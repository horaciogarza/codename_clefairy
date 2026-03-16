import SpriteKit

protocol GameTimerDelegate: AnyObject {
    func timerDidTick(remaining: Int)
    func timerDidExpire()
}

class GameTimerController {
    weak var delegate: GameTimerDelegate?
    weak var scene: SKScene?

    private var selectionTimer: Timer?
    private(set) var remainingTime: Int = 0
    private var maxTime: Int = 0

    // Node references (set by GameScene)
    weak var timerLabel: SKLabelNode?
    weak var timerOverlay: SKShapeNode?

    init(scene: SKScene) {
        self.scene = scene
    }

    func startTimer(duration: Int) {
        selectionTimer?.invalidate()
        remainingTime = duration
        maxTime = duration
        updateTimerVisuals()

        selectionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.remainingTime -= 1
            self.updateTimerVisuals()
            self.delegate?.timerDidTick(remaining: self.remainingTime)
            if self.remainingTime <= 0 {
                self.invalidate()
                self.delegate?.timerDidExpire()
            }
        }
    }

    func invalidate() {
        selectionTimer?.invalidate()
        selectionTimer = nil
    }

    func resetVisuals() {
        timerOverlay?.removeAllActions()
        timerOverlay?.alpha = 1
        timerOverlay?.fillColor = .clear
        timerOverlay?.lineWidth = 0
    }

    func showZenMode() {
        timerLabel?.text = "∞"
        if let shadow = timerLabel?.childNode(withName: "timerShadow") as? SKLabelNode {
            shadow.text = "∞"
        }
    }

    func hideTimer() {
        timerLabel?.run(SKAction.fadeOut(withDuration: 0.3))
        timerOverlay?.run(SKAction.fadeOut(withDuration: 0.3))
    }

    func updateTimerVisuals() {
        guard let timerLabel = timerLabel, let timerOverlay = timerOverlay else { return }

        let progress = maxTime > 0 ? CGFloat(remainingTime) / CGFloat(maxTime) : 1.0

        timerLabel.text = "\(remainingTime)"
        if let shadow = timerLabel.childNode(withName: "timerShadow") as? SKLabelNode {
            shadow.text = "\(remainingTime)"
        }

        timerLabel.run(SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))

        timerOverlay.fillColor = SKColor.systemYellow.withAlphaComponent((1.0 - progress) * 0.35)
        timerOverlay.lineWidth = (1.0 - progress) * 40

        if remainingTime <= 3 {
            timerLabel.fontColor = .systemRed
            timerOverlay.strokeColor = .systemRed
            timerLabel.run(SKAction.sequence([
                SKAction.scale(to: 1.5, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]))
            timerOverlay.run(SKAction.repeat(SKAction.sequence([
                SKAction.moveBy(x: 5, y: 0, duration: 0.05),
                SKAction.moveBy(x: -5, y: 0, duration: 0.05)
            ]), count: 2))
        } else {
            timerLabel.fontColor = .white
            timerOverlay.strokeColor = .systemYellow
        }
    }

    // Get timer duration for a given level and boss state
    static func timerDuration(for level: Int, isBoss: Bool, hasSlowMo: Bool) -> Int {
        let base = isBoss ? 10 : (7 * level)
        return hasSlowMo ? base * 2 : base
    }
}
