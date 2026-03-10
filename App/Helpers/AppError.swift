import Foundation

enum AppError: LocalizedError, Equatable {
    case missingConfiguration
    case invalidServerAddress
    case invalidResponse
    case server(String)
    case secureStoreFailure

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            "Сначала заполните адрес сервера, идентификатор emergency и секрет panic-lock."
        case .invalidServerAddress:
            "Введите полный адрес сервера, включая http:// или https://."
        case .invalidResponse:
            "Ответ сервера не удалось разобрать."
        case .server(let message):
            message
        case .secureStoreFailure:
            "Не удалось обновить защищённое хранилище."
        }
    }
}
