package com.muff.service

import com.muff.config.AppConfig
import com.muff.db.tables.AttestChallenges
import com.muff.db.tables.AttestedKeys
import com.upokecenter.cbor.CBORObject
import kotlinx.datetime.Clock
import org.jetbrains.exposed.sql.SqlExpressionBuilder.eq
import org.jetbrains.exposed.sql.SqlExpressionBuilder.less
import org.jetbrains.exposed.sql.and
import org.jetbrains.exposed.sql.deleteWhere
import org.jetbrains.exposed.sql.insert
import org.jetbrains.exposed.sql.selectAll
import org.jetbrains.exposed.sql.transactions.transaction
import org.jetbrains.exposed.sql.update
import org.slf4j.LoggerFactory
import java.io.ByteArrayInputStream
import java.security.KeyFactory
import java.security.MessageDigest
import java.security.PublicKey
import java.security.Signature
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import java.security.spec.X509EncodedKeySpec
import java.util.Base64
import kotlin.time.Duration.Companion.seconds

class AppAttestService(private val config: AppConfig.AppAttestConfig) {
    private val logger = LoggerFactory.getLogger(AppAttestService::class.java)
    private val appleRootCa: X509Certificate = loadAppleRootCa()

    fun generateChallenge(): String {
        val bytes = ByteArray(32)
        java.security.SecureRandom().nextBytes(bytes)
        val challenge = Base64.getEncoder().encodeToString(bytes)

        val expiresAt = Clock.System.now().plus(config.challengeTtlSeconds.seconds)

        transaction {
            AttestChallenges.insert {
                it[AttestChallenges.challenge] = challenge
                it[AttestChallenges.expiresAt] = expiresAt
            }
        }

        return challenge
    }

    fun verifyAttestation(keyId: String, attestationBytes: ByteArray, challenge: String): Boolean {
        try {
            // 1. Validate challenge: exists, unused, not expired
            val challengeValid = transaction {
                val row = AttestChallenges.selectAll()
                    .where {
                        (AttestChallenges.challenge eq challenge) and
                            (AttestChallenges.used eq false)
                    }
                    .singleOrNull() ?: return@transaction false

                val expiresAt = row[AttestChallenges.expiresAt]
                if (Clock.System.now() > expiresAt) {
                    return@transaction false
                }

                // Mark challenge as used
                AttestChallenges.update({ AttestChallenges.challenge eq challenge }) {
                    it[used] = true
                }
                true
            }

            if (!challengeValid) {
                logger.warn("Invalid or expired challenge for keyId={}", keyId)
                return false
            }

            // 2. Parse attestation CBOR
            val cbor = CBORObject.DecodeFromBytes(attestationBytes)
            val fmt = cbor["fmt"]?.AsString()
            if (fmt != "apple-appattest") {
                logger.warn("Unexpected attestation format: {}", fmt)
                return false
            }

            val attStmt = cbor["attStmt"]
            val authData = cbor["authData"]?.GetByteString()
                ?: run {
                    logger.warn("Missing authData in attestation")
                    return false
                }

            // 3. Extract certificate chain from attStmt
            val x5cArray = attStmt["x5c"]
            if (x5cArray == null || x5cArray.size() < 2) {
                logger.warn("Missing or incomplete x5c certificate chain")
                return false
            }

            val certFactory = CertificateFactory.getInstance("X.509")
            val credCert = certFactory.generateCertificate(
                ByteArrayInputStream(x5cArray[0].GetByteString()),
            ) as X509Certificate
            val intermediateCert = certFactory.generateCertificate(
                ByteArrayInputStream(x5cArray[1].GetByteString()),
            ) as X509Certificate

            // 4. Verify certificate chain
            try {
                intermediateCert.verify(appleRootCa.publicKey)
                credCert.verify(intermediateCert.publicKey)
            } catch (e: Exception) {
                logger.warn("Certificate chain verification failed: {}", e.message)
                return false
            }

            // 5. Verify nonce
            // nonce = SHA256(authData || clientDataHash)
            // clientDataHash = SHA256(challenge string as UTF-8) — matches iOS side
            val clientDataHash = sha256(challenge.toByteArray(Charsets.UTF_8))
            val nonceData = authData + clientDataHash
            val expectedNonce = sha256(nonceData)

            val credCertNonce = extractNonceFromCert(credCert)
            if (credCertNonce == null || !expectedNonce.contentEquals(credCertNonce)) {
                logger.warn("Nonce verification failed for keyId={}", keyId)
                return false
            }

            // 6. Verify rpIdHash in authData
            // rpIdHash is first 32 bytes of authData
            val rpIdHash = authData.copyOfRange(0, 32)
            val expectedRpIdHash = sha256("${config.teamId}.${config.bundleId}".toByteArray())
            if (!rpIdHash.contentEquals(expectedRpIdHash)) {
                logger.warn("rpIdHash mismatch for keyId={}", keyId)
                return false
            }

            // 7. Extract public key and receipt
            val publicKey = credCert.publicKey

            // 8. Extract receipt from attStmt
            val receipt = attStmt["receipt"]?.GetByteString() ?: ByteArray(0)

            // 9. Store the attested key
            transaction {
                // Delete any existing key with same keyId
                AttestedKeys.deleteWhere { AttestedKeys.keyId eq keyId }

                AttestedKeys.insert {
                    it[AttestedKeys.keyId] = keyId
                    it[AttestedKeys.publicKey] = publicKey.encoded
                    it[AttestedKeys.receipt] = receipt
                    it[signCount] = 0L
                    it[createdAt] = Clock.System.now()
                }
            }

            logger.info("Successfully attested keyId={}", keyId)
            return true
        } catch (e: Exception) {
            logger.error("Attestation verification failed for keyId={}", keyId, e)
            return false
        }
    }

