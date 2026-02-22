package com.muff.plugins

import com.muff.config.AppConfig
import com.muff.model.ErrorResponse
import com.muff.service.AppAttestService
import io.ktor.http.HttpMethod
import io.ktor.http.HttpStatusCode
import io.ktor.server.application.Application
import io.ktor.server.application.ApplicationCallPipeline
import io.ktor.server.request.header
import io.ktor.server.request.httpMethod
import io.ktor.server.request.path
import io.ktor.server.response.respond
import org.slf4j.LoggerFactory
import java.security.MessageDigest
import java.util.Base64

fun Application.configureAppAttest(
    config: AppConfig.AppAttestConfig,
    attestService: AppAttestService,
) {
    val logger = LoggerFactory.getLogger("AppAttestPlugin")

    intercept(ApplicationCallPipeline.Plugins) {
        val path = context.request.path()

        // Skip attestation endpoints, health, admin, and swagger
        if (shouldSkipAttest(path)) return@intercept

        val method = context.request.httpMethod
        val requireAssertion = when {
            config.enforceAll -> true
            config.enforcePost && method == HttpMethod.Post -> true
            else -> false
        }

        if (!requireAssertion) return@intercept

        val keyId = context.request.header("X-App-Attest-Key-Id")
        val assertionHeader = context.request.header("X-App-Attest-Assertion")

        if (keyId == null || assertionHeader == null) {
            // No attestation headers — fallback: allow but log warning
            logger.warn(
                "No attestation headers for {} {}",
                method.value,
                path,
            )
            return@intercept
        }

        val assertionBytes = try {
            Base64.getDecoder().decode(assertionHeader)
        } catch (e: IllegalArgumentException) {
            context.respond(
                HttpStatusCode.Forbidden,
                ErrorResponse("attestation_failed", "Invalid assertion encoding"),
            )
            finish()
            return@intercept
        }

        // Compute clientDataHash = SHA256(method + path + body)
        val clientDataHash = computeClientDataHash(method.value, path)

        if (!attestService.verifyAssertion(keyId, assertionBytes, clientDataHash)) {
            context.respond(
                HttpStatusCode.Forbidden,
                ErrorResponse("attestation_failed", "Invalid assertion"),
            )
            finish()
        }
    }
}

private fun shouldSkipAttest(path: String): Boolean {
    return path.startsWith("/v1/attest/") ||
        path == "/health" ||
        path.startsWith("/admin") ||
        path.startsWith("/swagger") ||
        path.startsWith("/admin-ui")
}

private fun computeClientDataHash(method: String, path: String): ByteArray {
    val data = "$method$path".toByteArray()
    return MessageDigest.getInstance("SHA-256").digest(data)
}
