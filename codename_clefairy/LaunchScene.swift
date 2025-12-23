import SpriteKit

class LaunchScene: SKScene {
    
    override func didMove(to view: SKView) {
        // Soft pastel gradient-like background
        backgroundColor = SKColor(red: 1.00, green: 0.49, blue: 0.73, alpha: 1.0) // Vibrant Pink
        setupDecorations()
        setupAnimation()
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
        
        // Cartoon style title with "Shadow"
        let titleShadow = SKLabelNode(fontNamed: "Gameplay")
        titleShadow.text = "CODENAME CLEFAIRY"
        titleShadow.fontSize = frame.width * 0.085
        titleShadow.fontColor = SKColor(red: 0.17, green: 0.18, blue: 0.26, alpha: 1.0)
        titleShadow.position = CGPoint(x: 2, y: -2)
        titleContainer.addChild(titleShadow)
        
        let titleMain = SKLabelNode(fontNamed: "Gameplay")
        titleMain.text = "CODENAME CLEFAIRY"
        titleMain.fontSize = frame.width * 0.085
        titleMain.fontColor = .white
        titleMain.position = .zero
        titleContainer.addChild(titleMain)
        
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