import Foundation

struct ConnectionHealth: Equatable {
    let status: String
    let deviceCount: Int
    let openAPIPath: String?

    var isReachable: Bool {
        status.lowercased() == "ok"
    }

    var title: String {
        isReachable ? "Сервер доступен" : "Сервер ответил состоянием \(status)"
    }

    var detail: String {
        let openAPI = openAPIPath.map { "Схема API: \($0)" } ?? "Схема API не указана"
        return "Устройств на сервере: \(deviceCount). \(openAPI)"
    }
}

struct HealthCheckResponse: Codable, Equatable {
    let status: String
    let openapiPath: String?
    let deviceCount: Int?
}
