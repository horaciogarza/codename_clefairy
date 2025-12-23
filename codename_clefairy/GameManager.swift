import Foundation
import UIKit

// MARK: - Skin Animation Types
enum SkinAnimationType: String, Codable {
    case standard // Standard bounce
    case squish   // Jelly-like deformation
    case glitch   // Cyberpunk flicker/offset
    case heavy    // Wood/Metal rigid shake
}

// MARK: - Button Skins
enum ButtonSkin: String, CaseIterable, Codable {
    case classic = "Classic"
    case wood = "Jungle"
    case metal = "Cyber"
    case jelly = "Gummy"
    case galaxy = "Galaxy"
    case candy = "Candy"

    var buttonColor: UIColor {
        switch self {
        case .classic: return .white
        case .wood: return UIColor(red: 0.82, green: 0.70, blue: 0.55, alpha: 1.0)
        case .metal: return UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
        case .jelly: return UIColor(red: 1.0, green: 0.4, blue: 0.7, alpha: 0.6)
        case .galaxy: return UIColor(red: 0.1, green: 0.05, blue: 0.2, alpha: 0.9)
        case .candy: return UIColor(red: 1.0, green: 0.85, blue: 0.9, alpha: 1.0)
        }
    }

    var strokeColor: UIColor {
        switch self {
        case .classic: return UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0)
        case .wood: return UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        case .metal: return UIColor(red: 0.0, green: 1.0, blue: 0.8, alpha: 1.0)
        case .jelly: return UIColor(red: 1.0, green: 0.8, blue: 0.9, alpha: 0.5)
        case .galaxy: return UIColor(red: 0.6, green: 0.3, blue: 1.0, alpha: 1.0)
        case .candy: return UIColor(red: 1.0, green: 0.4, blue: 0.6, alpha: 1.0)
        }
    }

    var strokeWidth: CGFloat {
        switch self {
        case .classic: return 4
        case .wood: return 6
        case .metal: return 3
        case .jelly: return 0
        case .galaxy: return 3
        case .candy: return 5
        }
    }

    var fontColor: UIColor {
        switch self {
        case .metal: return .cyan
        case .wood: return UIColor(red: 0.3, green: 0.15, blue: 0.05, alpha: 1.0)
        case .galaxy: return UIColor(red: 0.8, green: 0.6, blue: 1.0, alpha: 1.0)
        default: return .black
        }
    }

    var boardColor: UIColor {
        switch self {
        case .classic: return .white.withAlphaComponent(0.9)
        case .wood: return UIColor(red: 0.95, green: 0.90, blue: 0.80, alpha: 1.0)
        case .metal: return UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 0.9)
        case .jelly: return UIColor(red: 0.5, green: 0.0, blue: 0.5, alpha: 0.3)
        case .galaxy: return UIColor(red: 0.05, green: 0.02, blue: 0.15, alpha: 0.95)
        case .candy: return UIColor(red: 1.0, green: 0.95, blue: 0.98, alpha: 0.95)
        }
    }

    var boardBorderColor: UIColor {
        switch self {
        case .classic: return UIColor(red: 0.25, green: 0.75, blue: 1.00, alpha: 1.0)
        case .wood: return UIColor(red: 0.5, green: 0.3, blue: 0.1, alpha: 1.0)
        case .metal: return UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.5)
        case .jelly: return UIColor(red: 1.0, green: 0.5, blue: 0.8, alpha: 0.8)
        case .galaxy: return UIColor(red: 0.5, green: 0.2, blue: 0.8, alpha: 0.8)
        case .candy: return UIColor(red: 1.0, green: 0.6, blue: 0.8, alpha: 1.0)
        }
    }

    var animationType: SkinAnimationType {
        switch self {
        case .classic: return .standard
        case .wood: return .heavy
        case .metal: return .glitch
        case .jelly: return .squish
        case .galaxy: return .glitch
        case .candy: return .squish
        }
    }

    var cost: Int {
        switch self {
        case .classic: return 0
        case .wood: return 200
        case .metal: return 500
        case .jelly: return 1000
        case .galaxy: return 1500
        case .candy: return 800
        }
    }

    var description: String {
        switch self {
        case .classic: return "Clean & simple"
        case .wood: return "Natural jungle vibes"
        case .metal: return "Neon cyberpunk glow"
        case .jelly: return "Squishy & bouncy"
        case .galaxy: return "Cosmic purple dreams"
        case .candy: return "Sweet pastel delight"
        }
    }

    var previewEmoji: String {
        switch self {
        case .classic: return "🧠"
        case .wood: return "🌿"
        case .metal: return "🤖"
        case .jelly: return "🍬"
        case .galaxy: return "🌌"
        case .candy: return "🍭"
        }
    }
}

