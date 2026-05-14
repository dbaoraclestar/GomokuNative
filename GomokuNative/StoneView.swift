import SwiftUI

struct StoneView: View {
    let isBlack: Bool
    let moveNumber: Int?
    let isWinning: Bool
    let cellSize: CGFloat

    @State private var scale: CGFloat = 0
    @State private var glowAmount: CGFloat = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: isBlack
                            ? [Color(white: 0.33), Color(white: 0.07)]
                            : [.white, Color(white: 0.8)]),
                        center: .init(x: 0.35, y: 0.35),
                        startRadius: 0,
                        endRadius: cellSize * 0.41
                    )
                )
                .shadow(color: .black.opacity(isBlack ? 0.4 : 0.25), radius: 3, x: 2, y: 3)
                .frame(width: cellSize * 0.82, height: cellSize * 0.82)

            if let num = moveNumber {
                Text("\(num)")
                    .font(.system(size: cellSize * 0.3, weight: .bold))
                    .foregroundColor(isBlack ? .white.opacity(0.75) : .black.opacity(0.5))
            }
        }
        .shadow(color: isWinning ? .yellow : .clear, radius: isWinning ? (10 + glowAmount * 15) : 0)
        .scaleEffect(scale)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                scale = 1.0
            }
            if isWinning {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    glowAmount = 1.0
                }
            }
        }
    }
}
