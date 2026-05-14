import SwiftUI

struct ContentView: View {
    @StateObject private var engine = GameEngine()
    @State private var showConfetti = false
    @State private var playerName = "You"
    @State private var showNameDialog = false
    @State private var nameInput = ""
    @State private var titleBounce = false

    private let sizes = [9, 15, 19]

    private let difficultyEmojis: [Difficulty: String] = [
        .age4_5: "🐣", .age6_7: "🐥", .age8_9: "🐰",
        .age10_11: "🦊", .age12plus: "🦁"
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.35, green: 0.45, blue: 0.65),
                         Color(red: 0.28, green: 0.38, blue: 0.58),
                         Color(red: 0.38, green: 0.35, blue: 0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            GeometryReader { geo in
                let isLandscape = geo.size.width > geo.size.height
                if isLandscape {
                    HStack(spacing: 20) {
                        BoardView(engine: engine)
                            .allowsHitTesting(!engine.gameOver && engine.currentPlayer == GameEngine.player)
                            .frame(maxHeight: geo.size.height * 0.9)
                            .padding(.leading, 20)

                        VStack(spacing: 16) {
                            Spacer()
                            titleView
                            difficultySelectorRow
                            sizeSelectorRow
                            turnIndicator
                            scoreRow
                            buttonRow
                            Spacer()
                        }
                        .padding(.trailing, 20)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 10) {
                        titleView
                            .padding(.top, 20)

                        Spacer().frame(height: 10)

                        difficultySelectorRow

                        sizeSelectorRow

                        turnIndicator

                        Spacer(minLength: 0)

                        let footerHeight: CGFloat = 90
                        let headerHeight: CGFloat = 210
                        let availableForBoard = geo.size.height - headerHeight - footerHeight
                        let boardSize = min(geo.size.width - 32, availableForBoard)

                        BoardView(engine: engine)
                            .allowsHitTesting(!engine.gameOver && engine.currentPlayer == GameEngine.player)
                            .frame(width: boardSize, height: boardSize)

                        Spacer(minLength: 4)

                        scoreRow

                        buttonRow
                            .padding(.bottom, 12)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 16)
                }
            }

            if engine.gameOver {
                gameOverOverlay
            }

            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            if showNameDialog {
                nameEditDialog
            }
        }
        .statusBarHidden(true)
        .onChange(of: engine.gameOver) { newValue in
            if newValue && engine.winner == GameEngine.player {
                showConfetti = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showConfetti = false
                }
            }
        }
    }

    private var titleView: some View {
        VStack(spacing: 2) {
            Text("Gomoku")
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .pink.opacity(0.4), radius: 10, y: 3)
            Text("~ Five in a Row ~")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private var turnIndicator: some View {
        HStack(spacing: 12) {
            if engine.isThinking {
                ThinkingText()
            } else if !engine.gameOver {
                Text("Your turn! \(difficultyEmojis[engine.difficulty] ?? "")")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            }
            if engine.moveCount > 0 {
                Text("Move: \(engine.moveCount)")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(12)
            }
        }
        .frame(minHeight: 28)
    }

    private var sizeSelectorRow: some View {
        HStack(spacing: 8) {
            Text("Board:")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            ForEach(sizes, id: \.self) { size in
                Button("\(size)x\(size)") {
                    engine.setBoardSize(size)
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    engine.boardSize == size
                        ? Color.white.opacity(0.45)
                        : Color.white.opacity(0.15)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(engine.boardSize == size ? Color.white : Color.white.opacity(0.4), lineWidth: 2)
                )
                .cornerRadius(16)
                .foregroundColor(.white)
            }
        }
    }

    private var scoreRow: some View {
        HStack(spacing: 20) {
            Button(action: {
                nameInput = playerName == "You" ? "" : playerName
                showNameDialog = true
            }) {
                HStack(spacing: 6) {
                    Text("👦")
                    Text("\(playerName): \(engine.playerScore)")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.2))
                .cornerRadius(20)
            }
            HStack(spacing: 6) {
                Text("🤖")
                Text("Robot: \(engine.computerScore)")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.2))
            .cornerRadius(20)
        }
    }

    private var buttonRow: some View {
        HStack(spacing: 12) {
            Button {
                engine.undoMove()
            } label: {
                HStack(spacing: 4) {
                    Text("↩")
                    Text("Oops!")
                }
            }
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                LinearGradient(colors: [Color(red: 0.30, green: 0.85, blue: 0.75),
                                        Color(red: 0.20, green: 0.65, blue: 0.90)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .foregroundColor(.white)
            .cornerRadius(25)
            .shadow(color: Color.cyan.opacity(0.4), radius: 8, y: 4)
            .disabled(engine.moveHistory.isEmpty || engine.gameOver)
            .opacity(engine.moveHistory.isEmpty || engine.gameOver ? 0.4 : 1.0)

            Button {
                engine.resetGame()
                showConfetti = false
            } label: {
                HStack(spacing: 4) {
                    Text("🌟")
                    Text("New Game")
                }
            }
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .padding(.horizontal, 28)
            .padding(.vertical, 12)
            .background(
                LinearGradient(colors: [Color(red: 1.0, green: 0.55, blue: 0.20),
                                        Color(red: 0.95, green: 0.25, blue: 0.40)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .foregroundColor(.white)
            .cornerRadius(25)
            .shadow(color: Color.red.opacity(0.4), radius: 8, y: 4)
        }
    }

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text(resultMessage)
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.3), radius: 10, y: 3)

                Button {
                    engine.resetGame()
                    showConfetti = false
                } label: {
                    HStack(spacing: 6) {
                        Text("🎮")
                        Text("Play Again!")
                    }
                }
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .padding(.horizontal, 36)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(colors: [Color(red: 0.55, green: 0.20, blue: 0.90),
                                            Color(red: 0.85, green: 0.30, blue: 0.65)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .foregroundColor(.white)
                .cornerRadius(28)
                .shadow(color: Color.purple.opacity(0.4), radius: 10, y: 4)
            }
        }
    }

    private var resultMessage: String {
        guard let w = engine.winner else { return "It's a tie! 🤝" }
        if w == GameEngine.player {
            return "🎉 \(playerName) Win! 🏆"
        } else {
            return "Almost! Try again! 💪"
        }
    }

    private var difficultySelectorRow: some View {
        HStack(spacing: 6) {
            Text("Age:")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            ForEach(Difficulty.allCases, id: \.self) { level in
                Button {
                    engine.difficulty = level
                } label: {
                    HStack(spacing: 3) {
                        Text(difficultyEmojis[level] ?? "")
                            .font(.system(size: 13))
                        Text(level.rawValue)
                    }
                }
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    engine.difficulty == level
                        ? Color.white.opacity(0.45)
                        : Color.white.opacity(0.15)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(engine.difficulty == level ? Color.white : Color.white.opacity(0.4), lineWidth: 2)
                )
                .cornerRadius(16)
                .foregroundColor(.white)
            }
        }
    }

    private var nameEditDialog: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { showNameDialog = false }

            VStack(spacing: 16) {
                Text("What's your name? 😊")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                TextField("Your name", text: $nameInput)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.5), lineWidth: 2))
                    .foregroundColor(.white)
                    .frame(width: 220)
                    .onChange(of: nameInput) { newValue in
                        if newValue.count > 12 { nameInput = String(newValue.prefix(12)) }
                    }
                    .onSubmit { commitName() }

                HStack(spacing: 12) {
                    Button("Nope") {
                        showNameDialog = false
                    }
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(colors: [Color(red: 0.70, green: 0.95, blue: 0.90),
                                                Color(red: 0.90, green: 0.95, blue: 0.70)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .foregroundColor(Color(white: 0.33))
                    .cornerRadius(25)

                    Button("Done! ✨") {
                        commitName()
                    }
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(colors: [Color(red: 1.0, green: 0.75, blue: 0.40),
                                                Color(red: 1.0, green: 0.50, blue: 0.55)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(25)
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0.30, green: 0.25, blue: 0.50).opacity(0.95))
            )
        }
    }

    private func commitName() {
        let trimmed = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        playerName = trimmed.isEmpty ? "You" : trimmed
        showNameDialog = false
    }
}