// MARK: - Background Themes
enum BackgroundTheme: String, CaseIterable, Codable {
    case daylight = "Daylight"
    case sunset = "Sunset"
    case night = "Night Sky"
    case space = "Deep Space"
    case ocean = "Ocean"
    case forest = "Forest"
    case volcano = "Volcano"
    case arctic = "Arctic"

    var primaryColor: UIColor {
        switch self {
        case .daylight: return UIColor(red: 0.25, green: 0.75, blue: 1.00, alpha: 1.0)
        case .sunset: return UIColor(red: 1.0, green: 0.6, blue: 0.4, alpha: 1.0)
        case .night: return UIColor(red: 0.1, green: 0.1, blue: 0.3, alpha: 1.0)
        case .space: return UIColor(red: 0.02, green: 0.02, blue: 0.08, alpha: 1.0)
        case .ocean: return UIColor(red: 0.0, green: 0.4, blue: 0.7, alpha: 1.0)
        case .forest: return UIColor(red: 0.2, green: 0.5, blue: 0.3, alpha: 1.0)
        case .volcano: return UIColor(red: 0.3, green: 0.1, blue: 0.05, alpha: 1.0)
        case .arctic: return UIColor(red: 0.85, green: 0.92, blue: 0.98, alpha: 1.0)
        }
    }

    var secondaryColor: UIColor {
        switch self {
        case .daylight: return UIColor(red: 0.4, green: 0.8, blue: 0.4, alpha: 1.0)
        case .sunset: return UIColor(red: 1.0, green: 0.3, blue: 0.4, alpha: 1.0)
        case .night: return UIColor(red: 0.2, green: 0.2, blue: 0.5, alpha: 1.0)
        case .space: return UIColor(red: 0.1, green: 0.0, blue: 0.2, alpha: 1.0)
        case .ocean: return UIColor(red: 0.0, green: 0.6, blue: 0.5, alpha: 1.0)
        case .forest: return UIColor(red: 0.1, green: 0.35, blue: 0.15, alpha: 1.0)
        case .volcano: return UIColor(red: 0.8, green: 0.3, blue: 0.1, alpha: 1.0)
        case .arctic: return UIColor(red: 0.7, green: 0.85, blue: 0.95, alpha: 1.0)
        }
    }

    var accentEmoji: String {
        switch self {
        case .daylight: return "☀️"
        case .sunset: return "🌅"
        case .night: return "🌙"
        case .space: return "🚀"
        case .ocean: return "🐠"
        case .forest: return "🌲"
        case .volcano: return "🌋"
        case .arctic: return "❄️"
        }
    }

    var cost: Int {
        switch self {
        case .daylight: return 0
        case .sunset: return 150
        case .night: return 200
        case .space: return 400
        case .ocean: return 350
        case .forest: return 300
        case .volcano: return 500
        case .arctic: return 450
        }
    }

    var description: String {
        switch self {
        case .daylight: return "Bright sunny day"
        case .sunset: return "Golden hour vibes"
        case .night: return "Peaceful moonlit"
        case .space: return "Among the stars"
        case .ocean: return "Under the sea"
        case .forest: return "Deep in nature"
        case .volcano: return "Fiery adventure"
        case .arctic: return "Cool and crisp"
        }
    }
}

// MARK: - Emoji Packs
enum EmojiPack: String, CaseIterable, Codable {
    case standard = "Standard"
    case animals = "Zoo Friends"
    case food = "Yummy Food"
    case sports = "Sports Fan"
    case travel = "Traveler"
    case fantasy = "Fantasy"
    case space = "Space Explorer"
    case music = "Music Lover"

