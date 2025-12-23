import SpriteKit

class MenuScene: SKScene {
    
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.25, green: 0.75, blue: 1.00, alpha: 1.0) // Dark Navy Blue 0x0A0E14
        setupBackground()
        setupUI()
        
        Task { @MainActor in
            AdManager.shared.showBanner()
        }
    }
    
    private func setupBackground() {
        // 1. Hills
        let hill1 = SKShapeNode()
        let path1 = UIBezierPath()
        path1.move(to: CGPoint(x: 0, y: 0))
        path1.addLine(to: CGPoint(x: 0, y: frame.height * 0.3))
        path1.addQuadCurve(to: CGPoint(x: frame.width, y: frame.height * 0.2), controlPoint: CGPoint(x: frame.width * 0.5, y: frame.height * 0.4))
        path1.addLine(to: CGPoint(x: frame.width, y: 0))
        path1.close()
        hill1.path = path1.cgPath
        hill1.fillColor = SKColor(red: 0.4, green: 0.8, blue: 0.4, alpha: 1.0)
        hill1.strokeColor = .clear
        hill1.zPosition = -4
        addChild(hill1)
        
        let hill2 = SKShapeNode()
        let path2 = UIBezierPath()
        path2.move(to: CGPoint(x: 0, y: 0))
        path2.addLine(to: CGPoint(x: 0, y: frame.height * 0.15))
        path2.addQuadCurve(to: CGPoint(x: frame.width, y: frame.height * 0.25), controlPoint: CGPoint(x: frame.width * 0.4, y: frame.height * 0.05))
        path2.addLine(to: CGPoint(x: frame.width, y: 0))
        path2.close()
        hill2.path = path2.cgPath
        hill2.fillColor = SKColor(red: 0.3, green: 0.7, blue: 0.3, alpha: 1.0) // Darker Green
        hill2.strokeColor = .clear
        hill2.zPosition = -3
        addChild(hill2)
        
        // 2. Pixeled Clouds
        for _ in 0..<5 {
            spawnCloud()
        }
    }
    
    private func spawnCloud() {
        let cloudContainer = SKNode()
        let blockSize: CGFloat = 20
        let cols = Int.random(in: 4...7)
        let rows = Int.random(in: 2...4)
        
        for r in 0..<rows {
            for c in 0..<cols {
                if Bool.random() || (r > 0 && r < rows-1 && c > 0 && c < cols-1) {
                    let block = SKShapeNode(rectOf: CGSize(width: blockSize, height: blockSize))
                    block.fillColor = .white
                    block.strokeColor = .clear
                    block.position = CGPoint(x: CGFloat(c) * blockSize, y: CGFloat(r) * blockSize)
                    cloudContainer.addChild(block)
                }
            }
        }
        
        cloudContainer.alpha = 0.8
        cloudContainer.position = CGPoint(
            x: CGFloat.random(in: 0...frame.width),
            y: CGFloat.random(in: frame.midY...frame.maxY)
        )
        cloudContainer.zPosition = -6
        addChild(cloudContainer)
        
        let move = SKAction.moveBy(x: frame.width + 200, y: 0, duration: Double.random(in: 30...60))
        let reset = SKAction.moveBy(x: -(frame.width + 400), y: 0, duration: 0)
        cloudContainer.run(SKAction.repeatForever(SKAction.sequence([move, reset])))
    }
    
    func setupUI() {
        let shiftY = size.height * 0.05
        
        // --- How To Play Button (Bottom Left) ---
        let infoBtn = createCartoonButton(text: "HOW TO PLAY", color: .systemPink, size: CGSize(width: 180, height: 50))
        let safeBottom = view?.safeAreaInsets.bottom ?? 20
        infoBtn.position = CGPoint(x: 110, y: safeBottom + 50 + shiftY)
        infoBtn.name = "info"
        addChild(infoBtn)
        
        // --- Title ---
        let titleNode = SKNode()
        titleNode.position = CGPoint(x: frame.midX, y: frame.midY + (frame.height * 0.3))
        addChild(titleNode)
        
        // --- High Score Display ---
        let highScoreLabel = SKLabelNode(fontNamed: "Gameplay")
        highScoreLabel.text = "BEST: \(GameManager.shared.highScore)"
        highScoreLabel.fontSize = 20
        highScoreLabel.fontColor = .white
        highScoreLabel.position = CGPoint(x: frame.midX, y: titleNode.position.y - 60)
        addChild(highScoreLabel)
        
        let titleText = "MEMORANDUM"
        let colors: [SKColor] = [.red, .orange, .yellow, .green, .blue, .purple]
        
        let charSize: CGFloat = 38
        let spacing: CGFloat = 30
        var xOffset: CGFloat = -(CGFloat(titleText.count) * (spacing / 2))
        
        for (i, char) in titleText.enumerated() {
            let charNode = SKLabelNode(fontNamed: "Gameplay")
            charNode.text = String(char)
            charNode.fontSize = charSize
            charNode.fontColor = colors[i % colors.count]
            charNode.position = CGPoint(x: xOffset, y: 0)
            
            // Stroke effect (shadow)
            let shadow = SKLabelNode(fontNamed: "Gameplay")
            shadow.text = String(char)
            shadow.fontSize = charSize
            shadow.fontColor = .black
            shadow.zPosition = -1
            shadow.position = CGPoint(x: 3, y: -3)
            charNode.addChild(shadow)
            
            titleNode.addChild(charNode)
            
            let bounce = SKAction.sequence([
                SKAction.moveBy(x: 0, y: 5, duration: 0.3),
                SKAction.moveBy(x: 0, y: -5, duration: 0.3)
            ])
            let delay = SKAction.wait(forDuration: Double(i) * 0.1)
            charNode.run(SKAction.repeatForever(SKAction.sequence([delay, bounce, SKAction.wait(forDuration: 2.0)])))
            
            xOffset += spacing
        }
        
        // --- Play Classic Button ---
        let playClassicBtn = createCartoonButton(text: "PLAY CLASSIC", color: .systemGreen, size: CGSize(width: frame.width * 0.7, height: 80))
        playClassicBtn.position = CGPoint(x: frame.midX, y: frame.midY - (frame.height * 0.12) + shiftY)
        playClassicBtn.name = "play_classic"
        addChild(playClassicBtn)
        
        let classicPulse = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.6),
            SKAction.scale(to: 0.95, duration: 0.6)
        ])
        playClassicBtn.run(SKAction.repeatForever(classicPulse))
        
        // --- Play Zen Button ---
        let playZenBtn = createCartoonButton(text: "PLAY ZEN", color: .systemBlue, size: CGSize(width: frame.width * 0.7, height: 70))
        playZenBtn.position = CGPoint(x: frame.midX, y: playClassicBtn.position.y - 100)
        playZenBtn.name = "play_zen"
        addChild(playZenBtn)
        
        // Check for first launch - PRESENT ONBOARDING
        if !UserDefaults.standard.bool(forKey: "HasLaunchedBefore") {
            UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
            run(SKAction.wait(forDuration: 0.1)) { [weak self] in
                self?.transitionToOnboarding()
            }
        }
    }
    
    private func transitionToOnboarding() {
        let onboarding = OnboardingScene(size: self.size)
        onboarding.scaleMode = .aspectFill
        let transition = SKTransition.moveIn(with: .up, duration: 0.5)
        view?.presentScene(onboarding, transition: transition)
    }
    
    // --- Popup & Button Helpers ---
    
    private func createIconBtn(text: String, color: SKColor) -> SKNode {
        let container = SKNode()
        let size: CGFloat = 50
        
        let shadow = SKShapeNode(circleOfRadius: size/2)
        shadow.fillColor = .black.withAlphaComponent(0.2)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 2, y: -2)
        container.addChild(shadow)
        
        let body = SKShapeNode(circleOfRadius: size/2)
        body.fillColor = color
        body.strokeColor = .white
        body.lineWidth = 3
        body.name = "btn_body"
        container.addChild(body)
        
        let label = SKLabelNode(fontNamed: "AppleColorEmoji") // Better for emojis
        label.text = text
        label.fontSize = 24
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.zPosition = 1
        container.addChild(label)
        
        return container
    }
    
    private func createCartoonPanel(size: CGSize, color: SKColor) -> SKNode {
        let container = SKNode()
        
        let shadow = SKShapeNode(rectOf: size, cornerRadius: 20)
        shadow.fillColor = .black.withAlphaComponent(0.4)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 8, y: -8)
        container.addChild(shadow)
        
        let body = SKShapeNode(rectOf: size, cornerRadius: 20)
        body.fillColor = color
        body.strokeColor = .white
        body.lineWidth = 6
        container.addChild(body)
        
        return container
    }
    
    private func createCartoonButton(text: String, color: SKColor, size: CGSize) -> SKNode {
        let container = SKNode()
        
        let shadow = SKShapeNode(rectOf: size, cornerRadius: 25)
        shadow.fillColor = .black.withAlphaComponent(0.4)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -8)
        container.addChild(shadow)
        
        let body = SKShapeNode(rectOf: size, cornerRadius: 25)
        body.fillColor = color
        body.strokeColor = .white
        body.lineWidth = 6
        body.name = "btn_body"
        container.addChild(body)
        
        let label = SKLabelNode(fontNamed: "Gameplay")
        label.text = text
        label.fontSize = size.height * 0.4
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.zPosition = 1
        label.name = "btn_label"
        container.addChild(label)
        
        return container
    }
    
    private func showIntroPopup() {
        // Prevent double open
        if childNode(withName: "popup_overlay") != nil { return }
        
        let overlay = SKShapeNode(rectOf: self.size)
        overlay.fillColor = .black.withAlphaComponent(0.7)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: frame.midX, y: frame.midY)
        overlay.zPosition = 100
        overlay.name = "popup_overlay"
        addChild(overlay)
        
        let board = createCartoonPanel(size: CGSize(width: frame.width * 0.85, height: frame.height * 0.6), color: .white)
        board.position = .zero
        overlay.addChild(board)
        
        let title = SKLabelNode(fontNamed: "Gameplay")
        title.text = "HOW TO PLAY"
        title.fontSize = 32
        title.fontColor = .black
        title.position = CGPoint(x: 0, y: 180)
        title.zPosition = 10
        board.addChild(title)
        
        let instructions = [
            "1. Watch emojis!",
            "2. Wait for GO!",
            "3. Tap in ORDER!",
            "4. Be FAST!",
            "",
            "TAP TO START"
        ]
        
        for (i, line) in instructions.enumerated() {
            let label = SKLabelNode(fontNamed: "Gameplay")
            label.text = line
            label.fontSize = 20
            label.fontColor = .darkGray
            label.position = CGPoint(x: 0, y: 100 - CGFloat(i * 40))
            label.zPosition = 10
            board.addChild(label)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = self.nodes(at: location)
        
        // Handle Popups
        if let overlay = childNode(withName: "popup_overlay") {
            overlay.removeFromParent()
            hapticFeedback.impactOccurred()
            return
        }
        
        for node in nodes {
            let parent = (node.name == "btn_body") ? node.parent : node
            let nodeName = parent?.name ?? node.name
            
            // Tactile feedback
            let feedbackTarget = parent ?? node
            feedbackTarget.run(SKAction.scale(to: 0.9, duration: 0.1))
            
            if nodeName == "play_classic" {
                animateTap(parent ?? node) {
                    self.hapticFeedback.impactOccurred()
                    GameManager.shared.currentMode = .classic
                    self.transitionToGame()
                }
            } else if nodeName == "play_zen" {
                animateTap(parent ?? node) {
                    self.hapticFeedback.impactOccurred()
                    GameManager.shared.currentMode = .zen
                    self.transitionToGame()
                }
            } else if nodeName == "info" {
                animateTap(parent ?? node) {
                    self.hapticFeedback.impactOccurred()
                    self.transitionToOnboarding()
                }
            }
        }
    }
    
    
    private func animateTap(_ node: SKNode, completion: @escaping () -> Void) {
        let scaleDown = SKAction.scale(to: 0.9, duration: 0.1)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
        node.run(SKAction.sequence([scaleDown, scaleUp])) {
            completion()
        }
    }
    
    func transitionToGame() {
        guard let view = self.view else { return }
        if let snapshot = view.texture(from: self) {
            let gameScene = GameScene(size: self.size)
            gameScene.scaleMode = .aspectFill
            gameScene.doorTransitionTexture = snapshot
            view.presentScene(gameScene)
        } else {
            let gameScene = GameScene(size: self.size)
            gameScene.scaleMode = .aspectFill
            let transition = SKTransition.doorsOpenHorizontal(withDuration: 0.8)
            view.presentScene(gameScene, transition: transition)
        }
    }
    
    private func playSound(_ fileName: String) {
        run(SKAction.playSoundFileNamed(fileName, waitForCompletion: false))
    }
}
