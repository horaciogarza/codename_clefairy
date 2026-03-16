import SpriteKit

struct GameTheme {
    let id: String
    let name: String
    let skyColor: SKColor
    let hillColor: SKColor
    let hillColorDark: SKColor
    let accentColor: SKColor
    let boardColor: SKColor
    let buttonStrokeColor: SKColor
    let textColor: SKColor
    let frenzyBgColor: SKColor
    let frenzyHillColor: SKColor
    let unlockRequirement: String

    func isUnlocked() -> Bool {
        return ThemeManager.shared.isThemeUnlocked(id)
    }
}

class ThemeManager {
    static let shared = ThemeManager()

    private let unlockedKey = "themes_unlocked"

    // MARK: - Theme Definitions

    static let defaultTheme = GameTheme(
        id: "default",
        name: "Classic",
        skyColor: SKColor(red: 0.25, green: 0.75, blue: 1.00, alpha: 1.0),
        hillColor: SKColor(red: 0.4, green: 0.8, blue: 0.4, alpha: 1.0),
        hillColorDark: SKColor(red: 0.3, green: 0.7, blue: 0.3, alpha: 1.0),
        accentColor: .systemYellow,
        boardColor: .white,
        buttonStrokeColor: SKColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0),
        textColor: .white,
        frenzyBgColor: SKColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0),
        frenzyHillColor: .orange,
        unlockRequirement: "Free"
    )

    static let darkTheme = GameTheme(
        id: "dark",
        name: "Dark Mode",
        skyColor: SKColor(red: 0.08, green: 0.08, blue: 0.15, alpha: 1.0),
        hillColor: SKColor(red: 0.15, green: 0.15, blue: 0.25, alpha: 1.0),
        hillColorDark: SKColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0),
        accentColor: .systemPurple,
        boardColor: SKColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 0.9),
        buttonStrokeColor: .systemPurple,
        textColor: .white,
        frenzyBgColor: SKColor(red: 0.4, green: 0.1, blue: 0.5, alpha: 1.0),
        frenzyHillColor: .systemPurple,
        unlockRequirement: "Reach Level 10"
    )

    static let neonTheme = GameTheme(
        id: "neon",
        name: "Neon",
        skyColor: SKColor(red: 0.05, green: 0.0, blue: 0.15, alpha: 1.0),
        hillColor: SKColor(red: 0.0, green: 0.3, blue: 0.2, alpha: 1.0),
        hillColorDark: SKColor(red: 0.0, green: 0.2, blue: 0.15, alpha: 1.0),
        accentColor: .systemCyan,
        boardColor: SKColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 0.9),
        buttonStrokeColor: .systemCyan,
        textColor: .cyan,
        frenzyBgColor: SKColor(red: 0.3, green: 0.0, blue: 0.3, alpha: 1.0),
        frenzyHillColor: .systemPink,
        unlockRequirement: "Reach Level 25"
    )

    static let retroTheme = GameTheme(
        id: "retro",
        name: "Retro",
        skyColor: SKColor(red: 0.6, green: 0.5, blue: 0.3, alpha: 1.0),
        hillColor: SKColor(red: 0.4, green: 0.6, blue: 0.2, alpha: 1.0),
        hillColorDark: SKColor(red: 0.3, green: 0.5, blue: 0.15, alpha: 1.0),
        accentColor: .systemOrange,
        boardColor: SKColor(red: 0.95, green: 0.9, blue: 0.8, alpha: 0.9),
        buttonStrokeColor: .systemBrown,
        textColor: .brown,
        frenzyBgColor: SKColor(red: 0.8, green: 0.3, blue: 0.1, alpha: 1.0),
        frenzyHillColor: .systemBrown,
        unlockRequirement: "Defeat 5 Bosses"
    )

    static let natureTheme = GameTheme(
        id: "nature",
        name: "Nature",
        skyColor: SKColor(red: 0.5, green: 0.8, blue: 0.9, alpha: 1.0),
        hillColor: SKColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0),
        hillColorDark: SKColor(red: 0.15, green: 0.6, blue: 0.25, alpha: 1.0),
        accentColor: .systemGreen,
        boardColor: SKColor(red: 0.95, green: 1.0, blue: 0.95, alpha: 0.9),
        buttonStrokeColor: .systemGreen,
        textColor: .darkGray,
        frenzyBgColor: SKColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 1.0),
        frenzyHillColor: .systemGreen,
        unlockRequirement: "7-Day Streak"
    )

    static let oceanTheme = GameTheme(
        id: "ocean",
        name: "Ocean",
        skyColor: SKColor(red: 0.1, green: 0.3, blue: 0.6, alpha: 1.0),
        hillColor: SKColor(red: 0.1, green: 0.4, blue: 0.7, alpha: 1.0),
        hillColorDark: SKColor(red: 0.08, green: 0.3, blue: 0.6, alpha: 1.0),
        accentColor: .systemTeal,
        boardColor: SKColor(red: 0.85, green: 0.95, blue: 1.0, alpha: 0.9),
        buttonStrokeColor: .systemTeal,
        textColor: .white,
        frenzyBgColor: SKColor(red: 0.0, green: 0.2, blue: 0.5, alpha: 1.0),
        frenzyHillColor: .systemTeal,
        unlockRequirement: "Score 5000"
    )

    static let sunsetTheme = GameTheme(
        id: "sunset",
        name: "Sunset",
        skyColor: SKColor(red: 0.9, green: 0.5, blue: 0.3, alpha: 1.0),
        hillColor: SKColor(red: 0.6, green: 0.3, blue: 0.4, alpha: 1.0),
        hillColorDark: SKColor(red: 0.5, green: 0.25, blue: 0.35, alpha: 1.0),
        accentColor: .systemOrange,
        boardColor: SKColor(red: 1.0, green: 0.95, blue: 0.9, alpha: 0.9),
        buttonStrokeColor: .systemOrange,
        textColor: .white,
        frenzyBgColor: SKColor(red: 0.8, green: 0.2, blue: 0.1, alpha: 1.0),
        frenzyHillColor: .systemRed,
        unlockRequirement: "Earn 5 Achievements"
    )

    static let allThemes: [GameTheme] = [
        defaultTheme, darkTheme, neonTheme, retroTheme,
        natureTheme, oceanTheme, sunsetTheme
    ]

    // MARK: - State

    var currentTheme: GameTheme {
        let id = UserDefaults.standard.string(forKey: "settings_currentTheme") ?? "default"
        return Self.allThemes.first(where: { $0.id == id }) ?? Self.defaultTheme
    }

    func setCurrentTheme(_ themeId: String) {
        guard isThemeUnlocked(themeId) else { return }
        UserDefaults.standard.set(themeId, forKey: "settings_currentTheme")
    }

    func isThemeUnlocked(_ themeId: String) -> Bool {
        if themeId == "default" { return true }
        let unlocked = UserDefaults.standard.stringArray(forKey: unlockedKey) ?? []
        return unlocked.contains(themeId)
    }

    func unlockTheme(_ themeId: String) {
        var unlocked = UserDefaults.standard.stringArray(forKey: unlockedKey) ?? []
        if !unlocked.contains(themeId) {
            unlocked.append(themeId)
            UserDefaults.standard.set(unlocked, forKey: unlockedKey)
        }
    }

    func checkUnlocks() {
        let stats = StatsManager.shared

        if stats.highestLevelReached >= 10 { unlockTheme("dark") }
        if stats.highestLevelReached >= 25 { unlockTheme("neon") }
        if stats.totalBossesDefeated >= 5 { unlockTheme("retro") }
        if stats.currentDailyStreak >= 7 { unlockTheme("nature") }
        if GameManager.shared.highScore >= 5000 { unlockTheme("ocean") }

        let achievementCount = AchievementManager.shared.unlockedCount
        if achievementCount >= 5 { unlockTheme("sunset") }
    }
}
