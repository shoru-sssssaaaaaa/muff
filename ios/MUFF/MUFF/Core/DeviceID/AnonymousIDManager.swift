import Foundation
import CryptoKit

final class AnonymousIDManager: Sendable {
    static let shared = AnonymousIDManager()

    private static let keychainKey = "com.muff.anon-device-id"

    private init() {}

    var deviceIdHash: String {
        let rawId = rawDeviceId
        let hash = SHA256.hash(data: Data(rawId.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    private var rawDeviceId: String {
        if let existing = readFromKeychain() {
            return existing
        }
        let newId = UUID().uuidString
        saveToKeychain(newId)
        return newId
    }

    private func readFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: Self.keychainKey,
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

    private func saveToKeychain(_ value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: Self.keychainKey,
            kSecValueData as String: data,
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
}
