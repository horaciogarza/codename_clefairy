import Foundation
import UIKit

enum GameMode {
    case classic
    case zen
}

// MARK: - Game Manager
class GameManager {
    static let shared = GameManager()

    // Keys
    private let kScore = "kHighScore"
    
    var currentMode: GameMode = .classic

    // MARK: - Basic Stats
    var highScore: Int {
        get { UserDefaults.standard.integer(forKey: kScore) }
        set { UserDefaults.standard.set(newValue, forKey: kScore) }
    }
    
    // Holiday-based Emoji Logic (Foundational rule-based model)
    var thematicEmojis: [String] {
        let month = Calendar.current.component(.month, from: Date())
        
        switch month {
        case 1: // January - New Year
            return ["🎆", "🥂", "🎉", "🏔️", "❄️", "📅", "🎯", "🌟"]
        case 2: // February - Love
            return ["❤️", "🌹", "🍫", "💍", "💌", "🧸", "🏹", "💖"]
        case 3: // March - Spring
            return ["🌱", "🌷", "☘️", "🌈", "🦋", "🌦️", "🐣", "🍃"]
        case 4: // April - Easter/Rain
            return ["🐰", "🥚", "☔️", "☔️", "🌼", "🧺", "🐝", "🍭"]
        case 5: // May - Flowers
            return ["🌸", "🌺", "☀️", "🍦", "🍓", "👒", "🛶", "💐"]
        case 6: // June - Summer
            return ["🏖️", "🕶️", "🍍", "🌊", "⛱️", "🩴", "🐚", "🐬"]
        case 7: // July - Fireworks/Heat
            return ["🎆", "🇺🇸", "🍔", "🌽", "🔥", "🛶", "🏕️", "🎇"]
        case 8: // August - Late Summer
            return ["🍉", "🌻", "🏄", "🍦", "🍹", "🌴", "🚲", "⛵️"]
        case 9: // September - Autumn/School
            return ["🍎", "📚", "🍂", "✏️", "🏫", "🎒", "🍁", "🍄"]
        case 10: // October - Halloween
            return ["🎃", "👻", "🦇", "🕸️", "🍬", "🕷️", "💀", "🧙"]
        case 11: // November - Harvest
            return ["🦃", "🥧", "🌽", "🧣", "🍂", "☕️", "🥧", "🕯️"]
        case 12: // December - Christmas/Winter
            return ["🎄", "🎅", "🎁", "❄️", "☃️", "🦌", "🔔", "🍪"]
        default:
            return defaultEmojis
        }
    }

    var defaultEmojis: [String] {
        return ["🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼", "🐨", "🐯",
                "😂", "😍", "😎", "🤔", "😴", "🥳", "😱", "👻", "🤖", "👽",
                "🍎", "🍌", "🍇", "🍓", "🥝", "🍑", "🍍", "🍉", "🍒", "🥭"]
    }
    
    func getActivePool(count: Int) -> [String] {
        // Blend holiday emojis with default emojis for variety
        let holidaySet = thematicEmojis.shuffled()
        let defaultSet = defaultEmojis.shuffled()
        let combined = Array((holidaySet + defaultSet).prefix(count))
        return combined.shuffled()
    }
}
