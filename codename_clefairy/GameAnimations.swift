import SpriteKit

class GameAnimations {
    weak var scene: SKScene?

    init(scene: SKScene) {
        self.scene = scene
    }

    // MARK: - Countdown

    func runCountdown(from count: Int, countdownLabel: SKLabelNode, textOverride: String? = nil, playSound: @escaping (String) -> Void, completion: @escaping () -> Void) {
        var remaining = count
        countdownLabel.alpha = 1

        let update = SKAction.run { [weak self] in
            guard self != nil else { return }
            if remaining > 0 {
                countdownLabel.text = "\(remaining)"
                countdownLabel.fontColor = (remaining == 1) ? .systemRed : .systemYellow
                playSound("tick.mp3")
                countdownLabel.setScale(0)
                countdownLabel.zRotation = -0.5

                let appear = SKAction.group([
                    SKAction.scale(to: 1.2, duration: 0.2),
                    SKAction.rotate(byAngle: 0.6, duration: 0.2),
                    SKAction.fadeIn(withDuration: 0.1)
                ])
                countdownLabel.run(SKAction.sequence([
                    appear,
                    SKAction.scale(to: 1.0, duration: 0.1),
                    SKAction.rotate(toAngle: 0, duration: 0.1)
                ]))
                remaining -= 1
            } else {
                countdownLabel.text = textOverride ?? "GO!"
                countdownLabel.fontColor = .systemGreen
                playSound("go.mp3")
                countdownLabel.setScale(1.5)
                countdownLabel.run(SKAction.group([
                    SKAction.scale(to: 1.0, duration: 0.3),
                    SKAction.fadeOut(withDuration: 0.5)
                ]))
            }
        }

        let sequence = SKAction.sequence([update, SKAction.wait(forDuration: 1.0)])
        countdownLabel.run(SKAction.repeat(sequence, count: count + 1)) {
            completion()
        }
    }

    // MARK: - Sequence Display

    func showSequence(_ currentSequence: [String], centerDisplayLabel: SKLabelNode, stageNode: SKShapeNode, playSound: @escaping (String) -> Void, completion: @escaping () -> Void) {
        guard let scene = scene else { return }

        var delay = 0.5
        for emoji in currentSequence {
            let wait = SKAction.wait(forDuration: delay)
            let show = SKAction.run {
                centerDisplayLabel.text = emoji
                centerDisplayLabel.alpha = 1
                centerDisplayLabel.setScale(0.5)
                centerDisplayLabel.run(SKAction.scale(to: 1.0, duration: 0.2))
                stageNode.run(SKAction.sequence([
                    SKAction.scale(to: 1.05, duration: 0.1),
                    SKAction.scale(to: 1.0, duration: 0.1)
                ]))
                playSound("pop.mp3")
            }
            let hideWait = SKAction.wait(forDuration: 0.8)
            let fade = SKAction.run { centerDisplayLabel.alpha = 0 }
            scene.run(SKAction.sequence([wait, show, hideWait, fade]))
            delay += 1.2
        }

        scene.run(SKAction.wait(forDuration: delay)) {
            completion()
        }
    }

    // MARK: - Level Up

