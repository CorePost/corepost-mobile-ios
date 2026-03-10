import Foundation

struct AppConfiguration: Equatable {
    var serverAddress: String
    var emergencyId: String
    var panicSecret: String
    var adminToken: String
    var displayName: String

    var isComplete: Bool {
        hasServerAddress && hasCredentialPair
    }

    var hasServerAddress: Bool {
        !normalizedServerAddress.isEmpty
    }

    var hasCredentialPair: Bool {
        !normalizedEmergencyId.isEmpty && !normalizedPanicSecret.isEmpty
    }

    var normalizedServerAddress: String {
        serverAddress.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedEmergencyId: String {
        emergencyId.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedPanicSecret: String {
        panicSecret.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedAdminToken: String {
        adminToken.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedDisplayName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var serverLabel: String {
        guard let components = URLComponents(string: normalizedServerAddress),
              let host = components.host else {
            return normalizedServerAddress
        }

        if let port = components.port {
            return "\(host):\(port)"
        }
        return host
    }

    static let empty = AppConfiguration(
        serverAddress: "",
        emergencyId: "",
        panicSecret: "",
        adminToken: "",
        displayName: ""
    )
}
