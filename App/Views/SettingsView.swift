import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: AppViewModel

    @State private var draft: AppConfiguration
    private let demoSeed = DemoSeed.current

    init(configuration: AppConfiguration) {
        _draft = State(initialValue: configuration)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        GlassPanel {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Подключение")
                                    .font(.system(.title2, design: .rounded, weight: .bold))
                                Text("Все адреса и секреты вводятся вручную. Ничего не зашито в приложение, профиль можно в любой момент изменить или удалить.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        sectionCard(
                            title: "Сервер",
                            subtitle: "Используйте полный адрес с протоколом."
                        ) {
                            settingsField(title: "Адрес сервера") {
                                TextField("https://server.example", text: $draft.serverAddress)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.URL)
                                    .autocorrectionDisabled()
                                    .accessibilityIdentifier("settings.serverAddressField")
                            }

                            HStack(spacing: 12) {
                                Button {
                                    Task {
                                        await viewModel.testConnection(serverAddress: draft.serverAddress)
                                    }
                                } label: {
                                    Label(
                                        viewModel.isTestingConnection ? "Проверяем..." : "Проверить соединение",
                                        systemImage: "network"
                                    )
                                }
                                .buttonStyle(.borderedProminent)
                                .accessibilityIdentifier("settings.testConnectionButton")
                                .disabled(draft.normalizedServerAddress.isEmpty || viewModel.isTestingConnection)

                                Button("Очистить адрес") {
                                    draft.serverAddress = ""
                                }
                                .buttonStyle(.bordered)
                                .accessibilityIdentifier("settings.clearServerAddressButton")
                                .disabled(draft.normalizedServerAddress.isEmpty)
                            }

                            if let health = viewModel.connectionHealth {
                                statusStrip(title: health.title, detail: health.detail, color: health.isReachable ? .green : .orange)
                            }
                        }

                        sectionCard(
                            title: "Данные устройства",
                            subtitle: "Для ручного сценария используйте идентификатор emergency и panic secret."
                        ) {
                            settingsField(title: "Идентификатор emergency") {
                                TextField("Например, 1a2b3c...", text: $draft.emergencyId)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .accessibilityIdentifier("settings.emergencyIdField")
                            }

                            settingsField(title: "Panic secret") {
                                SecureField("Введите секрет блокировки", text: $draft.panicSecret)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .accessibilityIdentifier("settings.panicSecretField")
                            }
                        }

                        sectionCard(
                            title: "Демо-профиль",
                            subtitle: "Помогает быстро создать устройство на сервере и сохранить его секреты."
                        ) {
                            if let demoSeed {
                                Button {
                                    draft.serverAddress = demoSeed.serverAddress
                                    draft.adminToken = demoSeed.adminToken
                                    if draft.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        draft.displayName = demoSeed.displayName
                                    }
                                } label: {
                                    Label("Заполнить demo-данные", systemImage: "wand.and.stars")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .accessibilityIdentifier("settings.applyDemoSeedButton")
                            }

                            settingsField(title: "Отображаемое имя") {
                                TextField("Например, iPhone Демо", text: $draft.displayName)
                                    .accessibilityIdentifier("settings.displayNameField")
                            }

                            settingsField(title: "Токен администратора") {
                                SecureField("Введите токен администратора", text: $draft.adminToken)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .accessibilityIdentifier("settings.adminTokenField")
                            }

                            Button {
                                Task {
                                    if await viewModel.createDemoProfile(from: draft) {
                                        dismiss()
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "sparkles.rectangle.stack")
                                    Text(viewModel.isCreatingDemoProfile ? "Создаём..." : "Создать демо-профиль")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PrimaryCapsuleButtonStyle(palette: .mint))
                            .accessibilityIdentifier("settings.createDemoProfileButton")
                            .disabled(
                                draft.normalizedServerAddress.isEmpty ||
                                draft.normalizedAdminToken.isEmpty ||
                                viewModel.isCreatingDemoProfile
                            )
                        }

                        sectionCard(
                            title: "Удаление",
                            subtitle: "Полностью очищает адрес, идентификаторы и секреты."
                        ) {
                            Button("Удалить профиль", role: .destructive) {
                                viewModel.clearConfiguration()
                                dismiss()
                            }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("settings.removeProfileButton")
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Закрыть") { dismiss() }
                        .accessibilityIdentifier("settings.closeButton")
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    Button {
                        Task {
                            if await viewModel.saveConfiguration(draft) {
                                dismiss()
                            }
                        }
                    } label: {
                        Text(viewModel.isSaving ? "Сохраняем..." : "Сохранить профиль")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryCapsuleButtonStyle(palette: .sky))
                    .accessibilityIdentifier("settings.saveProfileButton")
                    .disabled(viewModel.isSaving)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)
                .background(Color(uiColor: .systemGroupedBackground))
            }
        }
    }

    private func sectionCard<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                content()
            }
        }
    }

    private func settingsField<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            content()
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                )
        }
    }

    private func statusStrip(title: String, detail: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(uiColor: .tertiarySystemGroupedBackground))
        )
    }
}
