import Foundation

enum Difficulty: String, CaseIterable {
    case age4_5 = "4-5"
    case age6_7 = "6-7"
    case age8_9 = "8-9"
    case age10_11 = "10-11"
    case age12plus = "12+"
}

class GameEngine: ObservableObject {
    static let empty = 0
    static let player = 1
    static let computer = 2

    private let directions: [(Int, Int)] = [(0,1),(1,0),(1,1),(1,-1)]

    private struct DirOpenResult {
        let count: Int
        let openEnds: Int
    }

    @Published var difficulty: Difficulty = .age4_5
    @Published var boardSize: Int = 9
    @Published var board: [[Int]] = []
    @Published var currentPlayer: Int = GameEngine.player
    @Published var gameOver: Bool = false
    @Published var winner: Int? = nil
    @Published var moveCount: Int = 0
    @Published var lastMove: (row: Int, col: Int)? = nil
    @Published var winningCells: [(row: Int, col: Int)] = []
    @Published var playerScore: Int = 0
    @Published var computerScore: Int = 0
    @Published var isThinking: Bool = false

    var moveHistory: [(player: (Int, Int), computer: (Int, Int)?)] = []

    init() {
        resetGame()
    }

    func setBoardSize(_ size: Int) {
        guard size != boardSize else { return }
        boardSize = size
        resetGame()
    }

    func resetGame() {
        board = Array(repeating: Array(repeating: GameEngine.empty, count: boardSize), count: boardSize)
        currentPlayer = GameEngine.player
        gameOver = false
        winner = nil
        moveCount = 0
        lastMove = nil
        winningCells = []
        moveHistory = []
        isThinking = false
    }

    private func getDifficultyParams() -> Double {
        switch difficulty {
        case .age4_5:    return 0.70
        case .age6_7:    return 0.35
        case .age8_9:    return 0.15
        case .age10_11:  return 0.05
        case .age12plus: return 0.00
        }
    }

    func placeStone(row: Int, col: Int, player: Int) -> Bool {
        guard board[row][col] == GameEngine.empty, !gameOver else { return false }
        board[row][col] = player
        moveCount += 1
        lastMove = (row, col)

        if let cells = checkWin(row: row, col: col, player: player) {
            gameOver = true
            winningCells = cells
            winner = player
            if player == GameEngine.player {
                playerScore += 1
            } else {
                computerScore += 1
            }
            return true
        }
        if moveCount == boardSize * boardSize {
            gameOver = true
            winner = nil
            return true
        }
        return true
    }

