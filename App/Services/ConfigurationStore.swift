import Foundation

final class ConfigurationStore {
    private enum Keys {
        static let serverAddress = "serverAddress"
        static let displayName = "displayName"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load(using keychain: KeychainStore) -> AppConfiguration {
        AppConfiguration(
            serverAddress: defaults.string(forKey: Keys.serverAddress) ?? "",
            emergencyId: keychain.read("emergencyId"),
            panicSecret: keychain.read("panicSecret"),
            adminToken: keychain.read("adminToken"),
            displayName: defaults.string(forKey: Keys.displayName) ?? ""
        )
    }

    func save(_ configuration: AppConfiguration, using keychain: KeychainStore) -> Bool {
        defaults.set(configuration.normalizedServerAddress, forKey: Keys.serverAddress)
        defaults.set(configuration.normalizedDisplayName, forKey: Keys.displayName)

        let emergencySaved = keychain.save(configuration.normalizedEmergencyId, for: "emergencyId")
        let secretSaved = keychain.save(configuration.normalizedPanicSecret, for: "panicSecret")
        let adminSaved: Bool
        if configuration.normalizedAdminToken.isEmpty {
            keychain.delete("adminToken")
            adminSaved = true
        } else {
            adminSaved = keychain.save(configuration.normalizedAdminToken, for: "adminToken")
        }

        return emergencySaved && secretSaved && adminSaved
    }

    func clear(using keychain: KeychainStore) {
        defaults.removeObject(forKey: Keys.serverAddress)
        defaults.removeObject(forKey: Keys.displayName)
        keychain.delete("emergencyId")
        keychain.delete("panicSecret")
        keychain.delete("adminToken")
    }
}
