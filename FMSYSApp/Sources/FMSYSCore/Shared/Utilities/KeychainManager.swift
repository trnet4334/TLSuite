import Security
import Foundation

// MARK: - KeychainKey

public enum KeychainKey: String {
    case accessToken  = "fmsys.auth.accessToken"
    case refreshToken = "fmsys.auth.refreshToken"
    case userId       = "fmsys.auth.userId"
}

// MARK: - KeychainError

public enum KeychainError: Error, Equatable {
    case itemNotFound
    case unexpectedStatus(OSStatus)
}

// MARK: - KeychainManager

public struct KeychainManager {

    public init() {}

    // MARK: save (upsert)

    public func save(_ value: String, forKey key: KeychainKey) throws {
        let data = Data(value.utf8)
        let lookupQuery: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key.rawValue
        ]

        // Try updating an existing item first — avoids a delete+add race
        // between concurrent callers (errSecDuplicateItem on SecItemAdd).
        var status = SecItemUpdate(
            lookupQuery as CFDictionary,
            [kSecValueData: data] as CFDictionary
        )

        if status == errSecItemNotFound {
            // Nothing to update — add a new item.
            var addQuery = lookupQuery
            addQuery[kSecValueData]      = data
            addQuery[kSecAttrAccessible] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            status = SecItemAdd(addQuery as CFDictionary, nil)
        }

        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    // MARK: load

    public func load(forKey key: KeychainKey) throws -> String {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrAccount:      key.rawValue,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.itemNotFound
        }
        return string
    }

    // MARK: delete

    public func delete(forKey key: KeychainKey) throws {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key.rawValue
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    // MARK: clearAll

    /// Removes all Keychain items created by FMSYS (scoped to known keys).
    public func clearAll() throws {
        for key in [KeychainKey.accessToken, .refreshToken, .userId] {
            try delete(forKey: key)
        }
    }
}