    fun verifyAssertion(keyId: String, assertionBytes: ByteArray, clientDataHash: ByteArray): Boolean {
        try {
            // 1. Look up stored public key
            val storedKey = transaction {
                AttestedKeys.selectAll()
                    .where { AttestedKeys.keyId eq keyId }
                    .singleOrNull()
            }

            if (storedKey == null) {
                logger.warn("No attested key found for keyId={}", keyId)
                return false
            }

            val publicKeyBytes = storedKey[AttestedKeys.publicKey]
            val storedSignCount = storedKey[AttestedKeys.signCount]

            // 2. Parse assertion CBOR
            val cbor = CBORObject.DecodeFromBytes(assertionBytes)
            val signature = cbor["signature"]?.GetByteString()
                ?: run {
                    logger.warn("Missing signature in assertion")
                    return false
                }
            val authenticatorData = cbor["authenticatorData"]?.GetByteString()
                ?: run {
                    logger.warn("Missing authenticatorData in assertion")
                    return false
                }

            // 3. Verify rpIdHash
            val rpIdHash = authenticatorData.copyOfRange(0, 32)
            val expectedRpIdHash = sha256("${config.teamId}.${config.bundleId}".toByteArray())
            if (!rpIdHash.contentEquals(expectedRpIdHash)) {
                logger.warn("rpIdHash mismatch in assertion for keyId={}", keyId)
                return false
            }

            // 4. Extract and verify sign count (bytes 33-36, big-endian)
            val signCountBytes = authenticatorData.copyOfRange(33, 37)
            val assertionSignCount = signCountBytes.fold(0L) { acc, byte ->
                (acc shl 8) or (byte.toLong() and 0xFF)
            }

            if (assertionSignCount <= storedSignCount) {
                logger.warn(
                    "Sign count not incremented for keyId={}: stored={}, assertion={}",
                    keyId,
                    storedSignCount,
                    assertionSignCount,
                )
                return false
            }

            // 5. Verify signature: SHA256(authenticatorData || clientDataHash)
            val signedData = sha256(authenticatorData + clientDataHash)
            val publicKey = restorePublicKey(publicKeyBytes)
            val sig = Signature.getInstance("SHA256withECDSA")
            sig.initVerify(publicKey)
            sig.update(signedData)

            if (!sig.verify(signature)) {
                logger.warn("Signature verification failed for keyId={}", keyId)
                return false
            }

            // 6. Update sign count
            transaction {
                AttestedKeys.update({ AttestedKeys.keyId eq keyId }) {
                    it[signCount] = assertionSignCount
                }
            }

            return true
        } catch (e: Exception) {
            logger.error("Assertion verification failed for keyId={}", keyId, e)
            return false
        }
    }

