import Foundation
import UIKit

enum SkinAnimationType: String, Codable {
    case standard // Standard bounce
    case squish   // Jelly-like deformation
    case glitch   // Cyberpunk flicker/offset
    case heavy    // Wood/Metal rigid shake
}

enum ButtonSkin: String, CaseIterable, Codable {
    case classic = "Classic"
    case wood = "Jungle"
    case metal = "Cyber"
    case jelly = "Gummy"
    
    // Button Appearance
    var buttonColor: UIColor {
        switch self {
        case .classic: return .white
        case .wood: return UIColor(red: 0.82, green: 0.70, blue: 0.55, alpha: 1.0) // Light wood
        case .metal: return UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0) // Dark Metal
        case .jelly: return UIColor(red: 1.0, green: 0.4, blue: 0.7, alpha: 0.6) // Translucent Pink
        }
    }
    
    var strokeColor: UIColor {
        switch self {
        case .classic: return UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0)
        case .wood: return UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0) // Dark brown
        case .metal: return UIColor(red: 0.0, green: 1.0, blue: 0.8, alpha: 1.0) // Neon Cyan
        case .jelly: return UIColor(red: 1.0, green: 0.8, blue: 0.9, alpha: 0.5) // Light highlight
        }
    }
    
    var strokeWidth: CGFloat {
        switch self {
        case .classic: return 4
        case .wood: return 6
        case .metal: return 3
        case .jelly: return 0 // No border for jelly, looks softer
        }
    }
    
    var fontColor: UIColor {
        switch self {
        case .metal: return .cyan // Neon text
        case .wood: return UIColor(red: 0.3, green: 0.15, blue: 0.05, alpha: 1.0)
        default: return .black
        }
    }
    
    // Board (Whiteboard) Appearance
    var boardColor: UIColor {
        switch self {
        case .classic: return .white.withAlphaComponent(0.9)
        case .wood: return UIColor(red: 0.95, green: 0.90, blue: 0.80, alpha: 1.0) // Parchment
        case .metal: return UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 0.9) // Dark Screen
        case .jelly: return UIColor(red: 0.5, green: 0.0, blue: 0.5, alpha: 0.3) // Purple glass
        }
    }
    
    var boardBorderColor: UIColor {
        switch self {
        case .classic: return UIColor(red: 0.25, green: 0.75, blue: 1.00, alpha: 1.0)
        case .wood: return UIColor(red: 0.5, green: 0.3, blue: 0.1, alpha: 1.0)
        case .metal: return UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.5)
        case .jelly: return UIColor(red: 1.0, green: 0.5, blue: 0.8, alpha: 0.8)
        }
    }
    
    var animationType: SkinAnimationType {
        switch self {
        case .classic: return .standard
        case .wood: return .heavy
        case .metal: return .glitch
        case .jelly: return .squish
        }
    }
    
    var cost: Int {
        switch self {
        case .classic: return 0
        case .wood: return 200
        case .metal: return 500
        case .jelly: return 1000
        }
    }
}

class GameManager {
    static let shared = GameManager()
    
    private let kScore = "kHighScore"
    private let kCoins = "kTotalCoins"
    private let kUnlocked = "kUnlockedSkins"
    private let kSelected = "kSelectedSkin"
    
    var highScore: Int {
        get { UserDefaults.standard.integer(forKey: kScore) }
        set { UserDefaults.standard.set(newValue, forKey: kScore) }
    }
    
    var totalCoins: Int {
        get { UserDefaults.standard.integer(forKey: kCoins) }
        set { UserDefaults.standard.set(newValue, forKey: kCoins) }
    }
    
    var unlockedSkins: [ButtonSkin] {
        get {
            if let data = UserDefaults.standard.data(forKey: kUnlocked),
               let skins = try? JSONDecoder().decode([ButtonSkin].self, from: data) {
                return skins
            }
            return [.classic]
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: kUnlocked)
            }
        }
    }
    
    var selectedSkin: ButtonSkin {
        get {
            if let raw = UserDefaults.standard.string(forKey: kSelected),
               let skin = ButtonSkin(rawValue: raw) {
                return skin
            }
            return .classic
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: kSelected)
        }
    }
    
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
}