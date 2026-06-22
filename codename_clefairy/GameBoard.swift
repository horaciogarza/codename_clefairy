import SpriteKit

struct LevelConfig {
    let poolSize: Int
    let sequenceLength: Int
    let movementType: MovementType
    let specialEffect: SpecialEffect
}

enum MovementType {
    case none, slow, moderate, fast, wander
}

enum SpecialEffect {
    case none, ghost, spin, pulse
}

class GameBoard {
    weak var scene: SKScene?
    var buttonNodes: [SKNode] = []

    init(scene: SKScene) {
        self.scene = scene
    }

    // MARK: - Level Config

    static func getLevelConfig(for level: Int) -> LevelConfig {
        switch level {
        case 1...2:
            return LevelConfig(poolSize: 8, sequenceLength: level, movementType: .none, specialEffect: .none)
        case 3...4:
            return LevelConfig(poolSize: 10, sequenceLength: level, movementType: .none, specialEffect: .none)
        case 5:
            return LevelConfig(poolSize: 10, sequenceLength: 3, movementType: .none, specialEffect: .none)
        case 6...8:
            return LevelConfig(poolSize: 15, sequenceLength: 5, movementType: .slow, specialEffect: .none)
        case 9:
            return LevelConfig(poolSize: 15, sequenceLength: 6, movementType: .moderate, specialEffect: .ghost)
        case 10:
            return LevelConfig(poolSize: 15, sequenceLength: 6, movementType: .fast, specialEffect: .spin)
        case 11...15:
            return LevelConfig(poolSize: 20, sequenceLength: 7, movementType: .wander, specialEffect: .pulse)
        default:
            let baseSeq = 7 + (level - 11) / 2
            let effect: SpecialEffect = [.ghost, .spin, .pulse].randomElement() ?? .none
            let movement: MovementType = [.moderate, .fast, .wander].randomElement() ?? .fast
            let size = (level % 2 == 0) ? 15 : 20
            return LevelConfig(poolSize: size, sequenceLength: baseSeq, movementType: movement, specialEffect: effect)
        }
    }

    static func sequenceCount(for level: Int, isBoss: Bool) -> Int {
        if isBoss { return 4 }
        return getLevelConfig(for: level).sequenceLength
    }

    // MARK: - Input Button Setup

    func setupInputButtons(activeEmojiPool: [String], level: Int, isBoss: Bool) {
        guard let scene = scene else { return }

        let config = GameBoard.getLevelConfig(for: level)
        let count = activeEmojiPool.count
        let cols = 5
        let rows = Int(ceil(Double(count) / Double(cols)))
        var btnSize: CGFloat = scene.frame.width * 0.14
        if count > 15 { btnSize = scene.frame.width * 0.12 }
        let spacing: CGFloat = 12
        let totalWidth = CGFloat(cols) * (btnSize + spacing) - spacing
        let totalHeight = CGFloat(rows) * (btnSize + spacing) - spacing
        let shiftY = scene.size.height * 0.05
        let centerY = scene.frame.height * 0.32 - shiftY
        let startX = scene.frame.midX - totalWidth / 2 + btnSize / 2
        let startY = centerY + totalHeight / 2 - btnSize / 2

        let theme = ThemeManager.shared.currentTheme

        for i in 0..<activeEmojiPool.count {
            let container = SKNode()
            let col = i % cols
            let row = i / cols
            container.position = CGPoint(
                x: startX + CGFloat(col) * (btnSize + spacing),
                y: startY - CGFloat(row) * (btnSize + spacing)
            )
            container.name = activeEmojiPool[i]

            if level >= 16 {
                let physBody = SKPhysicsBody(circleOfRadius: btnSize / 2)
                physBody.affectedByGravity = false
                physBody.linearDamping = 0.5
                physBody.restitution = 0.8
                container.physicsBody = physBody
                container.physicsBody?.applyImpulse(CGVector(dx: CGFloat.random(in: -5...5), dy: CGFloat.random(in: -5...5)))
            }

            let shadow = SKShapeNode(circleOfRadius: btnSize / 2)
            shadow.fillColor = .black.withAlphaComponent(0.3)
            shadow.strokeColor = .clear
            shadow.position = CGPoint(x: 0, y: -6)
            container.addChild(shadow)

            let body = SKShapeNode(circleOfRadius: btnSize / 2)
            body.fillColor = theme.boardColor
            body.strokeColor = theme.buttonStrokeColor
            body.lineWidth = 4
            body.name = "btn_body"
            container.addChild(body)

            let label = SKLabelNode(text: activeEmojiPool[i])
            label.fontSize = btnSize * 0.6
            label.fontColor = .black
            label.verticalAlignmentMode = .center
            label.zPosition = 1
            label.name = activeEmojiPool[i]
            container.addChild(label)

            scene.addChild(container)
            buttonNodes.append(container)

            container.setScale(0)
            container.run(SKAction.scale(to: 1.0, duration: 0.3))

            if !isBoss && level < 16 {
                applySpecialEffect(config.specialEffect, to: container, label: label)
                applyMovement(config.movementType, to: container)
            }
        }
    }

    func clearButtons() {
        buttonNodes.forEach { $0.removeFromParent() }
        buttonNodes.removeAll()
    }

    // MARK: - Effects

    private func applySpecialEffect(_ effect: SpecialEffect, to container: SKNode, label: SKLabelNode) {
        switch effect {
        case .ghost:
            container.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.2, duration: 1.0),
                SKAction.fadeAlpha(to: 1.0, duration: 1.0)
            ])))
        case .spin:
            container.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 4.0)))
            label.run(SKAction.repeatForever(SKAction.rotate(byAngle: -.pi * 2, duration: 4.0)))
        case .pulse:
            container.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.scale(to: 1.1, duration: 0.6),
                SKAction.scale(to: 0.9, duration: 0.6)
            ])))
        case .none:
            break
        }
    }

    private func applyMovement(_ movement: MovementType, to container: SKNode) {
        switch movement {
        case .slow, .moderate, .fast:
            let speed = (movement == .slow) ? 2.5 : ((movement == .moderate) ? 1.5 : 0.8)
            let d = CGFloat.random(in: 10...25)
            container.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.moveBy(x: d, y: 0, duration: speed),
                SKAction.moveBy(x: -d * 2, y: 0, duration: speed * 2),
                SKAction.moveBy(x: d, y: 0, duration: speed)
            ])))
        case .wander:
            let p = CGMutablePath()
            p.move(to: .zero)
            for _ in 0..<4 {
                p.addLine(to: CGPoint(x: CGFloat.random(in: -30...30), y: CGFloat.random(in: -30...30)))
            }
            p.closeSubpath()
            container.run(SKAction.repeatForever(SKAction.follow(p, asOffset: true, orientToPath: false, speed: 40)))
        case .none:
            break
        }
    }
}
