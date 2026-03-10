import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        ZStack {
            AnimatedBackdrop(palette: viewModel.heroPalette)
                .ignoresSafeArea()

            if viewModel.isConfigured {
                DashboardView()
            } else {
                OnboardingView()
            }
        }
        .sheet(isPresented: $viewModel.isSettingsPresented) {
            SettingsView(configuration: viewModel.configuration)
                .environmentObject(viewModel)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .alert("CorePost", isPresented: $viewModel.isAlertPresented) {
            Button("Понятно", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage)
        }
    }
}

private struct DashboardView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    ProfileSummaryCard()

                    StatusHeroCard(
                        state: viewModel.currentState,
                        detail: viewModel.lastOperationDetail.isEmpty ? viewModel.currentState.detail : viewModel.lastOperationDetail,
                        deviceId: viewModel.status?.deviceId ?? "Ещё не получен"
                    )

                    PanicButtonCard(
                        title: viewModel.primaryButtonTitle,
                        subtitle: viewModel.primaryButtonSubtitle,
                        state: viewModel.currentState,
                        deadline: viewModel.pendingConfirmationDeadline,
                        isLoading: viewModel.isLoading
                        ,
                        isEnabled: viewModel.canTriggerPrimaryAction
                    ) {
                        Task {
                            await viewModel.triggerPrimaryAction()
                        }
                    }

                    DeviceMetricsCard()

                    GlassPanel {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("Быстрые действия", systemImage: "bolt.fill")
                                .font(.headline)
                            actionButton("Обновить статус", systemImage: "arrow.clockwise") {
                                Task { await viewModel.refreshStatus() }
                            }
                            .accessibilityIdentifier("dashboard.refreshStatusButton")
                            actionButton("Проверить соединение", systemImage: "network") {
                                Task { await viewModel.testConnection() }
                            }
                            .accessibilityIdentifier("dashboard.testConnectionButton")
                            actionButton("Изменить профиль", systemImage: "slider.horizontal.3") {
                                viewModel.isSettingsPresented = true
                            }
                            .accessibilityIdentifier("dashboard.editProfileButton")
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 36)
            }
            .navigationTitle("CorePost")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.isSettingsPresented = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .accessibilityIdentifier("dashboard.settingsButton")
                }
            }
        }
    }

    private func actionButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.body.weight(.medium))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

private struct OnboardingView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                Spacer(minLength: 24)

                GlassPanel {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Мобильный panic-клиент")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text("Подключите свой сервер и профиль устройства")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Адрес сервера вводится вручную. После настройки приложение сможет проверять статус и выполнять сценарии блокировки и восстановления доступа.")
                            .font(.body)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 10) {
                            readinessPill(
                                title: "Сервер",
                                isReady: viewModel.configuration.hasServerAddress
                            )
                            readinessPill(
                                title: "Секреты",
                                isReady: viewModel.configuration.hasCredentialPair
                            )
                        }

                        Button("Открыть настройки") {
                            viewModel.isSettingsPresented = true
                        }
                        .accessibilityIdentifier("onboarding.openSettingsButton")
                        .buttonStyle(PrimaryCapsuleButtonStyle(palette: .sky))
                    }
                }

                VStack(spacing: 14) {
                    FeatureCard(
                        icon: "network",
                        title: "Гибкая конфигурация",
                        detail: "Адрес сервера можно ввести, изменить или удалить в любой момент."
                    )
                    FeatureCard(
                        icon: "lock.shield",
                        title: "Управление доступом",
                        detail: "Статус устройства и действия блокировки отображаются прямо в одном сценарии."
                    )
                    FeatureCard(
                        icon: "key.fill",
                        title: "Локальное хранение секретов",
                        detail: "Идентификатор emergency, panic secret и токен администратора хранятся отдельно от обычных настроек."
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }

    private func readinessPill(title: String, isReady: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isReady ? "checkmark.circle.fill" : "circle.dashed")
                .foregroundStyle(isReady ? Color.green : Color.secondary)
            Text(title)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule(style: .continuous)
                .fill(Color(uiColor: .tertiarySystemGroupedBackground))
        )
    }
}

private struct ProfileSummaryCard: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(viewModel.configuration.normalizedDisplayName.isEmpty ? "iOS-клиент" : viewModel.configuration.normalizedDisplayName)
                            .font(.system(.title2, design: .rounded, weight: .bold))
                        Text("Профиль привязан к пользовательскому адресу и может быть полностью очищен из настроек.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "iphone.gen3")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(viewModel.heroPalette.primary)
                }

                HStack(spacing: 12) {
                    summaryChip(
                        title: "Сервер",
                        value: viewModel.configuration.serverLabel.isEmpty ? "не задан" : viewModel.configuration.serverLabel
                    )
                    summaryChip(
                        title: "Соединение",
                        value: viewModel.connectionHealth?.isReachable == true ? "доступно" : "не проверено"
                    )
                }
            }
        }
        .accessibilityIdentifier("dashboard.profileSummaryCard")
    }

    private func summaryChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(uiColor: .tertiarySystemGroupedBackground))
        )
    }
}

private struct DeviceMetricsCard: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 16) {
                Label("Текущее подключение", systemImage: "wave.3.right.circle")
                    .font(.headline)

                metricRow(
                    title: "Адрес сервера",
                    value: viewModel.configuration.normalizedServerAddress
                )

                metricRow(
                    title: "Проверка соединения",
                    value: viewModel.connectionHealth?.title ?? "Проверка ещё не запускалась"
                )

                metricRow(
                    title: "Последнее обновление",
                    value: relativeRefreshText
                )

                metricRow(
                    title: "Разблокировка пользователем",
                    value: unlockText
                )
            }
        }
        .accessibilityIdentifier("dashboard.metricsCard")
    }

    private var unlockText: String {
        guard let status = viewModel.status else {
            return "Пока неизвестно"
        }
        return status.userCanUnlock ? "разрешена" : "только через администратора"
    }

    private var relativeRefreshText: String {
        guard let date = viewModel.lastRefreshAt else {
            return "Ещё не выполнялось"
        }
        return RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
    }

    private func metricRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value.isEmpty ? "Не задано" : value)
                .font(.subheadline.weight(.medium))
        }
    }
}

private struct FeatureCard: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        GlassPanel {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline)
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
