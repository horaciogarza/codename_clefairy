import Foundation

class DailyChallengeManager {
    static let shared = DailyChallengeManager()

    private let attemptKey = "daily_lastAttemptDate"
    private let completedKey = "daily_lastCompletedDate"
    private let scoreKey = "daily_bestScore"

    // MARK: - Seeded RNG (xorshift64)

    struct SeededRNG: RandomNumberGenerator {
        var state: UInt64

        init(seed: UInt64) {
            self.state = seed == 0 ? 1 : seed
        }

        mutating func next() -> UInt64 {
            state ^= state << 13
            state ^= state >> 7
            state ^= state << 17
            return state
        }
    }

    // MARK: - Daily Seed

    var todaySeed: UInt64 {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let dateString = formatter.string(from: Date())
        return UInt64(dateString) ?? 1
    }

    // MARK: - Attempt Tracking

    var hasAttemptedToday: Bool {
        guard let lastAttempt = UserDefaults.standard.string(forKey: attemptKey) else { return false }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return lastAttempt == formatter.string(from: Date())
    }

    var hasCompletedToday: Bool {
        guard let lastCompleted = UserDefaults.standard.string(forKey: completedKey) else { return false }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return lastCompleted == formatter.string(from: Date())
    }

    var bestDailyScore: Int {
        get { UserDefaults.standard.integer(forKey: scoreKey) }
        set { UserDefaults.standard.set(newValue, forKey: scoreKey) }
    }

    func recordAttempt() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        UserDefaults.standard.set(formatter.string(from: Date()), forKey: attemptKey)
    }

    func recordCompletion(score: Int) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        UserDefaults.standard.set(formatter.string(from: Date()), forKey: completedKey)
        if score > bestDailyScore {
            bestDailyScore = score
        }
    }

    // MARK: - Deterministic Daily Pool

    func getDailyPool(from emojis: [String], count: Int) -> [String] {
        var rng = SeededRNG(seed: todaySeed &+ 99991)
        var pool = emojis.sorted() // stable alphabetical base — same on every device
        for i in stride(from: pool.count - 1, through: 1, by: -1) {
            let j = Int(rng.next() % UInt64(i + 1))
            pool.swapAt(i, j)
        }
        return Array(pool.prefix(count))
    }

    // MARK: - Challenge Generation

    struct DailyRound {
        let poolSize: Int
        let sequenceLength: Int
        let emojiIndices: [Int]
    }

    func generateChallenge(emojiPool: [String]) -> [DailyRound] {
        var rng = SeededRNG(seed: todaySeed)
        var rounds: [DailyRound] = []

        for roundIndex in 0..<10 {
            let poolSize = min(8 + roundIndex, 20)
            let seqLength = min(2 + roundIndex / 2, 8)

            var indices: [Int] = []
            for _ in 0..<seqLength {
                let idx = Int(rng.next() % UInt64(min(poolSize, emojiPool.count)))
                indices.append(idx)
            }

            rounds.append(DailyRound(poolSize: poolSize, sequenceLength: seqLength, emojiIndices: indices))
        }

        return rounds
    }
}
