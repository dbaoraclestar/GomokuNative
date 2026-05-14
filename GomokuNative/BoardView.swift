import SwiftUI

struct BoardView: View {
    @ObservedObject var engine: GameEngine

    var body: some View {
        GeometryReader { geo in
            let labelWidth: CGFloat = 18
            let labelHeight: CGFloat = 16
            let availableWidth = geo.size.width - labelWidth
            let availableHeight = geo.size.height - labelHeight
            let totalSize = min(availableWidth, availableHeight)
            let cellSize = totalSize / CGFloat(engine.boardSize)

            VStack(spacing: 2) {
                HStack(spacing: 0) {
                    Spacer().frame(width: labelWidth)
                    ForEach(0..<engine.boardSize, id: \.self) { col in
                        Text(String(UnicodeScalar(65 + col)!))
                            .font(.system(size: min(10, cellSize * 0.35), weight: .semibold))
                            .foregroundColor(.white.opacity(0.55))
                            .frame(width: cellSize)
                    }
                }

                HStack(spacing: 4) {
                    VStack(spacing: 0) {
                        ForEach(0..<engine.boardSize, id: \.self) { row in
                            Text("\(row + 1)")
                                .font(.system(size: min(10, cellSize * 0.35), weight: .semibold))
                                .foregroundColor(.white.opacity(0.55))
                                .frame(width: labelWidth, height: cellSize)
                        }
                    }

                    boardGrid(totalSize: totalSize, cellSize: cellSize)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func boardGrid(totalSize: CGFloat, cellSize: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.72, green: 0.58, blue: 0.32))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(red: 0.50, green: 0.35, blue: 0.15), lineWidth: 4)
                )
                .shadow(color: Color.brown.opacity(0.3), radius: 8, y: 4)

            Canvas { context, size in
                let cs = cellSize
                let half = cs / 2
                for i in 0..<engine.boardSize {
                    let pos = half + CGFloat(i) * cs
                    var hPath = Path()
                    hPath.move(to: CGPoint(x: half, y: pos))
                    hPath.addLine(to: CGPoint(x: totalSize - half, y: pos))
                    context.stroke(hPath, with: .color(.black.opacity(0.7)), lineWidth: 1.0)

                    var vPath = Path()
                    vPath.move(to: CGPoint(x: pos, y: half))
                    vPath.addLine(to: CGPoint(x: pos, y: totalSize - half))
                    context.stroke(vPath, with: .color(.black.opacity(0.7)), lineWidth: 1.0)
                }
            }

            ForEach(0..<engine.boardSize, id: \.self) { row in
                ForEach(0..<engine.boardSize, id: \.self) { col in
                    let value = engine.board[row][col]
                    ZStack {
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                engine.handlePlayerMove(row: row, col: col)
                            }

                        if value != GameEngine.empty {
                            StoneView(
                                isBlack: value == GameEngine.player,
                                moveNumber: engine.moveNumber(row: row, col: col),
                                isWinning: engine.isWinningCell(row: row, col: col),
                                cellSize: cellSize
                            )
                        }

                        if engine.isLastMove(row: row, col: col) && !engine.isWinningCell(row: row, col: col) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                        }
                    }
                    .frame(width: cellSize, height: cellSize)
                    .position(
                        x: (CGFloat(col) + 0.5) * cellSize,
                        y: (CGFloat(row) + 0.5) * cellSize
                    )
                }
            }
        }
        .frame(width: totalSize, height: totalSize)
    }
}