    func handlePlayerMove(row: Int, col: Int) {
        guard currentPlayer == GameEngine.player, !gameOver else { return }
        guard placeStone(row: row, col: col, player: GameEngine.player) else { return }

        SoundManager.shared.playPlaceSound()

        if gameOver {
            if winner == GameEngine.player {
                SoundManager.shared.playWinSound()
            }
            return
        }

        let playerMove = (row, col)
        currentPlayer = GameEngine.computer
        isThinking = true

        let delay = 0.4 + Double.random(in: 0...0.4)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            let compMove = self.doComputerMove()
            self.moveHistory.append((player: playerMove, computer: compMove))
            self.isThinking = false
            if !self.gameOver {
                self.currentPlayer = GameEngine.player
            }
        }
    }

    func doComputerMove() -> (Int, Int)? {
        var emptyCells: [(Int, Int)] = []
        for r in 0..<boardSize {
            for c in 0..<boardSize {
                if board[r][c] == GameEngine.empty {
                    emptyCells.append((r, c))
                }
            }
        }
        guard !emptyCells.isEmpty else { return nil }

        var pick: (Int, Int)
        let randomChance = getDifficultyParams()

        if Double.random(in: 0...1) < randomChance {
            let nearby = emptyCells.filter { hasNeighbor(row: $0.0, col: $0.1, dist: 2) }
            let pool = nearby.isEmpty ? emptyCells : nearby
            pick = pool.randomElement()!
        } else {
            var bestScore = -1
            var bestMoves: [(Int, Int)] = []
            for cell in emptyCells {
                let score = evaluateCell(row: cell.0, col: cell.1)
                if score > bestScore {
                    bestScore = score
                    bestMoves = [cell]
                } else if score == bestScore {
                    bestMoves.append(cell)
                }
            }
            if difficulty == .age12plus {
                bestMoves = filterWithLookahead(bestMoves, emptyCells: emptyCells)
            }
            pick = bestMoves.randomElement()!
        }

        _ = placeStone(row: pick.0, col: pick.1, player: GameEngine.computer)
        SoundManager.shared.playPlaceSound()

        if gameOver && winner == GameEngine.computer {
            SoundManager.shared.playLoseSound()
        }

        return pick
    }

    func undoMove() {
        guard !moveHistory.isEmpty, !gameOver else { return }
        let last = moveHistory.removeLast()

        if let comp = last.computer {
            board[comp.0][comp.1] = GameEngine.empty
            moveCount -= 1
        }

        board[last.player.0][last.player.1] = GameEngine.empty
        moveCount -= 1

        if let prev = moveHistory.last {
            let target = prev.computer ?? prev.player
            lastMove = (target.0, target.1)
        } else {
            lastMove = nil
        }

        winningCells = []
        currentPlayer = GameEngine.player
        isThinking = false
    }

    private func checkWin(row: Int, col: Int, player: Int) -> [(row: Int, col: Int)]? {
        for dir in directions {
            var line: [(row: Int, col: Int)] = [(row, col)]
            var nr = row + dir.0, nc = col + dir.1
            while inBounds(nr, nc) && board[nr][nc] == player {
                line.append((nr, nc))
                nr += dir.0; nc += dir.1
            }
            nr = row - dir.0; nc = col - dir.1
            while inBounds(nr, nc) && board[nr][nc] == player {
                line.append((nr, nc))
                nr -= dir.0; nc -= dir.1
            }
            if line.count >= 5 { return line }
        }
        return nil
    }

    private func inBounds(_ r: Int, _ c: Int) -> Bool {
        r >= 0 && r < boardSize && c >= 0 && c < boardSize
    }

    private func hasNeighbor(row: Int, col: Int, dist: Int) -> Bool {
        for dr in -dist...dist {
            for dc in -dist...dist {
                if dr == 0 && dc == 0 { continue }
                let nr = row + dr, nc = col + dc
                if inBounds(nr, nc) && board[nr][nc] != GameEngine.empty { return true }
            }
        }
        return false
    }

    private func evaluateCell(row: Int, col: Int) -> Int {
        switch difficulty {
        case .age4_5: return evaluateEasy(row: row, col: col)
        case .age6_7: return evaluateMedium(row: row, col: col)
        case .age8_9, .age10_11, .age12plus: return evaluateAdvanced(row: row, col: col)
        }
    }

    private func evaluateEasy(row: Int, col: Int) -> Int {
        var score = 0
        for dir in directions {
            let cCount = countDir(row, col, dir.0, dir.1, GameEngine.computer) +
                         countDir(row, col, -dir.0, -dir.1, GameEngine.computer)
            let pCount = countDir(row, col, dir.0, dir.1, GameEngine.player) +
                         countDir(row, col, -dir.0, -dir.1, GameEngine.player)
            if cCount >= 4 { score += 5000 }
            else if cCount == 3 { score += 100 }
            if pCount >= 4 { score += 2000 }
            else if pCount == 3 { score += 80 }
        }
        return score
    }

    private func evaluateMedium(row: Int, col: Int) -> Int {
        var score = 0
        for dir in directions {
            let pCount = countDir(row, col, dir.0, dir.1, GameEngine.player) +
                         countDir(row, col, -dir.0, -dir.1, GameEngine.player)
            let cCount = countDir(row, col, dir.0, dir.1, GameEngine.computer) +
                         countDir(row, col, -dir.0, -dir.1, GameEngine.computer)
            if cCount >= 4 { score += 20000 }
            else if cCount == 3 { score += 400 }
            else if cCount == 2 { score += 40 }
            if pCount >= 4 { score += 10000 }
            else if pCount == 3 { score += 500 }
            else if pCount == 2 { score += 50 }
        }
        let center = boardSize / 2
        let dist = abs(row - center) + abs(col - center)
        score += max(0, boardSize - dist) * 2
        return score
    }

    private func evaluateAdvanced(row: Int, col: Int) -> Int {
        var score = 0
        var threats = 0
        let openMul: Double = (difficulty == .age10_11) ? 2.5 : 3.0
        for dir in directions {
            let cInfo = countDirOpen(row, col, dir.0, dir.1, GameEngine.computer)
            let pInfo = countDirOpen(row, col, dir.0, dir.1, GameEngine.player)
            if cInfo.count >= 4 { score += 100000 }
            else if cInfo.count == 3 && cInfo.openEnds == 2 { score += 15000; threats += 1 }
            else if cInfo.count == 3 && cInfo.openEnds == 1 { score += 2000 }
            else if cInfo.count == 2 && cInfo.openEnds == 2 { score += Int(600.0 * openMul) }
            else if cInfo.count == 2 && cInfo.openEnds == 1 { score += 150 }
            else if cInfo.count == 1 && cInfo.openEnds == 2 { score += 30 }
            if pInfo.count >= 4 { score += 50000 }
            else if pInfo.count == 3 && pInfo.openEnds == 2 { score += 18000; threats += 1 }
            else if pInfo.count == 3 && pInfo.openEnds == 1 { score += 3000 }
            else if pInfo.count == 2 && pInfo.openEnds == 2 { score += Int(700.0 * openMul) }
            else if pInfo.count == 2 && pInfo.openEnds == 1 { score += 200 }
            else if pInfo.count == 1 && pInfo.openEnds == 2 { score += 35 }
        }
        if threats >= 2 { score += 25000 }
        let center = boardSize / 2
        let dist = abs(row - center) + abs(col - center)
        score += max(0, boardSize - dist) * 3
        return score
    }

    private func countDir(_ r: Int, _ c: Int, _ dr: Int, _ dc: Int, _ player: Int) -> Int {
        var count = 0
        var nr = r + dr, nc = c + dc
        while inBounds(nr, nc) && board[nr][nc] == player {
            count += 1
            nr += dr; nc += dc
        }
        return count
    }

    private func countDirOpen(_ r: Int, _ c: Int, _ dr: Int, _ dc: Int, _ player: Int) -> DirOpenResult {
        var fwd = 0, openEnds = 0
        var nr = r + dr, nc = c + dc
        while inBounds(nr, nc) && board[nr][nc] == player { fwd += 1; nr += dr; nc += dc }
        if inBounds(nr, nc) && board[nr][nc] == GameEngine.empty { openEnds += 1 }
        var bwd = 0
        nr = r - dr; nc = c - dc
        while inBounds(nr, nc) && board[nr][nc] == player { bwd += 1; nr -= dr; nc -= dc }
        if inBounds(nr, nc) && board[nr][nc] == GameEngine.empty { openEnds += 1 }
        return DirOpenResult(count: fwd + bwd, openEnds: openEnds)
    }

    private func filterWithLookahead(_ bestMoves: [(Int, Int)], emptyCells: [(Int, Int)]) -> [(Int, Int)] {
        var safe: [(Int, Int)] = []
        for m in bestMoves {
            board[m.0][m.1] = GameEngine.computer
            var opponentCanWin = false
            for o in emptyCells {
                if o.0 == m.0 && o.1 == m.1 { continue }
                if board[o.0][o.1] != GameEngine.empty { continue }
                board[o.0][o.1] = GameEngine.player
                if checkWin(row: o.0, col: o.1, player: GameEngine.player) != nil {
                    opponentCanWin = true
                }
                board[o.0][o.1] = GameEngine.empty
                if opponentCanWin { break }
            }
            board[m.0][m.1] = GameEngine.empty
            if !opponentCanWin { safe.append(m) }
        }
        return safe.isEmpty ? bestMoves : safe
    }

    func isWinningCell(row: Int, col: Int) -> Bool {
        winningCells.contains { $0.row == row && $0.col == col }
    }

    func isLastMove(row: Int, col: Int) -> Bool {
        guard let last = lastMove else { return false }
        return last.row == row && last.col == col
    }

    func moveNumber(row: Int, col: Int) -> Int? {
        guard board[row][col] != GameEngine.empty else { return nil }
        var count = 0
        for entry in moveHistory {
            count += 1
            if entry.player.0 == row && entry.player.1 == col { return count * 2 - 1 }
            if let comp = entry.computer {
                if comp.0 == row && comp.1 == col { return count * 2 }
            }
        }
        return nil
    }
}