    var emojis: [String] {
        switch self {
        case .standard:
            return ["🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼", "🐨", "🐯",
                    "😂", "😍", "😎", "🤔", "😴", "🥳", "😱", "👻", "🤖", "👽",
                    "🍎", "🍌", "🍇", "🍓", "🥝", "🍑", "🍍", "🍉", "🍒", "🥭"]
        case .animals:
            return ["🦁", "🐘", "🦒", "🦓", "🦘", "🦔", "🦦", "🦥", "🐿️", "🦩",
                    "🦜", "🐢", "🦋", "🐝", "🦀", "🐙", "🦈", "🐬", "🐳", "🦭"]
        case .food:
            return ["🍕", "🍔", "🌮", "🍣", "🍜", "🍩", "🧁", "🍪", "🍫", "🍿",
                    "🥐", "🥨", "🧀", "🥚", "🥓", "🌭", "🍟", "🥗", "🍝", "🍰"]
        case .sports:
            return ["⚽️", "🏀", "🏈", "⚾️", "🎾", "🏐", "🏉", "🎱", "🏓", "🏸",
                    "🥊", "🏊", "🚴", "🏄", "⛷️", "🏂", "🎿", "🏋️", "🤸", "🏆"]
        case .travel:
            return ["✈️", "🚀", "🚂", "🚢", "🚗", "🏰", "🗼", "🗽", "🎡", "⛩️",
                    "🏝️", "🏔️", "🌋", "🏕️", "🎪", "🗿", "⛺️", "🌉", "🎢", "🛸"]
        case .fantasy:
            return ["🧙", "🧚", "🧜", "🧝", "🦄", "🐉", "🔮", "⚔️", "🛡️", "👑",
                    "💎", "🏹", "🪄", "🧞", "👹", "👺", "🎭", "🦇", "🕷️", "🌟"]
        case .space:
            return ["🚀", "🛸", "🌍", "🌙", "⭐️", "🌟", "💫", "☄️", "🪐", "🌌",
                    "👨‍🚀", "👽", "🛰️", "🔭", "🌑", "🌕", "☀️", "🌈", "💥", "🌠"]
        case .music:
            return ["🎵", "🎶", "🎸", "🎹", "🥁", "🎺", "🎷", "🎻", "🪕", "🎤",
                    "🎧", "📻", "🎼", "🪗", "🪘", "🎚️", "🎛️", "🎙️", "📯", "🔔"]
        }
    }

    var previewEmoji: String {
        switch self {
        case .standard: return "😊"
        case .animals: return "🦁"
        case .food: return "🍕"
        case .sports: return "⚽️"
        case .travel: return "✈️"
        case .fantasy: return "🦄"
        case .space: return "🚀"
        case .music: return "🎵"
        }
    }

    var cost: Int {
        switch self {
        case .standard: return 0
        case .animals: return 250
        case .food: return 250
        case .sports: return 300
        case .travel: return 350
        case .fantasy: return 400
        case .space: return 450
        case .music: return 300
        }
    }

    var description: String {
        switch self {
        case .standard: return "Classic emoji mix"
        case .animals: return "Wild animal kingdom"
        case .food: return "Delicious treats"
        case .sports: return "Athletic fun"
        case .travel: return "World explorer"
        case .fantasy: return "Magical creatures"
        case .space: return "Cosmic adventure"
        case .music: return "Musical vibes"
        }
    }
}

// MARK: - Special Effects
enum SpecialEffectPack: String, CaseIterable, Codable {
    case none = "None"
    case confetti = "Confetti"
    case fireworks = "Fireworks"
    case hearts = "Hearts"
    case stars = "Stardust"
    case bubbles = "Bubbles"
    case lightning = "Lightning"

    var previewEmoji: String {
        switch self {
        case .none: return "✖️"
        case .confetti: return "🎊"
        case .fireworks: return "🎆"
        case .hearts: return "💕"
        case .stars: return "⭐️"
        case .bubbles: return "🫧"
        case .lightning: return "⚡️"
        }
    }

    var cost: Int {
        switch self {
        case .none: return 0
        case .confetti: return 200
        case .fireworks: return 350
        case .hearts: return 250
        case .stars: return 300
        case .bubbles: return 200
        case .lightning: return 400
        }
    }

    var description: String {
        switch self {
        case .none: return "No extra effects"
        case .confetti: return "Party celebration"
        case .fireworks: return "Explosive victory"
        case .hearts: return "Lovely success"
        case .stars: return "Sparkling magic"
        case .bubbles: return "Floating joy"
        case .lightning: return "Electric power"
        }
    }
}

