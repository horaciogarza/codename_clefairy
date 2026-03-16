import SpriteKit

struct Achievement {
    let id: String
    let name: String
    let description: String
    let emoji: String
    let category: AchievementCategory
}

enum AchievementCategory: String {
    case level, score, boss, frenzy, streak, special
}

class AchievementManager {
    static let shared = AchievementManager()

    private let storageKey = "achievements_unlocked"

    // MARK: - Achievement Definitions

    static let allAchievements: [Achievement] = [
        // Level achievements
        Achievement(id: "level_5", name: "Getting Started", description: "Reach Level 5", emoji: "🌟", category: .level),
        Achievement(id: "level_10", name: "Memory Pro", description: "Reach Level 10", emoji: "🧠", category: .level),
        Achievement(id: "level_25", name: "Memory Master", description: "Reach Level 25", emoji: "👑", category: .level),

        // Score achievements
        Achievement(id: "score_1000", name: "Point Collector", description: "Score 1,000 points", emoji: "💰", category: .score),
        Achievement(id: "score_5000", name: "High Roller", description: "Score 5,000 points", emoji: "💎", category: .score),
        Achievement(id: "score_10000", name: "Score Legend", description: "Score 10,000 points", emoji: "🏆", category: .score),

        // Boss achievements
        Achievement(id: "boss_1", name: "Boss Slayer", description: "Defeat your first Boss", emoji: "⚔️", category: .boss),
        Achievement(id: "boss_5", name: "Boss Hunter", description: "Defeat 5 Bosses", emoji: "🐙", category: .boss),
        Achievement(id: "boss_10", name: "Boss Destroyer", description: "Defeat 10 Bosses", emoji: "💀", category: .boss),

        // Frenzy achievements
        Achievement(id: "frenzy_1", name: "On Fire", description: "Trigger Frenzy Mode", emoji: "🔥", category: .frenzy),
        Achievement(id: "frenzy_5", name: "Frenzy Fan", description: "Trigger 5 Frenzies", emoji: "🌋", category: .frenzy),

        // Streak achievements
        Achievement(id: "streak_3", name: "Consistent", description: "3-Day play streak", emoji: "📅", category: .streak),
        Achievement(id: "streak_7", name: "Dedicated", description: "7-Day play streak", emoji: "🗓️", category: .streak),
        Achievement(id: "streak_30", name: "Unstoppable", description: "30-Day play streak", emoji: "🏅", category: .streak),

        // Special achievements
        Achievement(id: "combo_10", name: "Combo King", description: "10+ tap combo streak", emoji: "⚡️", category: .special),
        Achievement(id: "daily_complete", name: "Daily Champion", description: "Complete a Daily Challenge", emoji: "🎯", category: .special),
    ]

    // MARK: - State

    private var unlockedAchievements: [String: String] {
        get {
            guard let data = UserDefaults.standard.data(forKey: storageKey),
                  let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
                return [:]
            }
            return dict
        }
        set {
            if let data = try? JSONSerialization.data(withJSONObject: newValue) {
                UserDefaults.standard.set(data, forKey: storageKey)
            }
        }
    }

    var unlockedCount: Int {
        return unlockedAchievements.count
    }

    func isUnlocked(_ achievementId: String) -> Bool {
        return unlockedAchievements[achievementId] != nil
    }

    // Returns newly unlocked achievement IDs
    @discardableResult
    func checkAchievements() -> [String] {
        let stats = StatsManager.shared
        var newlyUnlocked: [String] = []

        let checks: [(String, Bool)] = [
            ("level_5", stats.highestLevelReached >= 5),
            ("level_10", stats.highestLevelReached >= 10),
            ("level_25", stats.highestLevelReached >= 25),
            ("score_1000", GameManager.shared.highScore >= 1000),
            ("score_5000", GameManager.shared.highScore >= 5000),
            ("score_10000", GameManager.shared.highScore >= 10000),
            ("boss_1", stats.totalBossesDefeated >= 1),
            ("boss_5", stats.totalBossesDefeated >= 5),
            ("boss_10", stats.totalBossesDefeated >= 10),
            ("frenzy_1", stats.totalFrenziesTriggered >= 1),
            ("frenzy_5", stats.totalFrenziesTriggered >= 5),
            ("streak_3", stats.longestDailyStreak >= 3),
            ("streak_7", stats.longestDailyStreak >= 7),
            ("streak_30", stats.longestDailyStreak >= 30),
            ("combo_10", stats.bestComboStreak >= 10),
            ("daily_complete", DailyChallengeManager.shared.hasCompletedToday),
        ]

        var current = unlockedAchievements
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let now = formatter.string(from: Date())

        for (id, met) in checks {
            if met && current[id] == nil {
                current[id] = now
                newlyUnlocked.append(id)
            }
        }

        if !newlyUnlocked.isEmpty {
            unlockedAchievements = current
            ThemeManager.shared.checkUnlocks()
        }

        return newlyUnlocked
    }

    func achievement(for id: String) -> Achievement? {
        return Self.allAchievements.first(where: { $0.id == id })
    }

    // MARK: - Toast Display

    static func showUnlockToast(achievementId: String, in scene: SKScene) {
        guard let achievement = shared.achievement(for: achievementId) else { return }

        let container = SKNode()
        container.zPosition = 1000

        let bg = SKShapeNode(rectOf: CGSize(width: 280, height: 60), cornerRadius: 30)
        bg.fillColor = SKColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 0.95)
        bg.strokeColor = .systemYellow
        bg.lineWidth = 2
        container.addChild(bg)

        let emoji = SKLabelNode(text: achievement.emoji)
        emoji.fontSize = 28
        emoji.verticalAlignmentMode = .center
        emoji.position = CGPoint(x: -100, y: 0)
        container.addChild(emoji)

        let title = SKLabelNode(fontNamed: "Gameplay")
        title.text = achievement.name
        title.fontSize = 16
        title.fontColor = .systemYellow
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: -70, y: 8)
        container.addChild(title)

        let desc = SKLabelNode(fontNamed: "Gameplay")
        desc.text = achievement.description
        desc.fontSize = 11
        desc.fontColor = .lightGray
        desc.horizontalAlignmentMode = .left
        desc.position = CGPoint(x: -70, y: -10)
        container.addChild(desc)

        let safeBottom = scene.view?.safeAreaInsets.bottom ?? 20
        container.position = CGPoint(x: scene.frame.midX, y: -50)
        scene.addChild(container)

        let slideIn = SKAction.moveTo(y: safeBottom + 50, duration: 0.4)
        slideIn.timingMode = .easeOut
        let wait = SKAction.wait(forDuration: 2.5)
        let slideOut = SKAction.moveTo(y: -50, duration: 0.3)
        slideOut.timingMode = .easeIn

        container.run(SKAction.sequence([slideIn, wait, slideOut, SKAction.removeFromParent()]))
    }
}