    func showLevelUp(at position: CGPoint, completion: @escaping () -> Void) {
        guard let scene = scene else { return }

        let burstOrigin = CGPoint(x: scene.frame.midX, y: scene.frame.midY + 100)
        let palette: [SKColor] = [.systemRed, .systemYellow, .systemGreen, .systemBlue, .systemPurple, .systemPink, .systemOrange, .systemTeal]

        // Radial confetti burst — pixel squares spinning outward.
        for _ in 0..<60 {
            let confSize = CGFloat([8, 10, 12, 14].randomElement()!)
            let conf = SKShapeNode(rectOf: CGSize(width: confSize, height: confSize))
            conf.fillColor = palette.randomElement()!
            conf.strokeColor = .clear
            conf.position = burstOrigin
            conf.zPosition = 145
            conf.zRotation = CGFloat.random(in: 0...(.pi))
            scene.addChild(conf)

            let angle = CGFloat.random(in: 0...(.pi * 2))
            let dist = CGFloat.random(in: 120...360)
            let dur = Double.random(in: 0.7...1.1)
            let dest = CGPoint(x: burstOrigin.x + cos(angle) * dist, y: burstOrigin.y + sin(angle) * dist)
            conf.run(SKAction.sequence([
                SKAction.group([
                    SKAction.move(to: dest, duration: dur),
                    SKAction.rotate(byAngle: .pi * CGFloat.random(in: 3...6), duration: dur),
                    SKAction.sequence([SKAction.wait(forDuration: dur * 0.6), SKAction.fadeOut(withDuration: dur * 0.4)])
                ]),
                SKAction.removeFromParent()
            ]))
        }

        // Confetti rain — falls from the top of the screen with a little sway.
        for _ in 0..<40 {
            let confSize = CGFloat([6, 8, 10].randomElement()!)
            let conf = SKShapeNode(rectOf: CGSize(width: confSize, height: confSize))
            conf.fillColor = palette.randomElement()!
            conf.strokeColor = .clear
            conf.position = CGPoint(x: CGFloat.random(in: 0...scene.frame.width), y: scene.frame.maxY + 20)
            conf.zPosition = 145
            scene.addChild(conf)

            let fallDur = Double.random(in: 1.0...1.8)
            let sway = CGFloat.random(in: -40...40)
            conf.run(SKAction.sequence([
                SKAction.wait(forDuration: Double.random(in: 0...0.4)),
                SKAction.group([
                    SKAction.moveBy(x: sway, y: -(scene.frame.height + 60), duration: fallDur),
                    SKAction.rotate(byAngle: .pi * CGFloat.random(in: 2...5), duration: fallDur),
                    SKAction.sequence([SKAction.wait(forDuration: fallDur * 0.7), SKAction.fadeOut(withDuration: fallDur * 0.3)])
                ]),
                SKAction.removeFromParent()
            ]))
        }

        // Twinkling star sparkles around the banner.
        for _ in 0..<18 {
            let star = SKLabelNode(text: "✨")
            star.fontSize = CGFloat.random(in: 18...34)
            star.position = CGPoint(
                x: burstOrigin.x + CGFloat.random(in: -180...180),
                y: burstOrigin.y + CGFloat.random(in: -120...120)
            )
            star.zPosition = 146
            star.setScale(0)
            scene.addChild(star)
            star.run(SKAction.sequence([
                SKAction.wait(forDuration: Double.random(in: 0...0.5)),
                SKAction.scale(to: 1.0, duration: 0.2),
                SKAction.wait(forDuration: 0.3),
                SKAction.group([
                    SKAction.scale(to: 0, duration: 0.3),
                    SKAction.fadeOut(withDuration: 0.3)
                ]),
                SKAction.removeFromParent()
            ]))
        }

        let congrats = SKLabelNode(fontNamed: "Gameplay")
        congrats.text = "LEVEL UP!"
        congrats.fontSize = 70
        congrats.fontColor = .systemYellow
        congrats.verticalAlignmentMode = .center

        let shadow = SKLabelNode(fontNamed: "Gameplay")
        shadow.text = "LEVEL UP!"
        shadow.fontSize = 70
        shadow.fontColor = .black
        shadow.zPosition = -1
        shadow.position = CGPoint(x: 4, y: -4)
        shadow.verticalAlignmentMode = .center
        congrats.addChild(shadow)

        congrats.position = position
        congrats.zPosition = 150
        scene.addChild(congrats)
        congrats.setScale(0)

        congrats.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.2, duration: 0.2),
                SKAction.fadeIn(withDuration: 0.2)
            ]),
            SKAction.scale(to: 1.0, duration: 0.1),
            SKAction.wait(forDuration: 1.2),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ])) {
            completion()
        }
    }

    // MARK: - Score Popup

    func showScorePopup(score: Int, position: CGPoint, isBonus: Bool = false) {
        guard let scene = scene else { return }

        let label = SKLabelNode(fontNamed: "Gameplay")
        label.text = "+\(score)"
        label.fontSize = isBonus ? 32 : 24
        label.fontColor = isBonus ? .systemYellow : .white
        label.position = position
        label.zPosition = 100
        scene.addChild(label)

        let moveUp = SKAction.moveBy(x: 0, y: 50, duration: 0.8)
        let fadeOut = SKAction.fadeOut(withDuration: 0.8)
        let scaleUp = SKAction.scale(to: 1.5, duration: 0.2)

        label.run(SKAction.sequence([
            SKAction.group([moveUp, fadeOut, scaleUp]),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Door Opening Transition

    func performCustomDoorOpening(with texture: SKTexture, completion: @escaping () -> Void) {
        guard let scene = scene else { return }

        let leftRect = CGRect(x: 0, y: 0, width: 0.5, height: 1.0)
        let rightRect = CGRect(x: 0.5, y: 0, width: 0.5, height: 1.0)

        let leftDoor = SKSpriteNode(texture: SKTexture(rect: leftRect, in: texture))
        leftDoor.size = CGSize(width: scene.frame.width / 2, height: scene.frame.height)
        leftDoor.anchorPoint = CGPoint(x: 1, y: 0.5)
        leftDoor.position = CGPoint(x: scene.frame.midX, y: scene.frame.midY)
        leftDoor.zPosition = 1000
        scene.addChild(leftDoor)

        let rightDoor = SKSpriteNode(texture: SKTexture(rect: rightRect, in: texture))
        rightDoor.size = CGSize(width: scene.frame.width / 2, height: scene.frame.height)
        rightDoor.anchorPoint = CGPoint(x: 0, y: 0.5)
        rightDoor.position = CGPoint(x: scene.frame.midX, y: scene.frame.midY)
        rightDoor.zPosition = 1000
        scene.addChild(rightDoor)

        let dist = scene.frame.width / 2
        let p1D = dist * 0.3; let p1T = 0.3
        let p2D = dist * 0.1; let p2T = 1.0
        let p3D = dist * 0.6; let p3T = 0.2

        let leftSeq = SKAction.sequence([
            SKAction.moveBy(x: -p1D, y: 0, duration: p1T),
            SKAction.moveBy(x: -p2D, y: 0, duration: p2T),
            SKAction.moveBy(x: -p3D, y: 0, duration: p3T),
            SKAction.removeFromParent()
        ])
        let rightSeq = SKAction.sequence([
            SKAction.moveBy(x: p1D, y: 0, duration: p1T),
            SKAction.moveBy(x: p2D, y: 0, duration: p2T),
            SKAction.moveBy(x: p3D, y: 0, duration: p3T),
            SKAction.removeFromParent()
        ])

        leftDoor.run(leftSeq)
        rightDoor.run(rightSeq) {
            completion()
        }
    }

    // MARK: - Boss Entrance

    func showBossEntrance(boss: BossDef, stageNode: SKShapeNode, playSound: @escaping (String) -> Void, completion: @escaping (SKLabelNode) -> Void) {
        guard let scene = scene else { return }

        // Dramatic screen flash
        let flashOverlayBoss = SKShapeNode(rectOf: scene.size)
        flashOverlayBoss.position = CGPoint(x: scene.frame.midX, y: scene.frame.midY)
        flashOverlayBoss.fillColor = boss.accentColor
        flashOverlayBoss.strokeColor = .clear
        flashOverlayBoss.alpha = 0
        flashOverlayBoss.zPosition = 200
        scene.addChild(flashOverlayBoss)

        flashOverlayBoss.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.4, duration: 0.1),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))

        // Warning text
        let warningLabel = SKLabelNode(fontNamed: "Gameplay")
        warningLabel.text = "⚠️ \(boss.name) ⚠️"
        warningLabel.fontSize = 24
        warningLabel.fontColor = boss.accentColor
        warningLabel.position = CGPoint(x: scene.frame.midX, y: scene.frame.midY + 200)
        warningLabel.zPosition = 150
        warningLabel.alpha = 0
        scene.addChild(warningLabel)

        let warningAnim = SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.2),
            SKAction.repeat(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.3, duration: 0.15),
                SKAction.fadeAlpha(to: 1.0, duration: 0.15)
            ]), count: 4),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ])
        warningLabel.run(warningAnim)

        // Boss entrance after warning
        scene.run(SKAction.wait(forDuration: 1.5)) { [weak scene] in
            guard let scene = scene else { return }

            let bossNode = SKLabelNode(text: boss.emoji)
            bossNode.fontSize = 142.5
            bossNode.position = CGPoint(x: scene.frame.midX, y: scene.frame.maxY + 150)
            bossNode.zPosition = 10
            bossNode.name = "boss"
            bossNode.setScale(0.3)
            scene.addChild(bossNode)

            let targetY = scene.frame.maxY - 200
            let dropDown = SKAction.move(to: CGPoint(x: scene.frame.midX, y: targetY), duration: 0.5)
            dropDown.timingMode = .easeIn
            let scaleUp = SKAction.scale(to: 1.0, duration: 0.5)

            let impact = SKAction.run {
                let shake = SKAction.sequence([
                    SKAction.moveBy(x: 10, y: 0, duration: 0.05),
                    SKAction.moveBy(x: -20, y: 0, duration: 0.05),
                    SKAction.moveBy(x: 15, y: -5, duration: 0.05),
                    SKAction.moveBy(x: -10, y: 5, duration: 0.05),
                    SKAction.moveBy(x: 5, y: 0, duration: 0.05)
                ])
                stageNode.run(shake)
                playSound("boss_appear.mp3")

                for _ in 0..<12 {
                    let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 5...12))
                    particle.fillColor = [boss.accentColor, boss.hillColor, SKColor.white].randomElement()!
                    particle.strokeColor = .clear
                    particle.position = CGPoint(x: scene.frame.midX, y: targetY - 50)
                    particle.zPosition = 9
                    scene.addChild(particle)

                    let angle = CGFloat.random(in: 0...(.pi))
                    let dist = CGFloat.random(in: 80...150)
                    let dest = CGPoint(x: particle.position.x + cos(angle) * dist, y: particle.position.y + sin(angle) * dist)
                    particle.run(SKAction.sequence([
                        SKAction.group([
                            SKAction.move(to: dest, duration: 0.4),
                            SKAction.fadeOut(withDuration: 0.4)
                        ]),
                        SKAction.removeFromParent()
                    ]))
                }
            }

            bossNode.run(SKAction.sequence([
                SKAction.group([dropDown, scaleUp]),
                impact
            ])) {
                let wobble = SKAction.sequence([
                    SKAction.scaleX(to: 1.1, y: 0.9, duration: 0.5),
                    SKAction.scaleX(to: 0.9, y: 1.1, duration: 0.5)
                ])
                bossNode.run(SKAction.repeatForever(wobble))
                completion(bossNode)
            }
        }
    }

    // MARK: - Loss / Error Animation

    func showLoseLife(reason: String, at position: CGPoint, completion: @escaping () -> Void) {
        guard let scene = scene else { return }

        let oops = SKLabelNode(fontNamed: "Gameplay")
        oops.text = reason
        oops.fontColor = .systemRed
        oops.verticalAlignmentMode = .center

        let shadow = SKLabelNode(fontNamed: "Gameplay")
        shadow.text = reason
        shadow.fontSize = 60
        shadow.fontColor = .black
        shadow.zPosition = -1
        shadow.position = CGPoint(x: 4, y: -4)
        shadow.verticalAlignmentMode = .center
        oops.addChild(shadow)

        oops.fontSize = 60
        oops.position = position
        oops.zPosition = 150
        scene.addChild(oops)
        oops.setScale(0)

        oops.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.0, duration: 0.3),
                SKAction.fadeIn(withDuration: 0.3)
            ]),
            SKAction.wait(forDuration: 0.8),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ])) {
            completion()
        }
    }
}