// MARK: - Power-ups
enum PowerUp: String, CaseIterable, Codable {
    case extraLife = "Extra Life"
    case timeFreeze = "Time Freeze"
    case hint = "Hint"
    case shield = "Shield"
    case doubleCoins = "Double Coins"

    var previewEmoji: String {
        switch self {
        case .extraLife: return "❤️‍🩹"
        case .timeFreeze: return "⏱️"
        case .hint: return "💡"
        case .shield: return "🛡️"
        case .doubleCoins: return "💰"
        }
    }

    var cost: Int {
        switch self {
        case .extraLife: return 50
        case .timeFreeze: return 75
        case .hint: return 30
        case .shield: return 100
        case .doubleCoins: return 150
        }
    }

    var description: String {
        switch self {
        case .extraLife: return "One extra heart"
        case .timeFreeze: return "Freeze timer 5s"
        case .hint: return "Show next emoji"
        case .shield: return "Block one mistake"
        case .doubleCoins: return "2x coins for round"
        }
    }
}

// MARK: - Store Category
enum StoreCategory: String, CaseIterable {
    case skins = "Skins"
    case themes = "Themes"
    case emojis = "Emojis"
    case effects = "Effects"
    case powerups = "Power-Ups"

    var icon: String {
        switch self {
        case .skins: return "🎨"
        case .themes: return "🌄"
        case .emojis: return "😀"
        case .effects: return "✨"
        case .powerups: return "⚡️"
        }
    }
}

// MARK: - Filter Type
enum StoreFilter: String, CaseIterable {
    case all = "All"
    case owned = "Owned"
    case affordable = "Affordable"
    case notOwned = "Not Owned"

    var icon: String {
        switch self {
        case .all: return "📦"
        case .owned: return "✅"
        case .affordable: return "💰"
        case .notOwned: return "🔒"
        }
    }
}

// MARK: - Game Manager
class GameManager {
    static let shared = GameManager()

    // Keys
    private let kScore = "kHighScore"
    private let kCoins = "kTotalCoins"
    private let kUnlockedSkins = "kUnlockedSkins"
    private let kSelectedSkin = "kSelectedSkin"
    private let kUnlockedThemes = "kUnlockedThemes"
    private let kSelectedTheme = "kSelectedTheme"
    private let kUnlockedEmojis = "kUnlockedEmojis"
    private let kSelectedEmojis = "kSelectedEmojis"
    private let kUnlockedEffects = "kUnlockedEffects"
    private let kSelectedEffect = "kSelectedEffect"
    private let kPowerUps = "kPowerUps"

    // MARK: - Basic Stats
    var highScore: Int {
        get { UserDefaults.standard.integer(forKey: kScore) }
        set { UserDefaults.standard.set(newValue, forKey: kScore) }
    }

    var totalCoins: Int {
        get { UserDefaults.standard.integer(forKey: kCoins) }
        set { UserDefaults.standard.set(newValue, forKey: kCoins) }
    }

