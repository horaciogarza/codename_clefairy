import Foundation

enum PowerUpType: String, CaseIterable {
    case peek = "peek"
    case slowMo = "slowmo"
    case shield = "shield"

    var displayName: String {
        switch self {
        case .peek: return "PEEK"
        case .slowMo: return "SLOW-MO"
        case .shield: return "SHIELD"
        }
    }

    var emoji: String {
        switch self {
        case .peek: return "👁️"
        case .slowMo: return "🐌"
        case .shield: return "🛡️"
        }
    }

    var description: String {
        switch self {
        case .peek: return "Re-show the sequence"
        case .slowMo: return "2x timer duration"
        case .shield: return "Prevent 1 life loss"
        }
    }
}

class PowerUpManager {
    static let shared = PowerUpManager()

    private let storageKey = "powerups_inventory"

    // MARK: - Inventory

    private var inventory: [String: Int] {
        get {
            guard let data = UserDefaults.standard.data(forKey: storageKey),
                  let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Int] else {
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

    func count(of type: PowerUpType) -> Int {
        return inventory[type.rawValue] ?? 0
    }

    func hasPowerUp(_ type: PowerUpType) -> Bool {
        return count(of: type) > 0
    }

    func consume(_ type: PowerUpType) -> Bool {
        let current = count(of: type)
        guard current > 0 else { return false }
        var inv = inventory
        inv[type.rawValue] = current - 1
        inventory = inv
        return true
    }

    func award(_ type: PowerUpType, count: Int = 1) {
        var inv = inventory
        inv[type.rawValue] = (inv[type.rawValue] ?? 0) + count
        inventory = inv
    }

    func awardRandomPowerUp() {
        guard let type = PowerUpType.allCases.randomElement() else { return }
        award(type)
    }

    // MARK: - Earning Logic

    func checkLevelRewards(level: Int) {
        if level > 0 && level % 5 == 0 {
            awardRandomPowerUp()
        }
    }

    func awardBossDefeatReward() {
        awardRandomPowerUp()
    }

    func awardDailyChallengeReward() {
        for type in PowerUpType.allCases {
            award(type)
        }
    }
}
