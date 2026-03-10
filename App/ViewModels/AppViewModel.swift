import Foundation
import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
    @Published var configuration: AppConfiguration = .empty
    @Published var status: MobileStatus?
    @Published var connectionHealth: ConnectionHealth?
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var isTestingConnection = false
    @Published var isCreatingDemoProfile = false
    @Published var isSettingsPresented = false
    @Published var alertMessage = ""
    @Published var isAlertPresented = false
    @Published var lastOperationDetail = ""
    @Published var lastRefreshAt: Date?
    @Published var pendingConfirmationDeadline: Date?

    private let configurationStore: ConfigurationStore
    private let keychainStore: KeychainStore
    private let apiClient: APIClient

    init(configurationStore: ConfigurationStore, keychainStore: KeychainStore, apiClient: APIClient) {
        self.configurationStore = configurationStore
        self.keychainStore = keychainStore
        self.apiClient = apiClient
    }

    var isConfigured: Bool {
        configuration.isComplete
    }

    var currentState: DeviceState {
        status?.currentState ?? .registered
    }

    var heroPalette: AppPalette {
        currentState.accent
    }

    var primaryButtonTitle: String {
        switch currentState {
        case .pendingLock:
            "Подтвердить блокировку"
        case .locked:
            status?.userCanUnlock == false ? "Разблокировка запрещена" : "Восстановить доступ"
        default:
            "Заблокировать сейчас"
        }
    }

    var primaryButtonSubtitle: String {
        if let deadline = pendingConfirmationDeadline, deadline.timeIntervalSinceNow > 0 {
            return "Второй тап в течение окна подтверждения завершит блокировку."
        }

        switch currentState {
        case .locked:
            if status?.userCanUnlock == false {
                return "Пользовательская разблокировка отключена. Нужна административная процедура."
            }
            return "Запросит перевод устройства в состояние восстановления."
        case .pendingLock:
            return "Окно подтверждения уже открыто. Повторный тап завершит блокировку."
        default:
            return "Сразу отправит команду аварийной блокировки на выбранный сервер."
        }
    }

    var canTriggerPrimaryAction: Bool {
        guard isConfigured, !isLoading, !isSaving, !isCreatingDemoProfile else {
            return false
        }

        if currentState.isLocked {
            return status?.userCanUnlock ?? true
        }

        return true
    }

    func bootstrap() async {
        configuration = configurationStore.load(using: keychainStore)
        if configuration.hasServerAddress {
            await testConnection(silent: true)
        }
        guard isConfigured else { return }
        await refreshStatus()
    }

    @discardableResult
    func saveConfiguration(_ updated: AppConfiguration) async -> Bool {
        isSaving = true
        defer { isSaving = false }
        guard configurationStore.save(updated, using: keychainStore) else {
            showAlert(AppError.secureStoreFailure.localizedDescription)
            return false
        }

        configuration = configurationStore.load(using: keychainStore)
        pendingConfirmationDeadline = nil
        status = nil
        lastRefreshAt = nil

        if configuration.hasServerAddress {
            await testConnection(silent: true)
        } else {
            connectionHealth = nil
        }

        if isConfigured {
            await refreshStatus()
        }

        return true
    }

    func clearConfiguration() {
        configurationStore.clear(using: keychainStore)
        configuration = .empty
        status = nil
        connectionHealth = nil
        lastRefreshAt = nil
        pendingConfirmationDeadline = nil
        lastOperationDetail = ""
    }

    @discardableResult
    func createDemoProfile(from updated: AppConfiguration) async -> Bool {
        isCreatingDemoProfile = true
        defer { isCreatingDemoProfile = false }

        do {
            let bundle = try await apiClient.createDemoProfile(configuration: updated)
            var refreshed = updated
            refreshed.emergencyId = bundle.emergencyId
            refreshed.panicSecret = bundle.panicSecret

            guard await saveConfiguration(refreshed) else {
                return false
            }

            lastOperationDetail = "Демо-профиль создан для устройства \(bundle.deviceId)."
            isSettingsPresented = false
            return true
        } catch {
            showAlert(error.localizedDescription)
            return false
        }
    }

    @discardableResult
    func testConnection(serverAddress: String? = nil, silent: Bool = false) async -> Bool {
        let address = (serverAddress ?? configuration.normalizedServerAddress).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !address.isEmpty else {
            connectionHealth = nil
            return false
        }

        isTestingConnection = true
        defer { isTestingConnection = false }

        do {
            connectionHealth = try await apiClient.testConnection(serverAddress: address)
            return true
        } catch {
            connectionHealth = nil
            if !silent {
                showAlert(error.localizedDescription)
            }
            return false
        }
    }

    func refreshStatus() async {
        guard isConfigured else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            status = try await apiClient.mobileStatus(configuration: configuration)
            lastRefreshAt = Date()
            if status?.currentState != .pendingLock {
                pendingConfirmationDeadline = nil
            }
        } catch {
            showAlert(error.localizedDescription)
        }
    }

    func triggerPrimaryAction() async {
        guard isConfigured else {
            showAlert(AppError.missingConfiguration.localizedDescription)
            return
        }

        guard canTriggerPrimaryAction else {
            if currentState.isLocked, status?.userCanUnlock == false {
                showAlert("На этом устройстве пользовательская разблокировка отключена.")
            }
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            if currentState.isLocked {
                let (refreshed, operation, _) = try await apiClient.unlock(configuration: configuration)
                status = refreshed
                lastOperationDetail = operation.detail
                pendingConfirmationDeadline = nil
            } else {
                let (refreshed, operation, code) = try await apiClient.lock(configuration: configuration)
                status = refreshed
                lastOperationDetail = operation.detail
                if code == 201, let refreshed {
                    pendingConfirmationDeadline = Date().addingTimeInterval(TimeInterval(refreshed.lockApprovalTimeSecond))
                } else {
                    pendingConfirmationDeadline = nil
                }
            }
        } catch {
            showAlert(error.localizedDescription)
        }
    }

    private func showAlert(_ message: String) {
        alertMessage = message
        isAlertPresented = true
    }
}
