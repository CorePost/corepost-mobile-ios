import Foundation

struct DemoSeed {
    let serverAddress: String
    let adminToken: String
    let displayName: String

    static var current: DemoSeed? {
        let environment = ProcessInfo.processInfo.environment

        guard let serverAddress = environment["DEMO_SERVER_ADDRESS"]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !serverAddress.isEmpty,
              let adminToken = environment["DEMO_ADMIN_TOKEN"]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !adminToken.isEmpty else {
            return nil
        }

        let displayName = environment["DEMO_DISPLAY_NAME"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        return DemoSeed(
            serverAddress: serverAddress,
            adminToken: adminToken,
            displayName: displayName?.isEmpty == false ? displayName! : "iPhone демо"
        )
    }
}
