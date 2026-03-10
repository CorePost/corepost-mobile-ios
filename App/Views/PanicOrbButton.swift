import SwiftUI

struct PanicOrbButton: View {
    let state: DeviceState
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(state.accent.primary.opacity(isEnabled ? 0.95 : 0.55))
                    .frame(width: 228, height: 228)
                    .overlay(
                        Circle()
                            .strokeBorder(.white.opacity(0.26), lineWidth: 1.5)
                    )
                    .shadow(color: state.accent.primary.opacity(0.35), radius: 35, x: 0, y: 18)
                    .overlay(
                        Circle()
                            .fill(.white.opacity(0.18))
                            .frame(width: 90, height: 90)
                            .blur(radius: 24)
                            .offset(x: -40, y: -52)
                    )

                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.25)
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: state.isLocked ? "lock.open.fill" : "shield.lefthalf.filled.badge.xmark")
                            .font(.system(size: 42, weight: .bold))
                        Text(state.isLocked ? "СНЯТЬ" : "БЛОК")
                            .font(.system(.headline, design: .rounded, weight: .black))
                            .tracking(2)
                    }
                    .foregroundStyle(.white.opacity(isEnabled ? 1 : 0.72))
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .scaleEffect(isLoading ? 0.97 : 1.0)
        .animation(.spring(response: 0.32, dampingFraction: 0.72), value: isLoading)
    }
}
