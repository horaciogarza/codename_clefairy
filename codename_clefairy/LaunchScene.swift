import SpriteKit

class LaunchScene: SKScene {

    private var canSkip = false
    private var isTransitioning = false
    private var skipLabel: SKLabelNode?
    private var bgRenderer: BackgroundRenderer?

    override func didMove(to view: SKView) {
        let theme = ThemeManager.shared.currentTheme
        backgroundColor = theme.skyColor

        bgRenderer = BackgroundRenderer(scene: self)
        setupHills(theme: theme)
        setupDecorations(theme: theme)
        setupSkipHint()
        setupAnimation(theme: theme)
    }

    // MARK: - Background

    private func setupHills(theme: GameTheme) {
        // Back hill
        let hill1 = SKShapeNode()
        let path1 = UIBezierPath()
        path1.move(to: CGPoint(x: 0, y: 0))
        path1.addLine(to: CGPoint(x: 0, y: frame.height * 0.25))
        path1.addQuadCurve(
            to: CGPoint(x: frame.width, y: frame.height * 0.18),
            controlPoint: CGPoint(x: frame.width * 0.5, y: frame.height * 0.38)
        )
        path1.addLine(to: CGPoint(x: frame.width, y: 0))
        path1.close()
        hill1.path = path1.cgPath
        hill1.fillColor = theme.hillColor
        hill1.strokeColor = .clear
        hill1.zPosition = -4
        addChild(hill1)

        // Front hill
        let hill2 = SKShapeNode()
        let path2 = UIBezierPath()
        path2.move(to: CGPoint(x: 0, y: 0))
        path2.addLine(to: CGPoint(x: 0, y: frame.height * 0.12))
        path2.addQuadCurve(
            to: CGPoint(x: frame.width, y: frame.height * 0.2),
            controlPoint: CGPoint(x: frame.width * 0.4, y: frame.height * 0.02)
        )
        path2.addLine(to: CGPoint(x: frame.width, y: 0))
        path2.close()
        hill2.path = path2.cgPath
        hill2.fillColor = theme.hillColorDark
        hill2.strokeColor = .clear
        hill2.zPosition = -3
        addChild(hill2)

        // Clouds
        for _ in 0..<4 {
            bgRenderer?.spawnCloud(isFrenzyMode: false)
        }
    }

    private func setupDecorations(theme: GameTheme) {
        // Floating memory-themed particles
        let particleEmojis = ["✨", "💭", "🧩", "🔮"]
        for _ in 0..<12 {
            let particle = SKLabelNode(text: particleEmojis.randomElement()!)
            particle.fontSize = CGFloat.random(in: 14...28)
            particle.alpha = CGFloat.random(in: 0.15...0.35)
            particle.position = CGPoint(
                x: CGFloat.random(in: 0...frame.width),
                y: CGFloat.random(in: frame.height * 0.25...frame.height)
            )
            particle.zPosition = -2
            addChild(particle)

            let driftY = CGFloat.random(in: 30...60)
            let driftX = CGFloat.random(in: -15...15)
            let duration = Double.random(in: 3...6)
            let drift = SKAction.sequence([
                SKAction.moveBy(x: driftX, y: driftY, duration: duration),
                SKAction.moveBy(x: -driftX, y: -driftY, duration: duration)
            ])
            let fade = SKAction.sequence([
                SKAction.fadeAlpha(to: particle.alpha * 0.5, duration: duration),
                SKAction.fadeAlpha(to: particle.alpha, duration: duration)
            ])
            particle.run(SKAction.repeatForever(SKAction.group([drift, fade])))
        }
    }

    // MARK: - Skip Hint

