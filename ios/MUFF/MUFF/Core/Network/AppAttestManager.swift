import DeviceCheck
import CryptoKit
import Foundation

@MainActor
final class AppAttestManager {
    static let shared = AppAttestManager()

    private let service = DCAppAttestService.shared

    private static let keychainKeyId = "com.muff.attest-key-id"
    private static let keychainVerified = "com.muff.attest-verified"

    private init() {}

    var isSupported: Bool {
        #if DEBUG
        return false
        #else
        return service.isSupported
        #endif
    }

    var isAttested: Bool {
        readKeychain(Self.keychainVerified) == "true"
    }

    private var storedKeyId: String? {
        readKeychain(Self.keychainKeyId)
    }

    // MARK: - Attestation

    func ensureAttested() async throws {
        guard isSupported else { return }
        guard !isAttested else { return }

        // 1. Generate key if needed
        let keyId: String
        if let existing = storedKeyId {
            keyId = existing
        } else {
            keyId = try await service.generateKey()
            saveKeychain(Self.keychainKeyId, value: keyId)
        }

        // 2. Get challenge from server
        let apiClient = APIClient()
        let challengeResponse: AttestChallengeResponse = try await apiClient.fetchAttestChallenge()

        // 3. Create clientDataHash from challenge
        let challengeData = Data(challengeResponse.challenge.utf8)
        let challengeHash = SHA256.hash(data: challengeData)
        let clientDataHash = Data(challengeHash)

        // 4. Attest key with Apple
        let attestation = try await service.attestKey(keyId, clientDataHash: clientDataHash)

        // 5. Verify with backend
        let verifyRequest = AttestVerifyRequest(
            keyId: keyId,
            attestation: attestation.base64EncodedString(),
            challenge: challengeResponse.challenge
        )
        let verifyResponse: AttestVerifyResponse = try await apiClient.verifyAttestation(verifyRequest)

        if verifyResponse.verified {
            saveKeychain(Self.keychainVerified, value: "true")
        }
    }

    // MARK: - Assertion

    func assertionHeaders(for request: URLRequest) async -> [String: String] {
        guard isSupported, isAttested, let keyId = storedKeyId else {
            return [:]
        }

        do {
            let clientDataHash = computeClientDataHash(for: request)
            let assertion = try await service.generateAssertion(keyId, clientDataHash: clientDataHash)

            return [
                "X-App-Attest-Key-Id": keyId,
                "X-App-Attest-Assertion": assertion.base64EncodedString(),
            ]
        } catch {
            return [:]
        }
    }

    // MARK: - Private

    private func computeClientDataHash(for request: URLRequest) -> Data {
        let method = request.httpMethod ?? "GET"
        let path = request.url?.path ?? ""
        let data = Data((method + path).utf8)
        let hash = SHA256.hash(data: data)
        return Data(hash)
    }

    private func readKeychain(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private func saveKeychain(_ key: String, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
}
