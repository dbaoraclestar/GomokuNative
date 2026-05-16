# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Gomoku (five-in-a-row) game for children, implemented as a native SwiftUI iOS app. The game features a computer opponent with age-based difficulty levels (4-5, 6-7, 8-9, 10-11, 12+) and three board sizes (9x9, 15x15, 19x19). Zero external dependencies.

**Bundle ID:** `com.guozh.gomoku-native` | **Deployment target:** iOS 15.0 | **Swift 5.0**

## Development

```bash
open GomokuNative.xcodeproj
# Build and run from Xcode (Cmd+R). No package manager, test framework, or CI pipeline.
# Changes are tested manually on device/simulator.
```

## Architecture

All source lives in `GomokuNative/`. Six files total — the app is intentionally flat with no navigation or persistence layer.

**Data flow:** `ContentView` owns a `@StateObject` `GameEngine`. `BoardView` and `StoneView` observe it via `@ObservedObject`. `SoundManager` is a standalone singleton called directly from `GameEngine`.

**Game loop:** Player taps a cell → `BoardView` calls `engine.handlePlayerMove()` → engine places stone, checks win → if game continues, schedules `doComputerMove()` on main queue after 0.4-0.8s delay → engine places AI stone, checks win → sets `currentPlayer` back to player.

**Undo model:** `moveHistory` stores `(playerMove, computerMove?)` pairs. Undo removes the last pair (both stones) in one operation, so the player never sees an intermediate state.

## AI Difficulty Model

Two levers: random-move probability and evaluation sophistication.

| Difficulty | Random % | Evaluator | Extra |
|-----------|----------|-----------|-------|
| 4-5 | 70% | `evaluateEasy` (simple count) | — |
| 6-7 | 35% | `evaluateMedium` (+center bias) | — |
| 8-9 | 15% | `evaluateAdvanced` (+open-end awareness) | — |
| 10-11 | 5% | `evaluateAdvanced` (lower open multiplier) | — |
| 12+ | 0% | `evaluateAdvanced` (full) | `filterWithLookahead` (1-ply pruning) |

When the random roll triggers, AI picks a random cell within distance-2 of an existing stone (not a truly random empty cell).

`evaluateAdvanced` scores each empty cell by examining all 4 directions via `countDirOpen()`, which returns consecutive-stone count and open-end count. This enables threat classification (open-three vs half-open-three). The `openMul` multiplier is 2.5 for age 10-11 and 3.0 for age 12+.

`filterWithLookahead` (age 12+ only) removes candidate moves where the opponent could win on the next turn — a 1-ply opponent-win pruning pass.

## Sound System

`SoundManager` generates all sounds procedurally via `AVAudioEngine` + `AVAudioPCMBuffer` — no audio asset files. Each sound creates a fresh `AVAudioEngine` instance on a background queue. Place sound uses a frequency sweep (800→400 Hz); win sound plays an ascending C-E-G-C sequence; lose sound plays a descending triangle-wave sequence.

## Layout

`ContentView` handles both portrait and landscape via `GeometryReader`. In landscape, board goes left and controls go right. In portrait, controls stack above and below the board, with board size calculated from remaining vertical space.
