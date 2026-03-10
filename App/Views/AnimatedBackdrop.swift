import SwiftUI

struct AnimatedBackdrop: View {
    let palette: AppPalette
    @State private var animate = false

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)

            RoundedRectangle(cornerRadius: 120, style: .continuous)
                .fill(
                    LinearGradient(colors: palette.colors.map { $0.opacity(0.16) }, startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: 320, height: 320)
                .blur(radius: 18)
                .rotationEffect(.degrees(animate ? 10 : -8))
                .offset(x: animate ? 120 : -90, y: animate ? -220 : -170)

            RoundedRectangle(cornerRadius: 100, style: .continuous)
                .fill(
                    LinearGradient(colors: palette.colors.reversed().map { $0.opacity(0.12) }, startPoint: .top, endPoint: .bottom)
                )
                .frame(width: 260, height: 260)
                .blur(radius: 26)
                .rotationEffect(.degrees(animate ? -16 : 12))
                .offset(x: animate ? -130 : 120, y: animate ? 280 : 220)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}
