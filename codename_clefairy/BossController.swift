import SpriteKit

/// A distinct boss with its own emoji and a full-screen color palette so each
/// boss level looks completely different from the normal stages.
struct BossDef {
    let name: String
    let emoji: String
    let skyColor: SKColor
    let hillColor: SKColor
    let hillColorDark: SKColor
    let accentColor: SKColor

    static let all: [BossDef] = [
        BossDef(name: "THE KRAKEN", emoji: "🐙",
                skyColor: SKColor(red: 0.04, green: 0.10, blue: 0.22, alpha: 1.0),
                hillColor: SKColor(red: 0.10, green: 0.22, blue: 0.40, alpha: 1.0),
                hillColorDark: SKColor(red: 0.05, green: 0.13, blue: 0.28, alpha: 1.0),
                accentColor: .systemTeal),
        BossDef(name: "INFERNO WYRM", emoji: "🐉",
                skyColor: SKColor(red: 0.22, green: 0.04, blue: 0.04, alpha: 1.0),
                hillColor: SKColor(red: 0.45, green: 0.12, blue: 0.05, alpha: 1.0),
                hillColorDark: SKColor(red: 0.28, green: 0.06, blue: 0.03, alpha: 1.0),
                accentColor: .systemOrange),
        BossDef(name: "THE ONI", emoji: "👹",
                skyColor: SKColor(red: 0.12, green: 0.03, blue: 0.18, alpha: 1.0),
                hillColor: SKColor(red: 0.30, green: 0.10, blue: 0.40, alpha: 1.0),
                hillColorDark: SKColor(red: 0.18, green: 0.05, blue: 0.26, alpha: 1.0),
                accentColor: .systemPurple),
        BossDef(name: "MECHA-X", emoji: "🤖",
                skyColor: SKColor(red: 0.10, green: 0.12, blue: 0.16, alpha: 1.0),
                hillColor: SKColor(red: 0.22, green: 0.26, blue: 0.32, alpha: 1.0),
                hillColorDark: SKColor(red: 0.14, green: 0.17, blue: 0.22, alpha: 1.0),
                accentColor: .systemCyan),
        BossDef(name: "THE PHANTOM", emoji: "👻",
                skyColor: SKColor(red: 0.03, green: 0.10, blue: 0.08, alpha: 1.0),
                hillColor: SKColor(red: 0.08, green: 0.24, blue: 0.18, alpha: 1.0),
                hillColorDark: SKColor(red: 0.04, green: 0.15, blue: 0.11, alpha: 1.0),
                accentColor: .systemGreen),
        BossDef(name: "FROST TITAN", emoji: "❄️",
                skyColor: SKColor(red: 0.06, green: 0.16, blue: 0.26, alpha: 1.0),
                hillColor: SKColor(red: 0.20, green: 0.38, blue: 0.52, alpha: 1.0),
                hillColorDark: SKColor(red: 0.12, green: 0.26, blue: 0.38, alpha: 1.0),
                accentColor: .white)
    ]

    /// Picks a boss for a boss level (every 5th level), cycling through the roster.
    static func forLevel(_ level: Int) -> BossDef {
        let bossNumber = max(1, level / 5)
        return all[(bossNumber - 1) % all.count]
    }
}

protocol BossControllerDelegate: AnyObject {
    func bossPhaseReady()
    func bossDefeated()
}

class BossController {
    weak var scene: SKScene?
    weak var delegate: BossControllerDelegate?

    var bossNode: SKLabelNode?
    var bossRound = 0

    init(scene: SKScene) {
        self.scene = scene
    }

    func reset() {
        bossRound = 0
        bossNode?.removeFromParent()
        bossNode = nil
    }

    func startBossRound(boss: BossDef, stageNode: SKShapeNode, levelLabel: SKLabelNode, animations: GameAnimations, playSound: @escaping (String) -> Void) {
        bossRound = 0

        levelLabel.text = boss.name
        levelLabel.fontColor = boss.accentColor
        if let shadow = levelLabel.children.first as? SKLabelNode {
            shadow.text = boss.name
        }

        animations.showBossEntrance(boss: boss, stageNode: stageNode, playSound: playSound) { [weak self] bossNode in
            self?.bossNode = bossNode
            self?.delegate?.bossPhaseReady()
        }
    }

    func advancePhase() -> Bool {
        bossRound += 1
        if bossRound >= 3 {
            // Boss defeated
            bossNode?.run(SKAction.sequence([
                SKAction.scale(to: 0, duration: 0.5),
                SKAction.removeFromParent()
            ]))
            bossNode = nil
            return false // no more phases
        }
        return true // more phases remain
    }

    var currentPhaseText: String {
        return "ATTACK \(bossRound + 1)!"
    }
}