struct ThinkingText: View {
    @State private var dots = ""
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        Text("🤖 Thinking\(dots)")
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            .onReceive(timer) { _ in
                if dots.count >= 3 {
                    dots = ""
                } else {
                    dots += "."
                }
            }
    }
}

struct ConfettiView: View {
    @State private var particles: [(id: Int, x: CGFloat, color: Color, size: CGFloat, duration: Double, delay: Double)] = []

    private let colors: [Color] = [.red, .yellow, .green, .blue, .pink, .purple, .orange, .mint]

    var body: some View {
        ZStack {
            ForEach(particles, id: \.id) { p in
                ConfettiPiece(color: p.color, size: p.size, duration: p.duration, delay: p.delay)
                    .position(x: p.x, y: -20)
            }
        }
        .onAppear {
            particles = (0..<50).map { i in
                (id: i,
                 x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                 color: colors.randomElement()!,
                 size: CGFloat.random(in: 8...18),
                 duration: Double.random(in: 1.5...3.5),
                 delay: Double.random(in: 0...0.5))
            }
        }
    }
}

struct ConfettiPiece: View {
    let color: Color
    let size: CGFloat
    let duration: Double
    let delay: Double

    @State private var offset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: size, height: size)
            .cornerRadius(size > 12 ? 2 : size / 2)
            .rotationEffect(.degrees(rotation))
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.linear(duration: duration).delay(delay)) {
                    offset = UIScreen.main.bounds.height + 40
                    rotation = 720
                    opacity = 0
                }
            }
    }
}
