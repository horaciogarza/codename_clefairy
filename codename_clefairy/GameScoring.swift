import SpriteKit

class GameScoring {

    // Session Stats
    var totalTapPoints = 0
    var totalBaseLevelPoints = 0
    var totalSpeedBonusPoints = 0
    var totalBossPoints = 0
    var totalFrenzyMultiplierPoints = 0

    var currentScore = 0
    var comboCount = 0
    var lastTapTime: TimeInterval = 0

    // Heat/Frenzy
    var heatValue: CGFloat = 0
    var isFrenzyMode = false

    // Session tracking
    var bossesDefeatedThisSession = 0
    var frenziesTriggeredThisSession = 0
    var bestComboThisSession = 0
    var sessionStartTime: Date?

    func reset() {
        totalTapPoints = 0
        totalBaseLevelPoints = 0
        totalSpeedBonusPoints = 0
        totalBossPoints = 0
        totalFrenzyMultiplierPoints = 0
        currentScore = 0
        comboCount = 0
        lastTapTime = 0
        heatValue = 0
        isFrenzyMode = false
        bossesDefeatedThisSession = 0
        frenziesTriggeredThisSession = 0
        bestComboThisSession = 0
        sessionStartTime = Date()
    }

    // MARK: - Tap Scoring

    struct TapResult {
        let tapPoints: Int
        let heatChanged: Bool
        let frenzyTriggered: Bool
    }

    func processTap() -> TapResult {
        let now = Date().timeIntervalSince1970

        // Heat System Logic
        if now - lastTapTime < 0.6 {
            heatValue = min(1.0, heatValue + 0.15)
            comboCount += 1
        } else {
            heatValue = max(0, heatValue - 0.05)
            comboCount = 0
        }

        if comboCount > bestComboThisSession {
            bestComboThisSession = comboCount
        }

        let tapPoints = 5 + (comboCount * 2)
        currentScore += tapPoints
        totalTapPoints += tapPoints

        lastTapTime = now

        let frenzyTriggered = heatValue >= 1.0 && !isFrenzyMode
        if frenzyTriggered {
            isFrenzyMode = true
            frenziesTriggeredThisSession += 1
        }

        return TapResult(tapPoints: tapPoints, heatChanged: true, frenzyTriggered: frenzyTriggered)
    }

    // MARK: - Round Scoring

    func scoreBossPhaseComplete(level: Int, remainingTime: Int) -> Int {
        let baseScore = level * 20
        let speedBonus = remainingTime * 10
        let total = baseScore + speedBonus
        currentScore += total
        totalBossPoints += total
        return total
    }

    func recordBossDefeated() {
        bossesDefeatedThisSession += 1
    }

    func scoreRoundComplete(level: Int, remainingTime: Int, isBoss: Bool) -> Int {
        if isBoss {
            return scoreBossPhaseComplete(level: level, remainingTime: remainingTime)
        } else {
            let baseLevelScore = level * 10
            let speedBonus = remainingTime * 5
            let roundTotalBeforeFrenzy = baseLevelScore + speedBonus

            totalBaseLevelPoints += baseLevelScore
            totalSpeedBonusPoints += speedBonus

            var totalRoundPoints = roundTotalBeforeFrenzy
            if isFrenzyMode {
                let frenzyBonus = totalRoundPoints
                totalFrenzyMultiplierPoints += frenzyBonus
                totalRoundPoints += frenzyBonus
            }

            currentScore += totalRoundPoints
            return totalRoundPoints
        }
    }

    // MARK: - Verification

    struct VerifyResult {
        let allCorrect: Bool
        let perItemCorrect: [Bool]
    }

    func verifySequence(user: [String], expected: [String]) -> VerifyResult {
        var perItem: [Bool] = []
        var allCorrect = true

        for i in 0..<expected.count {
            let correct = i < user.count && user[i] == expected[i]
            perItem.append(correct)
            if !correct { allCorrect = false }
        }

        return VerifyResult(allCorrect: allCorrect, perItemCorrect: perItem)
    }

    // MARK: - Frenzy

    func endFrenzy() {
        isFrenzyMode = false
        heatValue = 0
    }

    // MARK: - Session End

    func sessionTimePlayed() -> TimeInterval {
        guard let start = sessionStartTime else { return 0 }
        return Date().timeIntervalSince(start)
    }
}
