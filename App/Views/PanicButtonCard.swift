import SwiftUI

struct PanicButtonCard: View {
    let title: String
    let subtitle: String
    let state: DeviceState
    let deadline: Date?
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        GlassPanel {
            VStack(spacing: 22) {
                PanicOrbButton(state: state, isLoading: isLoading, isEnabled: isEnabled, action: action)
                    .accessibilityIdentifier("dashboard.primaryActionButton")
                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                    if let deadline {
                        CountdownView(deadline: deadline)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                    } else {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct CountdownView: View {
    let deadline: Date
    @State private var remaining = 0

    var body: some View {
        Text(remaining > 0 ? "Подтвердите ещё раз в течение \(remaining) с" : "Окно подтверждения истекло")
            .task(id: deadline) {
                while true {
                    let seconds = max(0, Int(deadline.timeIntervalSinceNow.rounded()))
                    remaining = seconds
                    if seconds == 0 { break }
                    try? await Task.sleep(for: .seconds(1))
                }
            }
    }
}