    fun cleanupExpiredChallenges(): Int {
        return transaction {
            AttestChallenges.deleteWhere {
                AttestChallenges.expiresAt less Clock.System.now()
            }
        }
    }

    private fun sha256(data: ByteArray): ByteArray {
        return MessageDigest.getInstance("SHA-256").digest(data)
    }

    private fun extractNonceFromCert(cert: X509Certificate): ByteArray? {
        // The nonce is in OID 1.2.840.113635.100.8.2
        val nonceOid = "1.2.840.113635.100.8.2"
        val extensionValue = cert.getExtensionValue(nonceOid) ?: return null
        return parseDerNonce(extensionValue)
    }

    private fun parseDerNonce(extensionValue: ByteArray): ByteArray? {
        try {
            // extensionValue is an ASN.1 OCTET STRING wrapping the actual extension
            // We need to unwrap: OCTET_STRING -> SEQUENCE -> [1] -> OCTET_STRING -> nonce
            var offset = 0

            // Outer OCTET STRING (tag 0x04)
            if (extensionValue[offset].toInt() != 0x04) return null
            offset++
            val outerLen = readDerLength(extensionValue, offset)
            offset = outerLen.second

            // SEQUENCE (tag 0x30)
            if (extensionValue[offset].toInt() != 0x30) return null
            offset++
            val seqLen = readDerLength(extensionValue, offset)
            offset = seqLen.second

            // CONTEXT [1] (tag 0xA1)
            if ((extensionValue[offset].toInt() and 0xFF) != 0xA1) return null
            offset++
            val ctxLen = readDerLength(extensionValue, offset)
            offset = ctxLen.second

            // OCTET STRING (tag 0x04)
            if (extensionValue[offset].toInt() != 0x04) return null
            offset++
            val nonceLen = readDerLength(extensionValue, offset)
            offset = nonceLen.second

            return extensionValue.copyOfRange(offset, offset + nonceLen.first)
        } catch (e: Exception) {
            logger.warn("Failed to parse DER nonce: {}", e.message)
            return null
        }
    }

    private fun readDerLength(data: ByteArray, offset: Int): Pair<Int, Int> {
        val firstByte = data[offset].toInt() and 0xFF
        return if (firstByte < 0x80) {
            Pair(firstByte, offset + 1)
        } else {
            val numBytes = firstByte and 0x7F
            var length = 0
            for (i in 1..numBytes) {
                length = (length shl 8) or (data[offset + i].toInt() and 0xFF)
            }
            Pair(length, offset + 1 + numBytes)
        }
    }

    private fun restorePublicKey(encodedKey: ByteArray): PublicKey {
        val keyFactory = KeyFactory.getInstance("EC")
        val keySpec = X509EncodedKeySpec(encodedKey)
        return keyFactory.generatePublic(keySpec)
    }

    private fun loadAppleRootCa(): X509Certificate {
        val pemBytes = this::class.java.classLoader
            .getResourceAsStream("apple_app_attest_root_ca.pem")
            ?.readBytes()
            ?: throw IllegalStateException("Apple App Attest Root CA not found in resources")

        val certFactory = CertificateFactory.getInstance("X.509")
        return certFactory.generateCertificate(ByteArrayInputStream(pemBytes)) as X509Certificate
    }
}
