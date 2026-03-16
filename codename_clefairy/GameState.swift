import Foundation

indirect enum GameState: Equatable {
    case idle
    case countdown(Int)
    case showingSequence
    case awaitingInput
    case verifying
    case levelUp
    case bossWarning
    case bossCountdown(Int)
    case bossShowingSequence
    case bossAwaitingInput
    case bossVerifying
    case bossDefeated
    case gameOver
    case paused(previous: GameState)

    var isAcceptingInput: Bool {
        switch self {
        case .awaitingInput, .bossAwaitingInput:
            return true
        default:
            return false
        }
    }

    var isBossPhase: Bool {
        switch self {
        case .bossWarning, .bossCountdown, .bossShowingSequence,
             .bossAwaitingInput, .bossVerifying, .bossDefeated:
            return true
        default:
            return false
        }
    }

    var canPause: Bool {
        switch self {
        case .awaitingInput, .bossAwaitingInput, .showingSequence,
             .bossShowingSequence, .countdown, .bossCountdown:
            return true
        default:
            return false
        }
    }

    // Custom Equatable to handle paused's associated value
    static func == (lhs: GameState, rhs: GameState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.showingSequence, .showingSequence),
             (.awaitingInput, .awaitingInput),
             (.verifying, .verifying),
             (.levelUp, .levelUp),
             (.bossWarning, .bossWarning),
             (.bossShowingSequence, .bossShowingSequence),
             (.bossAwaitingInput, .bossAwaitingInput),
             (.bossVerifying, .bossVerifying),
             (.bossDefeated, .bossDefeated),
             (.gameOver, .gameOver):
            return true
        case (.countdown(let a), .countdown(let b)):
            return a == b
        case (.bossCountdown(let a), .bossCountdown(let b)):
            return a == b
        case (.paused(let a), .paused(let b)):
            return a == b
        default:
            return false
        }
    }
}
