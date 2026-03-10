import Foundation

struct MobileStatus: Codable, Equatable {
    let deviceId: String
    let currentState: DeviceState
    let userCanUnlock: Bool
    let needLockApproval: Bool
    let lockApprovalTimeSecond: Int
}

struct ProvisioningBundle: Codable, Equatable {
    let deviceId: String
    let emergencyId: String
    let panicSecret: String
}

struct LockOperationResponse: Codable {
    let detail: String
    let currentState: DeviceState?
}
