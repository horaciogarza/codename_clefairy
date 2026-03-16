import Foundation

class StatsManager {
    static let shared = StatsManager()

    private let prefix = "stats_"

    private func key(_ name: String) -> String { prefix + name }

    var totalGamesPlayed: Int {
        get { UserDefaults.standard.integer(forKey: key("totalGamesPlayed")) }
        set { UserDefaults.standard.set(newValue, forKey: key("totalGamesPlayed")) }
    }

    var highestLevelReached: Int {
        get { UserDefaults.standard.integer(forKey: key("highestLevelReached")) }
        set { UserDefaults.standard.set(newValue, forKey: key("highestLevelReached")) }
    }

    var totalBossesDefeated: Int {
        get { UserDefaults.standard.integer(forKey: key("totalBossesDefeated")) }
        set { UserDefaults.standard.set(newValue, forKey: key("totalBossesDefeated")) }
    }

    var totalFrenziesTriggered: Int {
        get { UserDefaults.standard.integer(forKey: key("totalFrenziesTriggered")) }
        set { UserDefaults.standard.set(newValue, forKey: key("totalFrenziesTriggered")) }
    }

    var bestComboStreak: Int {
        get { UserDefaults.standard.integer(forKey: key("bestComboStreak")) }
        set { UserDefaults.standard.set(newValue, forKey: key("bestComboStreak")) }
    }

    var totalTimePlayed: TimeInterval {
        get { UserDefaults.standard.double(forKey: key("totalTimePlayed")) }
        set { UserDefaults.standard.set(newValue, forKey: key("totalTimePlayed")) }
    }

    var currentDailyStreak: Int {
        get { UserDefaults.standard.integer(forKey: key("currentDailyStreak")) }
        set { UserDefaults.standard.set(newValue, forKey: key("currentDailyStreak")) }
    }

    var longestDailyStreak: Int {
        get { UserDefaults.standard.integer(forKey: key("longestDailyStreak")) }
        set { UserDefaults.standard.set(newValue, forKey: key("longestDailyStreak")) }
    }

    var lastPlayedDate: Date? {
        get { UserDefaults.standard.object(forKey: key("lastPlayedDate")) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: key("lastPlayedDate")) }
    }

    // MARK: - Recording

    func recordGameStart() {
        totalGamesPlayed += 1
    }

    func recordGameEnd(level: Int, score: Int, bossesDefeated: Int, frenziesTriggered: Int, bestCombo: Int, timePlayed: TimeInterval) {
        if level > highestLevelReached {
            highestLevelReached = level
        }
        totalBossesDefeated += bossesDefeated
        totalFrenziesTriggered += frenziesTriggered
        if bestCombo > bestComboStreak {
            bestComboStreak = bestCombo
        }
        totalTimePlayed += timePlayed

        AchievementManager.shared.checkAchievements()
    }

    func recordDailyPlay() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastPlayed = lastPlayedDate {
            let lastDay = calendar.startOfDay(for: lastPlayed)
            let daysBetween = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysBetween == 1 {
                // Consecutive day
                currentDailyStreak += 1
            } else if daysBetween > 1 {
                // Streak broken
                currentDailyStreak = 1
            }
            // daysBetween == 0 means same day, don't change streak
        } else {
            // First time playing
            currentDailyStreak = 1
        }

        if currentDailyStreak > longestDailyStreak {
            longestDailyStreak = currentDailyStreak
        }

        lastPlayedDate = today

        // Award streak rewards
        let milestones = [3, 7, 14, 30]
        if milestones.contains(currentDailyStreak) {
            PowerUpManager.shared.awardRandomPowerUp()
        }
    }
}
