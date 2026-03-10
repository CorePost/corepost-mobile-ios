import SwiftUI

@main
struct CorePostMobileIOSApp: App {
    @StateObject private var viewModel: AppViewModel

    init() {
        let configurationStore = ConfigurationStore()
        let keychainStore = KeychainStore(service: "com.corepost.mobileios.secure")

        if ProcessInfo.processInfo.environment["UITEST_RESET_STATE"] == "1" {
            configurationStore.clear(using: keychainStore)
        }

        _viewModel = StateObject(
            wrappedValue: AppViewModel(
                configurationStore: configurationStore,
                keychainStore: keychainStore,
                apiClient: APIClient()
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .task {
                    await viewModel.bootstrap()
                }
        }
    }
}