    private func setupSkipHint() {
        let safeBottom = view?.safeAreaInsets.bottom ?? 0

        skipLabel = SKLabelNode(fontNamed: "Gameplay")
        skipLabel?.text = "TAP TO SKIP"
        skipLabel?.fontSize = 14
        skipLabel?.fontColor = .white.withAlphaComponent(0.5)
        skipLabel?.position = CGPoint(x: frame.midX, y: safeBottom + 60)
        skipLabel?.alpha = 0
        skipLabel?.zPosition = 10
        addChild(skipLabel!)

        run(SKAction.wait(forDuration: 1.0)) { [weak self] in
            self?.canSkip = true
            self?.skipLabel?.run(SKAction.fadeIn(withDuration: 0.4))
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard canSkip, !isTransitioning else { return }
        isTransitioning = true
        removeAllActions()
        children.forEach { $0.removeAllActions() }
        transitionToMenu()
    }

    // MARK: - Intro Animation

    private func setupAnimation(theme: GameTheme) {
        let center = CGPoint(x: frame.midX, y: frame.midY + frame.height * 0.05)

        // Phase 1: Sequence of game-themed emojis popping in and out
        let emojis = ["👁️", "🎯", "⚡️", "🧠"]
        var delay = 0.0

        for (index, emoji) in emojis.enumerated() {
            let label = SKLabelNode(text: emoji)
            label.fontSize = frame.width * 0.2
            label.position = center
            label.alpha = 0
            label.setScale(0)
            label.zPosition = 5
            addChild(label)

            let wait = SKAction.wait(forDuration: delay)

            // Staggered directional entrance
            let angles: [CGFloat] = [-.pi/6, .pi/6, -.pi/4, 0]
            let startAngle = angles[index % angles.count]

            let popIn = SKAction.group([
                SKAction.fadeIn(withDuration: 0.25),
                SKAction.scale(to: 1.3, duration: 0.25),
                SKAction.rotate(byAngle: startAngle, duration: 0.25)
            ])
            popIn.timingMode = .easeOut

            let settle = SKAction.group([
                SKAction.scale(to: 1.0, duration: 0.15),
                SKAction.rotate(toAngle: 0, duration: 0.15)
            ])
            settle.timingMode = .easeInEaseOut

            let hold = SKAction.wait(forDuration: 0.2)

            let popOut = SKAction.group([
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.scale(to: 0.3, duration: 0.2)
            ])
            popOut.timingMode = .easeIn

            label.run(SKAction.sequence([
                wait, popIn, settle, hold, popOut, SKAction.removeFromParent()
            ]))

            delay += 0.45
        }

        // Phase 2: Brain drop-in
        run(SKAction.wait(forDuration: delay + 0.2)) { [weak self] in
            self?.showBrain(at: center, theme: theme)
        }
    }

    // MARK: - Brain Entrance

    private func showBrain(at position: CGPoint, theme: GameTheme) {
        // Shadow
        let brainShadow = SKLabelNode(text: "🧠")
        brainShadow.fontSize = frame.width * 0.28
        brainShadow.alpha = 0
        brainShadow.position = CGPoint(x: position.x + 6, y: frame.maxY + 100)
        brainShadow.zPosition = 4
        addChild(brainShadow)

        // Brain
        let brain = SKLabelNode(text: "🧠")
        brain.fontSize = frame.width * 0.28
        brain.position = CGPoint(x: position.x, y: frame.maxY + 108)
        brain.zPosition = 5
        addChild(brain)

        // Shadow fades in as brain approaches
        brainShadow.run(SKAction.fadeAlpha(to: 0.2, duration: 0.3))

        let targetPos = CGPoint(x: position.x, y: position.y + frame.height * 0.05)

        let moveIn = SKAction.move(to: targetPos, duration: 0.8)
        moveIn.timingMode = .easeIn

        // Squash on landing
        let squash = SKAction.sequence([
            SKAction.scaleX(to: 1.2, y: 0.85, duration: 0.08),
            SKAction.scaleX(to: 0.9, y: 1.1, duration: 0.08),
            SKAction.scaleX(to: 1.0, y: 1.0, duration: 0.1)
        ])

        // Impact ring
        let impactRing = SKAction.run { [weak self] in
            guard let self = self else { return }
            let ring = SKShapeNode(circleOfRadius: 10)
            ring.strokeColor = theme.accentColor.withAlphaComponent(0.6)
            ring.fillColor = .clear
            ring.lineWidth = 3
            ring.position = CGPoint(x: targetPos.x, y: targetPos.y - 30)
            ring.zPosition = 3
            self.addChild(ring)

            ring.run(SKAction.group([
                SKAction.scale(to: 8, duration: 0.5),
                SKAction.fadeOut(withDuration: 0.5)
            ])) {
                ring.removeFromParent()
            }

            self.playSound("pop.mp3")
        }

        let shadowTarget = CGPoint(x: position.x + 6, y: targetPos.y - 6)
        brainShadow.run(SKAction.move(to: shadowTarget, duration: 0.8))

        brain.run(SKAction.sequence([moveIn, squash, impactRing])) { [weak self] in
            // Gentle idle pulse
            let pulse = SKAction.repeatForever(SKAction.sequence([
                SKAction.scale(to: 1.06, duration: 0.6),
                SKAction.scale(to: 0.94, duration: 0.6)
            ]))
            brain.run(pulse)
            self?.showTitle(below: targetPos, theme: theme)
        }
    }

    // MARK: - Title Reveal

    private func showTitle(below brainPos: CGPoint, theme: GameTheme) {
        let titleContainer = SKNode()
        titleContainer.position = CGPoint(x: brainPos.x, y: brainPos.y - frame.height * 0.18)
        titleContainer.alpha = 0
        titleContainer.setScale(0.5)
        titleContainer.zPosition = 5
        addChild(titleContainer)

        let titleText = "MEMORANDUM"
        let colors: [SKColor] = [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .magenta, .red, .orange]
        let charSize: CGFloat = frame.width * 0.085
        let spacing: CGFloat = charSize * 0.78
        var xOffset: CGFloat = -(CGFloat(titleText.count - 1) * spacing) / 2

        for (i, char) in titleText.enumerated() {
            // Shadow
            let charShadow = SKLabelNode(fontNamed: "Gameplay")
            charShadow.text = String(char)
            charShadow.fontSize = charSize
            charShadow.fontColor = .black.withAlphaComponent(0.35)
            charShadow.position = CGPoint(x: xOffset + 3, y: -3)
            charShadow.zPosition = -1
            titleContainer.addChild(charShadow)

            // Letter
            let charNode = SKLabelNode(fontNamed: "Gameplay")
            charNode.text = String(char)
            charNode.fontSize = charSize
            charNode.fontColor = colors[i % colors.count]
            charNode.position = CGPoint(x: xOffset, y: 0)
            charNode.alpha = 0
            titleContainer.addChild(charNode)

            // Staggered letter reveal
            let letterDelay = Double(i) * 0.05
            charNode.run(SKAction.sequence([
                SKAction.wait(forDuration: letterDelay),
                SKAction.fadeIn(withDuration: 0.15)
            ]))
            charShadow.run(SKAction.sequence([
                SKAction.wait(forDuration: letterDelay),
                SKAction.fadeAlpha(to: 0.35, duration: 0.15)
            ]))

            xOffset += spacing
        }

        // Container scales up
        let appear = SKAction.group([
            SKAction.fadeIn(withDuration: 0.4),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        appear.timingMode = .easeOut

        titleContainer.run(appear) { [weak self] in
            // Subtle title bounce
            let bounce = SKAction.repeatForever(SKAction.sequence([
                SKAction.moveBy(x: 0, y: 4, duration: 0.8),
                SKAction.moveBy(x: 0, y: -4, duration: 0.8)
            ]))
            titleContainer.run(bounce)

            self?.showSubtitle(below: titleContainer.position)
        }
    }

    // MARK: - Subtitle + Auto-transition

    private func showSubtitle(below titlePos: CGPoint) {
        let streak = StatsManager.shared.currentDailyStreak

        if streak > 0 {
            let streakLabel = SKLabelNode(fontNamed: "Gameplay")
            streakLabel.text = "🔥 \(streak)-DAY STREAK"
            streakLabel.fontSize = 16
            streakLabel.fontColor = .systemOrange
            streakLabel.position = CGPoint(x: titlePos.x, y: titlePos.y - 40)
            streakLabel.alpha = 0
            streakLabel.zPosition = 5
            addChild(streakLabel)

            streakLabel.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.3),
                SKAction.fadeIn(withDuration: 0.4)
            ]))
        }

        // Auto-transition after a beat
        run(SKAction.wait(forDuration: 2.0)) { [weak self] in
            self?.transitionToMenu()
        }
    }

    // MARK: - Transition

    func transitionToMenu() {
        let menuScene = MenuScene(size: self.size)
        menuScene.scaleMode = .aspectFill
        let transition = SKTransition.fade(with: .white, duration: 0.8)
        self.view?.presentScene(menuScene, transition: transition)
    }

    // MARK: - Sound

    private func playSound(_ fileName: String) {
        guard GameManager.shared.soundEnabled else { return }
        run(SKAction.playSoundFileNamed(fileName, waitForCompletion: false))
    }
}
