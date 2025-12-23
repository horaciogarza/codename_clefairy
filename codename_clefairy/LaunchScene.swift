import SpriteKit

class LaunchScene: SKScene {

    private var canSkip = false
    private var skipLabel: SKLabelNode?

    override func didMove(to view: SKView) {
        // Soft pastel gradient-like background
        backgroundColor = SKColor(red: 1.00, green: 0.49, blue: 0.73, alpha: 1.0) // Vibrant Pink
        setupDecorations()
        setupSkipHint()
        setupAnimation()
    }

    private func setupSkipHint() {
        let safeBottom = view?.safeAreaInsets.bottom ?? 0

        skipLabel = SKLabelNode(fontNamed: "Gameplay")
        skipLabel?.text = "TAP TO SKIP"
        skipLabel?.fontSize = 16
        skipLabel?.fontColor = .white.withAlphaComponent(0.6)
        skipLabel?.position = CGPoint(x: frame.midX, y: safeBottom + 80)
        skipLabel?.alpha = 0
        addChild(skipLabel!)

        // Show skip hint after a brief delay
        run(SKAction.wait(forDuration: 1.0)) { [weak self] in
            self?.canSkip = true
            self?.skipLabel?.run(SKAction.fadeIn(withDuration: 0.3))
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if canSkip {
            removeAllActions()
            children.forEach { $0.removeAllActions() }
            transitionToMenu()
        }
    }
    
    private func setupDecorations() {
        // Add some floating bubbles in the background
        for _ in 0..<15 {
            let bubble = SKShapeNode(circleOfRadius: CGFloat.random(in: 10...30))
            bubble.fillColor = .white.withAlphaComponent(0.2)
            bubble.strokeColor = .clear
            bubble.position = CGPoint(
                x: CGFloat.random(in: 0...frame.width),
                y: CGFloat.random(in: 0...frame.height)
            )
            addChild(bubble)
            
            let move = SKAction.moveBy(x: 0, y: 50, duration: Double.random(in: 3...6))
            bubble.run(SKAction.repeatForever(SKAction.sequence([move, move.reversed()])))
        }
    }
    
    func setupAnimation() {
        let center = CGPoint(x: frame.midX, y: frame.midY)
        let emojis = ["✨", "🎮", "⭐️", "🎈"]
        var delay = 0.0
        
        for emoji in emojis {
            let label = SKLabelNode(text: emoji)
            label.fontSize = frame.width * 0.18
            label.position = center
            label.alpha = 0
            label.setScale(0)
            addChild(label)
            
            let wait = SKAction.wait(forDuration: delay)
            let popIn = SKAction.group([
                SKAction.fadeIn(withDuration: 0.3),
                SKAction.scale(to: 1.4, duration: 0.3),
                SKAction.rotate(byAngle: CGFloat(0.2), duration: 0.3)
            ])
            popIn.timingMode = .easeOut
            
            let bounce = SKAction.sequence([
                SKAction.scale(to: 1.0, duration: 0.1),
                SKAction.scale(to: 1.2, duration: 0.1)
            ])
            
            let fadeOut = SKAction.group([
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.scale(to: 0.2, duration: 0.3)
            ])
            
            label.run(SKAction.sequence([
                wait,
                popIn,
                bounce,
                SKAction.wait(forDuration: 0.3),
                fadeOut,
                SKAction.removeFromParent()
            ]))
            delay += 0.5
        }
        
        run(SKAction.wait(forDuration: delay)) { [weak self] in
            self?.showBrain(at: center)
        }
    }
    
    func showBrain(at position: CGPoint) {
        // Brain Container for Shadow Effect
        let brainShadow = SKLabelNode(text: "🧠")
        brainShadow.fontSize = frame.width * 0.3
        brainShadow.fontColor = .black.withAlphaComponent(0.2)
        brainShadow.position = CGPoint(x: position.x + 8, y: frame.maxY + 100)
        addChild(brainShadow)
        
        let brain = SKLabelNode(text: "🧠")
        brain.fontSize = frame.width * 0.3
        brain.position = CGPoint(x: position.x, y: frame.maxY + 108)
        addChild(brain)
        
        let moveIn = SKAction.move(to: position, duration: 1.2)
        moveIn.timingMode = .easeOut
        
        let wobble = SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.5),
            SKAction.scale(to: 0.95, duration: 0.5)
        ]))
        
        brain.run(moveIn)
        brainShadow.run(moveIn) { [weak self] in
            brain.run(wobble)
            self?.showTitle(at: position)
        }
    }
    
    func showTitle(at position: CGPoint) {
        let titleContainer = SKNode()
        titleContainer.position = CGPoint(x: position.x, y: position.y - (frame.height * 0.2))
        titleContainer.alpha = 0
        titleContainer.setScale(0)
        addChild(titleContainer)
        
        // Cartoon style title with "Shadow" - Rainbow MEMORANDUM
        let titleText = "MEMORANDUM"
        let colors: [SKColor] = [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .magenta, .red, .orange]
        let charSize: CGFloat = frame.width * 0.09
        let spacing: CGFloat = charSize * 0.75
        var xOffset: CGFloat = -(CGFloat(titleText.count - 1) * spacing) / 2

        for (i, char) in titleText.enumerated() {
            let charShadow = SKLabelNode(fontNamed: "Gameplay")
            charShadow.text = String(char)
            charShadow.fontSize = charSize
            charShadow.fontColor = SKColor(red: 0.17, green: 0.18, blue: 0.26, alpha: 1.0)
            charShadow.position = CGPoint(x: xOffset + 3, y: -3)
            charShadow.zPosition = -1
            titleContainer.addChild(charShadow)

            let charNode = SKLabelNode(fontNamed: "Gameplay")
            charNode.text = String(char)
            charNode.fontSize = charSize
            charNode.fontColor = colors[i % colors.count]
            charNode.position = CGPoint(x: xOffset, y: 0)
            titleContainer.addChild(charNode)

            xOffset += spacing
        }
        
        let appear = SKAction.group([
            SKAction.fadeIn(withDuration: 0.6),
            SKAction.scale(to: 1.0, duration: 0.6)
        ])
        appear.timingMode = .easeOut
        
        titleContainer.run(appear) { [weak self] in
            let wait = SKAction.wait(forDuration: 1.8)
            self?.run(wait) {
                self?.transitionToMenu()
            }
        }
    }
    
    func transitionToMenu() {
        let menuScene = MenuScene(size: self.size)
        menuScene.scaleMode = .aspectFill
        let transition = SKTransition.fade(with: .white, duration: 1.0)
        self.view?.presentScene(menuScene, transition: transition)
    }
}
