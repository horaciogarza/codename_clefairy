import SpriteKit

class MenuScene: SKScene {
    
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedback = UINotificationFeedbackGenerator()
    private var shopLabel: SKLabelNode? // Reference to update coin count
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.25, green: 0.75, blue: 1.00, alpha: 1.0)
        setupBackground()
        setupUI()
        updateShopButton()
    }
    
    private func updateShopButton() {
        shopLabel?.text = "SHOP 💰 \(GameManager.shared.totalCoins)"
    }
    
    private func setupBackground() {
        let sun = SKShapeNode(circleOfRadius: 60)
        sun.fillColor = .yellow
        sun.strokeColor = .orange
        sun.lineWidth = 4
        sun.position = CGPoint(x: frame.maxX - 80, y: frame.maxY - 80)
        sun.zPosition = -5
        addChild(sun)
        
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
        
        let rotate = SKAction.rotate(byAngle: .pi, duration: 10)
        sun.run(SKAction.repeatForever(rotate))
        
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
        hill2.fillColor = SKColor(red: 0.3, green: 0.7, blue: 0.3, alpha: 1.0)
        hill2.strokeColor = .clear
        hill2.zPosition = -3
        addChild(hill2)
        
        for _ in 0..<5 { spawnCloud() }
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
        cloudContainer.position = CGPoint(x: CGFloat.random(in: 0...frame.width), y: CGFloat.random(in: frame.midY...frame.maxY))
        cloudContainer.zPosition = -6
        addChild(cloudContainer)
        let move = SKAction.moveBy(x: frame.width + 200, y: 0, duration: Double.random(in: 30...60))
        let reset = SKAction.moveBy(x: -(frame.width + 400), y: 0, duration: 0)
        cloudContainer.run(SKAction.repeatForever(SKAction.sequence([move, reset])))
    }
    
    func setupUI() {
        let safeTop = view?.safeAreaInsets.top ?? 50
        
        let infoBtn = createIconBtn(text: "?", color: .systemPink)
        infoBtn.position = CGPoint(x: 50, y: frame.maxY - safeTop - 30)
        infoBtn.name = "info"
        addChild(infoBtn)
        
        let cheatBtn = SKLabelNode(fontNamed: "Gameplay")
        cheatBtn.text = "[+100💰]"
        cheatBtn.fontSize = 20
        cheatBtn.fontColor = .systemGreen
        cheatBtn.position = CGPoint(x: frame.maxX - 60, y: frame.maxY - safeTop - 30)
        cheatBtn.name = "cheat_coin"
        cheatBtn.zPosition = 100
        addChild(cheatBtn)
        
        let titleNode = SKNode()
        titleNode.position = CGPoint(x: frame.midX, y: frame.midY + (frame.height * 0.3))
        addChild(titleNode)
        
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
            let shadow = SKLabelNode(fontNamed: "Gameplay")
            shadow.text = String(char)
            shadow.fontSize = charSize
            shadow.fontColor = .black
            shadow.zPosition = -1
            shadow.position = CGPoint(x: 3, y: -3)
            charNode.addChild(shadow)
            titleNode.addChild(charNode)
            let bounce = SKAction.sequence([SKAction.moveBy(x: 0, y: 5, duration: 0.3), SKAction.moveBy(x: 0, y: -5, duration: 0.3)])
            let delay = SKAction.wait(forDuration: Double(i) * 0.1)
            charNode.run(SKAction.repeatForever(SKAction.sequence([delay, bounce, SKAction.wait(forDuration: 2.0)])))
            xOffset += spacing
        }
        
        let board = createCartoonPanel(size: CGSize(width: frame.width * 0.85, height: frame.height * 0.25), color: SKColor(red: 0.9, green: 0.9, blue: 0.95, alpha: 1.0))
        board.position = CGPoint(x: frame.midX, y: frame.midY + 40)
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
        
        let playBtn = createCartoonButton(text: "PLAY!", color: .systemGreen, size: CGSize(width: frame.width * 0.7, height: 100))
        playBtn.position = CGPoint(x: frame.midX, y: frame.midY - (frame.height * 0.15))
        playBtn.name = "play"
        addChild(playBtn)
        
        let scaleUp = SKAction.scale(to: 1.05, duration: 0.6)
        let scaleDown = SKAction.scale(to: 0.95, duration: 0.6)
        playBtn.run(SKAction.repeatForever(SKAction.sequence([scaleUp, scaleDown])))
        
        let shopBtn = createCartoonButton(text: "SHOP", color: .systemPurple, size: CGSize(width: frame.width * 0.7, height: 70))
        shopBtn.position = CGPoint(x: frame.midX, y: playBtn.position.y - 100)
        shopBtn.name = "shop"
        addChild(shopBtn)
        
        if let label = shopBtn.children.first(where: { ($0 as? SKLabelNode)?.name == "btn_label" }) as? SKLabelNode {
            shopLabel = label
        } else if let label = shopBtn.children.first(where: { $0 is SKLabelNode }) as? SKLabelNode {
            shopLabel = label
        }
        
        if !UserDefaults.standard.bool(forKey: "HasLaunchedBefore") {
            showIntroPopup()
            UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
        }
    }
    
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
        let label = SKLabelNode(fontNamed: "AppleColorEmoji")
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
    
    private func showShopPopup() {
        if childNode(withName: "shop_overlay") != nil { return }
        
        let overlay = SKShapeNode(rectOf: self.size)
        overlay.fillColor = .black.withAlphaComponent(0.7)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: frame.midX, y: frame.midY)
        overlay.zPosition = 100
        overlay.name = "shop_overlay"
        addChild(overlay)
        
        let boardHeight = frame.height * 0.7
        let board = createCartoonPanel(size: CGSize(width: frame.width * 0.9, height: boardHeight), color: .white)
        board.position = .zero
        overlay.addChild(board)
        
        let title = SKLabelNode(fontNamed: "Gameplay")
        title.text = "ITEM SHOP"
        title.fontSize = 32
        title.fontColor = .black
        title.position = CGPoint(x: 0, y: boardHeight/2 - 50)
        title.zPosition = 10
        board.addChild(title)
        
        let skins = ButtonSkin.allCases
        let startY = boardHeight/2 - 120
        let spacing: CGFloat = 80
        
        for (i, skin) in skins.enumerated() {
            let row = SKNode()
            row.position = CGPoint(x: 0, y: startY - CGFloat(i) * spacing)
            board.addChild(row)
            
            // Preview Circle - Uses Dynamic Styles
            let preview = SKShapeNode(circleOfRadius: 25)
            preview.fillColor = skin.buttonColor
            preview.strokeColor = skin.strokeColor
            preview.lineWidth = skin.strokeWidth
            if skin == .metal { preview.glowWidth = 2 } // Cyber Glow
            preview.position = CGPoint(x: -100, y: 0)
            row.addChild(preview)
            
            let nameLabel = SKLabelNode(fontNamed: "Gameplay")
            nameLabel.text = skin.rawValue
            nameLabel.fontSize = 20
            nameLabel.fontColor = .black
            nameLabel.horizontalAlignmentMode = .left
            nameLabel.position = CGPoint(x: -60, y: 5)
            row.addChild(nameLabel)
            
            let costLabel = SKLabelNode(fontNamed: "Gameplay")
            costLabel.fontSize = 16
            costLabel.horizontalAlignmentMode = .left
            costLabel.position = CGPoint(x: -60, y: -15)
            row.addChild(costLabel)
            
            let isUnlocked = GameManager.shared.unlockedSkins.contains(skin)
            let isSelected = GameManager.shared.selectedSkin == skin
            
            var btnColor: UIColor = .systemBlue
            var btnText = "BUY"
            
            if isSelected {
                btnColor = .systemGreen
                btnText = "USED"
            } else if isUnlocked {
                btnColor = .systemBlue
                btnText = "USE"
            } else {
                btnColor = .systemOrange
                btnText = "\(skin.cost)"
            }
            
            let btn = createCartoonButton(text: btnText, color: btnColor, size: CGSize(width: 100, height: 50))
            btn.position = CGPoint(x: 100, y: 0)
            btn.name = "skin_\(skin.rawValue)"
            row.addChild(btn)
            
            if isUnlocked {
                costLabel.text = "Owned"
                costLabel.fontColor = .systemGreen
            } else {
                costLabel.text = "Price: \(skin.cost)"
                costLabel.fontColor = .gray
            }
        }
        
        let closeLabel = SKLabelNode(fontNamed: "Gameplay")
        closeLabel.text = "TAP OUTSIDE TO CLOSE"
        closeLabel.fontSize = 16
        closeLabel.fontColor = .gray
        closeLabel.position = CGPoint(x: 0, y: -boardHeight/2 + 30)
        board.addChild(closeLabel)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = self.nodes(at: location)
        
        if let _ = nodes.first(where: { $0.name == "cheat_coin" }) {
            GameManager.shared.totalCoins += 100
            hapticFeedback.impactOccurred()
            updateShopButton()
            if childNode(withName: "shop_overlay") != nil {
                childNode(withName: "shop_overlay")?.removeFromParent()
                showShopPopup()
            }
            return
        }
        
        if let overlay = childNode(withName: "popup_overlay") {
            overlay.removeFromParent()
            hapticFeedback.impactOccurred()
            return
        }
        
        if let shopOverlay = childNode(withName: "shop_overlay") {
            for node in nodes {
                let parent = (node.name == "btn_body") ? node.parent : node
                if let name = parent?.name, name.starts(with: "skin_") {
                    let skinName = String(name.dropFirst(5))
                    if let skin = ButtonSkin(rawValue: skinName) {
                        handleSkinAction(skin)
                    }
                    return
                }
            }
            shopOverlay.removeFromParent()
            hapticFeedback.impactOccurred()
            updateShopButton()
            return
        }
        
        for node in nodes {
            let parent = (node.name == "btn_body") ? node.parent : node
            let nodeName = parent?.name ?? node.name
            
            if nodeName == "play" {
                animateTap(parent ?? node) {
                    self.hapticFeedback.impactOccurred()
                    self.transitionToGame()
                }
            } else if nodeName == "shop" {
                animateTap(parent ?? node) {
                    self.hapticFeedback.impactOccurred()
                    self.showShopPopup()
                }
            } else if nodeName == "info" {
                animateTap(parent ?? node) {
                    self.hapticFeedback.impactOccurred()
                    self.showIntroPopup()
                }
            }
        }
    }
    
    private func handleSkinAction(_ skin: ButtonSkin) {
        let mgr = GameManager.shared
        if mgr.unlockedSkins.contains(skin) {
            mgr.selectedSkin = skin
        } else {
            if mgr.unlockSkin(skin) {
                mgr.selectedSkin = skin
                playSound("kaching.mp3")
            } else {
                notificationFeedback.notificationOccurred(.error)
                return
            }
        }
        hapticFeedback.impactOccurred()
        childNode(withName: "shop_overlay")?.removeFromParent()
        showShopPopup()
        updateShopButton()
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