    // MARK: - Skins
    var unlockedSkins: [ButtonSkin] {
        get {
            if let data = UserDefaults.standard.data(forKey: kUnlockedSkins),
               let skins = try? JSONDecoder().decode([ButtonSkin].self, from: data) {
                return skins
            }
            return [.classic]
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: kUnlockedSkins)
            }
        }
    }

    var selectedSkin: ButtonSkin {
        get {
            if let raw = UserDefaults.standard.string(forKey: kSelectedSkin),
               let skin = ButtonSkin(rawValue: raw) {
                return skin
            }
            return .classic
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: kSelectedSkin)
        }
    }

    // MARK: - Themes
    var unlockedThemes: [BackgroundTheme] {
        get {
            if let data = UserDefaults.standard.data(forKey: kUnlockedThemes),
               let themes = try? JSONDecoder().decode([BackgroundTheme].self, from: data) {
                return themes
            }
            return [.daylight]
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: kUnlockedThemes)
            }
        }
    }

    var selectedTheme: BackgroundTheme {
        get {
            if let raw = UserDefaults.standard.string(forKey: kSelectedTheme),
               let theme = BackgroundTheme(rawValue: raw) {
                return theme
            }
            return .daylight
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: kSelectedTheme)
        }
    }

    // MARK: - Emoji Packs
    var unlockedEmojiPacks: [EmojiPack] {
        get {
            if let data = UserDefaults.standard.data(forKey: kUnlockedEmojis),
               let packs = try? JSONDecoder().decode([EmojiPack].self, from: data) {
                return packs
            }
            return [.standard]
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: kUnlockedEmojis)
            }
        }
    }

    var selectedEmojiPack: EmojiPack {
        get {
            if let raw = UserDefaults.standard.string(forKey: kSelectedEmojis),
               let pack = EmojiPack(rawValue: raw) {
                return pack
            }
            return .standard
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: kSelectedEmojis)
        }
    }

    // MARK: - Effects
    var unlockedEffects: [SpecialEffectPack] {
        get {
            if let data = UserDefaults.standard.data(forKey: kUnlockedEffects),
               let effects = try? JSONDecoder().decode([SpecialEffectPack].self, from: data) {
                return effects
            }
            return [.none]
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: kUnlockedEffects)
            }
        }
    }

    var selectedEffect: SpecialEffectPack {
        get {
            if let raw = UserDefaults.standard.string(forKey: kSelectedEffect),
               let effect = SpecialEffectPack(rawValue: raw) {
                return effect
            }
            return .none
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: kSelectedEffect)
        }
    }

    // MARK: - Power-ups (Consumables)
    var powerUpInventory: [PowerUp: Int] {
        get {
            if let data = UserDefaults.standard.data(forKey: kPowerUps),
               let inventory = try? JSONDecoder().decode([String: Int].self, from: data) {
                var result: [PowerUp: Int] = [:]
                for (key, value) in inventory {
                    if let powerUp = PowerUp(rawValue: key) {
                        result[powerUp] = value
                    }
                }
                return result
            }
            return [:]
        }
        set {
            var stringDict: [String: Int] = [:]
            for (key, value) in newValue {
                stringDict[key.rawValue] = value
            }
            if let data = try? JSONEncoder().encode(stringDict) {
                UserDefaults.standard.set(data, forKey: kPowerUps)
            }
        }
    }

    func getPowerUpCount(_ powerUp: PowerUp) -> Int {
        return powerUpInventory[powerUp] ?? 0
    }

    // MARK: - Purchase Methods
    func unlockSkin(_ skin: ButtonSkin) -> Bool {
        if totalCoins >= skin.cost {
            totalCoins -= skin.cost
            var skins = unlockedSkins
            if !skins.contains(skin) {
                skins.append(skin)
                unlockedSkins = skins
            }
            return true
        }
        return false
    }

    func unlockTheme(_ theme: BackgroundTheme) -> Bool {
        if totalCoins >= theme.cost {
            totalCoins -= theme.cost
            var themes = unlockedThemes
            if !themes.contains(theme) {
                themes.append(theme)
                unlockedThemes = themes
            }
            return true
        }
        return false
    }

    func unlockEmojiPack(_ pack: EmojiPack) -> Bool {
        if totalCoins >= pack.cost {
            totalCoins -= pack.cost
            var packs = unlockedEmojiPacks
            if !packs.contains(pack) {
                packs.append(pack)
                unlockedEmojiPacks = packs
            }
            return true
        }
        return false
    }

    func unlockEffect(_ effect: SpecialEffectPack) -> Bool {
        if totalCoins >= effect.cost {
            totalCoins -= effect.cost
            var effects = unlockedEffects
            if !effects.contains(effect) {
                effects.append(effect)
                unlockedEffects = effects
            }
            return true
        }
        return false
    }

    func purchasePowerUp(_ powerUp: PowerUp, quantity: Int = 1) -> Bool {
        let totalCost = powerUp.cost * quantity
        if totalCoins >= totalCost {
            totalCoins -= totalCost
            var inventory = powerUpInventory
            inventory[powerUp] = (inventory[powerUp] ?? 0) + quantity
            powerUpInventory = inventory
            return true
        }
        return false
    }

    func usePowerUp(_ powerUp: PowerUp) -> Bool {
        var inventory = powerUpInventory
        if let count = inventory[powerUp], count > 0 {
            inventory[powerUp] = count - 1
            powerUpInventory = inventory
            return true
        }
        return false
    }
}
