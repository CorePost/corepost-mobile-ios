import Foundation

enum DeviceState: String, Codable, CaseIterable {
    case registered
    case normal
    case pendingLock = "pending_lock"
    case locked
    case restricted
    case recovered

    var title: String {
        switch self {
        case .registered:
            "Профиль готов"
        case .normal:
            "Устройство в норме"
        case .pendingLock:
            "Нужно подтверждение"
        case .locked:
            "Устройство заблокировано"
        case .restricted:
            "Ограниченный режим"
        case .recovered:
            "Доступ восстановлен"
        }
    }

    var detail: String {
        switch self {
        case .registered:
            "Профиль создан. Обновите статус, чтобы проверить доступность устройства."
        case .normal:
            "Сервер считает устройство доверенным."
        case .pendingLock:
            "Для завершения блокировки нужен второй тап в окне подтверждения."
        case .locked:
            "Предзагрузочная разблокировка должна быть запрещена, а постзагрузочная реакция активирована."
        case .restricted:
            "Устройство на связи, но уровень доверия снижен."
        case .recovered:
            "Доступ возвращён. Обновите статус, чтобы увидеть итоговое состояние."
        }
    }

    var badgeTitle: String {
        switch self {
        case .registered:
            "готов"
        case .normal:
            "норма"
        case .pendingLock:
            "ожидание"
        case .locked:
            "lock"
        case .restricted:
            "ограничен"
        case .recovered:
            "восстановлен"
        }
    }

    var accent: AppPalette {
        switch self {
        case .registered:
            .amber
        case .normal:
            .mint
        case .pendingLock:
            .blue
        case .locked:
            .coral
        case .restricted:
            .violet
        case .recovered:
            .sky
        }
    }

    var isLocked: Bool {
        self == .locked
    }
}
