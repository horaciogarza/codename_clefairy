import SpriteKit

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

    func startBossRound(stageNode: SKShapeNode, levelLabel: SKLabelNode, animations: GameAnimations, playSound: @escaping (String) -> Void) {
        bossRound = 0

        levelLabel.text = "BOSS BATTLE!"
        levelLabel.fontColor = .systemRed
        if let shadow = levelLabel.children.first as? SKLabelNode {
            shadow.text = "BOSS BATTLE!"
        }

        animations.showBossEntrance(stageNode: stageNode, playSound: playSound) { [weak self] boss in
            self?.bossNode = boss
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
