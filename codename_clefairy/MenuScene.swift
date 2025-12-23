import SpriteKit

class MenuScene: SKScene {
    
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.25, green: 0.75, blue: 1.00, alpha: 1.0) // Brighter Sky Blue
        setupBackground()
        setupUI()
    }
    
    private func setupBackground() {
        // 1. Sun with a face
        let sun = SKShapeNode(circleOfRadius: 60)
        sun.fillColor = .yellow
        sun.strokeColor = .orange
        sun.lineWidth = 4
        sun.position = CGPoint(x: frame.maxX - 80, y: frame.maxY - 80)
        sun.zPosition = -5
        addChild(sun)
        
        // Sun rays
        for i in 0..<8 {
            let ray = SKShapeNode(rectOf: CGSize(width: 20, height: 8))
            ray.fillColor = .yellow
            ray.strokeColor = .clear
            ray.position = CGPoint(x: 80, y: 0)
            ray.zRotation = CGFloat(i) * (.pi / 4)
            
            let rayContainer = SKNode()
            rayContainer.position = .zero
            rayContainer.addChild(ray)
            rayContainer.zRotation = CGFloat(i) * (.pi / 4)
            sun.addChild(rayContainer)
        }
        
        // Sun Face
        let leftEye = SKShapeNode(circleOfRadius: 6)
        leftEye.fillColor = .black
        leftEye.position = CGPoint(x: -20, y: 10)
        sun.addChild(leftEye)
        
        let rightEye = SKShapeNode(circleOfRadius: 6)
        rightEye.fillColor = .black
        rightEye.position = CGPoint(x: 20, y: 10)
        sun.addChild(rightEye)
        
        let smile = SKShapeNode()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: -20, y: -15))
        path.addQuadCurve(to: CGPoint(x: 20, y: -15), controlPoint: CGPoint(x: 0, y: -35))
        smile.path = path.cgPath
        smile.strokeColor = .black
        smile.lineWidth = 4
        smile.lineCap = .round
        sun.addChild(smile)
        
        // Animate Sun
        let rotate = SKAction.rotate(byAngle: .pi, duration: 10)
        sun.run(SKAction.repeatForever(rotate))
        
        // 2. Hills
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
        
        // 3. Pixeled Clouds
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
        let safeTop = view?.safeAreaInsets.top ?? 50
        
        // --- Top Bar (Clean & Consolidated) ---
        let barHeight: CGFloat = 80
        let barY = frame.maxY - safeTop - (barHeight / 2)
        
        // Bar Background (Translucent "Glass/Cloud" Effect)
        let topBar = SKShapeNode(rectOf: CGSize(width: frame.width - 40, height: barHeight), cornerRadius: 25)
        topBar.fillColor = .white.withAlphaComponent(0.85)
        topBar.strokeColor = .clear
        topBar.position = CGPoint(x: frame.midX, y: barY)
        topBar.zPosition = 10
        
        // Shadow for Bar
        let barShadow = SKShapeNode(rectOf: CGSize(width: frame.width - 40, height: barHeight), cornerRadius: 25)
        barShadow.fillColor = .black.withAlphaComponent(0.2)
        barShadow.strokeColor = .clear
        barShadow.position = CGPoint(x: 4, y: -4)
        barShadow.zPosition = -1
        topBar.addChild(barShadow)
        
        addChild(topBar)
        
        // --- Buttons & Score in Top Bar ---
        
        // Info Button (Left)
        let infoBtn = createIconBtn(text: "?", color: .systemPink)
        infoBtn.position = CGPoint(x: -(topBar.frame.width/2) + 50, y: 0)
        infoBtn.name = "info"
        topBar.addChild(infoBtn)
        
        // Settings Button (Right)
        let settingsBtn = createIconBtn(text: "⚙", color: .systemBlue)
        settingsBtn.position = CGPoint(x: (topBar.frame.width/2) - 50, y: 0)
        settingsBtn.name = "settings"
        topBar.addChild(settingsBtn)
        
        // Score (Center)
        let scoreLabel = SKLabelNode(fontNamed: "Gameplay")
        scoreLabel.text = "BEST: 9999"
        scoreLabel.fontSize = 28
        scoreLabel.fontColor = .darkGray
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.position = CGPoint(x: 0, y: 0)
        topBar.addChild(scoreLabel)
        
        
        // --- Title (Smaller & Cleaner) ---
        let titleNode = SKNode()
        // Positioned below the bar, slightly higher than before
        titleNode.position = CGPoint(x: frame.midX, y: barY - barHeight - 40)
        addChild(titleNode)
        
        let titleText = "MEMORANDUM"
        let colors: [SKColor] = [.red, .orange, .yellow, .green, .blue, .purple]
        
        // Reduced font size and spacing
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
        
        // --- Main Board ---
        let board = createCartoonPanel(size: CGSize(width: frame.width * 0.85, height: frame.height * 0.25), color: SKColor(red: 0.9, green: 0.9, blue: 0.95, alpha: 1.0))
        board.position = CGPoint(x: frame.midX, y: frame.midY + 20)
        addChild(board)
        
        let boardTitle = SKLabelNode(fontNamed: "Gameplay")
        boardTitle.text = "DAILY CHALLENGE"
        boardTitle.fontSize = 28
        boardTitle.fontColor = .black
        boardTitle.position = CGPoint(x: 0, y: 40)
        boardTitle.zPosition = 2
        board.addChild(boardTitle)
        
        let subText = SKLabelNode(fontNamed: "Gameplay")
        subText.text = "Can you beat it?"
        subText.fontSize = 18
        subText.fontColor = .darkGray
        subText.position = CGPoint(x: 0, y: 0)
        subText.zPosition = 2
        board.addChild(subText)
        
        // --- Play Button ---
        let playBtn = createCartoonButton(text: "PLAY!", color: .systemGreen, size: CGSize(width: frame.width * 0.7, height: 100))
        playBtn.position = CGPoint(x: frame.midX, y: frame.midY - (frame.height * 0.2))
        playBtn.name = "play"
        addChild(playBtn)
        
        let scaleUp = SKAction.scale(to: 1.05, duration: 0.6)
        let scaleDown = SKAction.scale(to: 0.95, duration: 0.6)
        playBtn.run(SKAction.repeatForever(SKAction.sequence([scaleUp, scaleDown])))
        
        // Check for first launch
        if !UserDefaults.standard.bool(forKey: "HasLaunchedBefore") {
            showIntroPopup()
            UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
        }
    }
    
    private func createIconBtn(text: String, color: SKColor) -> SKNode {
        let container = SKNode()
        let size: CGFloat = 50
        
        // Shadow
        let shadow = SKShapeNode(circleOfRadius: size/2)
        shadow.fillColor = .black.withAlphaComponent(0.2)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 2, y: -2)
        container.addChild(shadow)
        
        // Body
        let body = SKShapeNode(circleOfRadius: size/2)
        body.fillColor = color
        body.strokeColor = .white
        body.lineWidth = 3
        body.name = "btn_body" // Detect taps here
        container.addChild(body)
        
        // Label
        let label = SKLabelNode(fontNamed: "Gameplay")
        label.text = text
        label.fontSize = 30
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
        label.fontSize = size.height * 0.5
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.zPosition = 1
        container.addChild(label)
        
        return container
    }
    
    private func showIntroPopup() {
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
        
        if let popup = childNode(withName: "popup_overlay") {
            popup.removeFromParent()
            hapticFeedback.impactOccurred()
            return
        }
        
        for node in nodes {
            // Check if we hit the button body or the container
            let parent = (node.name == "btn_body") ? node.parent : node
            let nodeName = parent?.name ?? node.name
            
            if nodeName == "play" {
                animateTap(parent ?? node) {
                    self.hapticFeedback.impactOccurred()
                    self.transitionToGame()
                }
            } else if nodeName == "settings" {
                animateTap(parent ?? node) {
                    self.hapticFeedback.impactOccurred()
                }
            } else if nodeName == "info" {
                animateTap(parent ?? node) {
                    self.hapticFeedback.impactOccurred()
                    self.showIntroPopup()
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
        // Capture snapshot for custom door transition
        if let snapshot = view.texture(from: self) {
            let gameScene = GameScene(size: self.size)
            gameScene.scaleMode = .aspectFill
            gameScene.doorTransitionTexture = snapshot
            view.presentScene(gameScene) // Present immediately, GameScene handles animation
        } else {
            // Fallback if snapshot fails
            let gameScene = GameScene(size: self.size)
            gameScene.scaleMode = .aspectFill
            let transition = SKTransition.doorsOpenHorizontal(withDuration: 0.8)
            view.presentScene(gameScene, transition: transition)
        }
    }
}