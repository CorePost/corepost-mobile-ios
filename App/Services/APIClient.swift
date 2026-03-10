import CryptoKit
import Foundation

struct APIClient {
    func testConnection(serverAddress: String) async throws -> ConnectionHealth {
        let url = try buildURL(from: serverAddress, path: "/healthz")
        let (data, response) = try await URLSession.shared.data(from: url)
        try validate(response: response, data: data, accepted: [200])
        let payload = try JSONDecoder().decode(HealthCheckResponse.self, from: data)
        return ConnectionHealth(
            status: payload.status,
            deviceCount: payload.deviceCount ?? 0,
            openAPIPath: payload.openapiPath
        )
    }

    func mobileStatus(configuration: AppConfiguration) async throws -> MobileStatus {
        try await performSignedRequest(
            configuration: configuration,
            path: "/mobile/check",
            method: "GET",
            body: Optional<Data>.none
        )
    }

    func lock(configuration: AppConfiguration) async throws -> (MobileStatus?, LockOperationResponse, Int) {
        try await performSignedAction(configuration: configuration, path: "/mobile/lock")
    }

    func unlock(configuration: AppConfiguration) async throws -> (MobileStatus?, LockOperationResponse, Int) {
        try await performSignedAction(configuration: configuration, path: "/mobile/unlock")
    }

    func createDemoProfile(configuration: AppConfiguration) async throws -> ProvisioningBundle {
        guard !configuration.normalizedAdminToken.isEmpty else {
            throw AppError.server("Введите токен администратора, чтобы создать демо-профиль.")
        }
        let url = try buildURL(from: configuration.normalizedServerAddress, path: "/admin/register")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(configuration.normalizedAdminToken, forHTTPHeaderField: "X-Admin-Token")
        let payload = [
            "displayName": configuration.normalizedDisplayName.isEmpty ? "iPhone демо" : configuration.normalizedDisplayName,
            "unlockProfile": "2fa"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)
        return try JSONDecoder().decode(ProvisioningBundle.self, from: data)
    }

    private func performSignedAction(configuration: AppConfiguration, path: String) async throws -> (MobileStatus?, LockOperationResponse, Int) {
        let url = try buildURL(from: configuration.normalizedServerAddress, path: path)
        let timestamp = String(Int(Date().timeIntervalSince1970))
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(configuration.normalizedEmergencyId, forHTTPHeaderField: "X-EmergencyId")
        request.setValue(timestamp, forHTTPHeaderField: "X-Timestamp")
        request.setValue(signature(secret: configuration.normalizedPanicSecret, method: "POST", path: path, timestamp: timestamp), forHTTPHeaderField: "X-Signature")
        let (data, response) = try await URLSession.shared.data(for: request)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        try validate(response: response, data: data, accepted: [200, 201])
        let operation = try JSONDecoder().decode(LockOperationResponse.self, from: data)
        let refreshed = try? await mobileStatus(configuration: configuration)
        return (refreshed, operation, code)
    }

    private func performSignedRequest<T: Decodable>(
        configuration: AppConfiguration,
        path: String,
        method: String,
        body: Data?
    ) async throws -> T {
        let url = try buildURL(from: configuration.normalizedServerAddress, path: path)
        let timestamp = String(Int(Date().timeIntervalSince1970))
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.setValue(configuration.normalizedEmergencyId, forHTTPHeaderField: "X-EmergencyId")
        request.setValue(timestamp, forHTTPHeaderField: "X-Timestamp")
        request.setValue(signature(secret: configuration.normalizedPanicSecret, method: method, path: path, timestamp: timestamp), forHTTPHeaderField: "X-Signature")
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func buildURL(from base: String, path: String) throws -> URL {
        let trimmed = base.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var components = URLComponents(string: trimmed),
              let scheme = components.scheme,
              ["http", "https"].contains(scheme.lowercased()),
              components.host != nil else {
            throw AppError.invalidServerAddress
        }

        let basePath = components.percentEncodedPath
        components.percentEncodedPath = joinedPath(basePath, path)
        guard let url = components.url else {
            throw AppError.invalidServerAddress
        }
        return url
    }

    private func joinedPath(_ basePath: String, _ path: String) -> String {
        let normalizedBase = basePath == "/" ? "" : basePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let normalizedPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if normalizedBase.isEmpty {
            return "/" + normalizedPath
        }
        return "/" + normalizedBase + "/" + normalizedPath
    }

    private func signature(secret: String, method: String, path: String, timestamp: String) -> String {
        let payload = [method.uppercased(), path, timestamp].joined(separator: "\n")
        let key = SymmetricKey(data: Data(secret.utf8))
        let digest = HMAC<SHA256>.authenticationCode(for: Data(payload.utf8), using: key)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func validate(response: URLResponse, data: Data, accepted: Set<Int> = [200, 201]) throws {
        guard let http = response as? HTTPURLResponse else {
            throw AppError.invalidResponse
        }
        guard accepted.contains(http.statusCode) else {
            if let payload = try? JSONDecoder().decode(LockOperationResponse.self, from: data) {
                throw AppError.server(payload.detail)
            }
            if let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let detail = payload["detail"] as? String {
                throw AppError.server(detail)
            }
            throw AppError.server("Сервер вернул статус \(http.statusCode).")
        }
    }
}
