import Foundation
import UIKit

enum ButtonSkin: String, CaseIterable, Codable {
    case classic = "Classic"
    case wood = "Wood"
    case metal = "Metal"
    case jelly = "Jelly"
    
    var primaryColor: UIColor {
        switch self {
        case .classic: return .white
        case .wood: return UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
        case .metal: return UIColor(red: 0.8, green: 0.8, blue: 0.85, alpha: 1.0)
        case .jelly: return UIColor(red: 1.0, green: 0.6, blue: 0.8, alpha: 0.8)
        }
    }
    
    var strokeColor: UIColor {
        switch self {
        case .classic: return UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0)
        case .wood: return UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        case .metal: return UIColor(red: 0.5, green: 0.5, blue: 0.6, alpha: 1.0)
        case .jelly: return UIColor(red: 1.0, green: 0.2, blue: 0.6, alpha: 1.0)
        }
    }
    
    var cost: Int {
        switch self {
        case .classic: return 0
        case .wood: return 500
        case .metal: return 1000
        case .jelly: return 2000
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
