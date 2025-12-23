import SpriteKit

class OnboardingScene: SKScene {
    
    private var currentPage = 0
    private let totalPages = 3
    
    private let pages: [(title: String, icon: String, description: String)] = [
        ("MEMORIZE", "🧠", "Watch the sequence of emojis carefully as they appear on the board."),
        ("REPEAT", "👉", "Wait for the 'GO!' signal, then tap the emojis in the exact same order."),
        ("GO FAST", "⚡️", "Be quick! Higher speed builds your heat meter and triggers FRENZY MODE for 2x points!")
    ]
    
    private var contentNode = SKNode()
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
        Task { @MainActor in
            AdManager.shared.hideBanner()
        }
        
        setupUI()
        showPage(index: 0)
    }
    
    private func setupUI() {
        addChild(contentNode)
        
        // Navigation buttons
        let skipBtn = SKLabelNode(fontNamed: "Gameplay")
        skipBtn.text = "SKIP"
        skipBtn.fontSize = 18
        skipBtn.fontColor = .lightGray
        skipBtn.position = CGPoint(x: frame.maxX - 60, y: frame.maxY - 60)
        skipBtn.name = "skip"
        addChild(skipBtn)
        
        let nextBtn = SKShapeNode(rectOf: CGSize(width: 180, height: 60), cornerRadius: 30)
        nextBtn.fillColor = .systemGreen
        nextBtn.strokeColor = .white
        nextBtn.lineWidth = 3
        nextBtn.position = CGPoint(x: frame.midX, y: frame.midY - 150)
        nextBtn.name = "next"
        addChild(nextBtn)
        
        let nextLabel = SKLabelNode(fontNamed: "Gameplay")
        nextLabel.text = "NEXT"
        nextLabel.fontSize = 24
        nextLabel.fontColor = .white
        nextLabel.verticalAlignmentMode = .center
        nextLabel.name = "next"
        nextBtn.addChild(nextLabel)
    }
    
    private func showPage(index: Int) {
        contentNode.removeAllChildren()
        
        let page = pages[index]
        
        let iconLabel = SKLabelNode(text: page.icon)
        iconLabel.fontSize = 120
        iconLabel.position = CGPoint(x: frame.midX, y: frame.midY + 100)
        contentNode.addChild(iconLabel)
        
        let titleLabel = SKLabelNode(fontNamed: "Gameplay")
        titleLabel.text = page.title
        titleLabel.fontSize = 36 // Increased size
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: frame.midX, y: frame.midY - 20)
        contentNode.addChild(titleLabel)
        
        let descLabel = SKLabelNode(fontNamed: "Gameplay")
        descLabel.text = page.description
        descLabel.fontSize = 16
        descLabel.fontColor = .lightGray
        descLabel.preferredMaxLayoutWidth = frame.width * 0.8
        descLabel.numberOfLines = 0
        descLabel.horizontalAlignmentMode = .center
        descLabel.position = CGPoint(x: frame.midX, y: frame.midY - 100)
        contentNode.addChild(descLabel)
        
        // Dot indicators
        for i in 0..<totalPages {
            let dot = SKShapeNode(circleOfRadius: 6)
            dot.fillColor = (i == index) ? .white : .darkGray
            dot.strokeColor = .clear
            dot.position = CGPoint(x: frame.midX - CGFloat(totalPages-1)*15 + CGFloat(i * 30), y: frame.midY - 200) // Adjusted relative to next button
            contentNode.addChild(dot)
        }
        
        if index == totalPages - 1 {
            if let nextBtn = childNode(withName: "next")?.children.first as? SKLabelNode {
                nextBtn.text = "START"
            }
        }
        
        contentNode.alpha = 0
        contentNode.run(SKAction.fadeIn(withDuration: 0.3))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let node = atPoint(location)
        
        if node.name == "next" || node.parent?.name == "next" {
            if currentPage < totalPages - 1 {
                currentPage += 1
                showPage(index: currentPage)
            } else {
                finishOnboarding()
            }
        } else if node.name == "skip" {
            finishOnboarding()
        }
    }
    
    private func finishOnboarding() {
        let menuScene = MenuScene(size: self.size)
        menuScene.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: 0.8)
        view?.presentScene(menuScene, transition: transition)
    }
}
