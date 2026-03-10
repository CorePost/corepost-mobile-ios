import SwiftUI

struct StatusHeroCard: View {
    let state: DeviceState
    let detail: String
    let deviceId: String

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(state.title)
                            .font(.system(.title, design: .rounded, weight: .bold))
                        Text(detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    StateCapsule(state: state)
                }

                Divider()
                    .overlay(Color.black.opacity(0.08))

                HStack(alignment: .top) {
                    Label("Устройство", systemImage: "desktopcomputer")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(deviceId)
                        .font(.footnote.monospaced())
                        .multilineTextAlignment(.trailing)
                }
            }
        }
    }
}

private struct StateCapsule: View {
    let state: DeviceState

    var body: some View {
        Text(state.badgeTitle)
            .font(.caption.weight(.bold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: state.accent.colors.map { $0.opacity(0.88) },
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .foregroundStyle(.white)
            .textCase(.uppercase)
    }
}
