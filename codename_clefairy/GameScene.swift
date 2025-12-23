import SpriteKit
import AVFoundation

class GameScene: SKScene {
    
    // MARK: - Properties
    var doorTransitionTexture: SKTexture?
    
    private var lives = 3
    private var level = 1
    private var currentScore = 0
    private var comboCount = 0
    private var lastTapTime: TimeInterval = 0
    
    // Boss State
    private var isBossLevel = false
    private var bossRound = 0 // 0 to 2 (3 rounds)
    private var bossNode: SKLabelNode?
    
    // Difficulty Configuration
    private struct LevelConfig {
        let poolSize: Int
        let sequenceLength: Int
        let movementType: MovementType
        let specialEffect: SpecialEffect
    }

    private enum MovementType {
        case none
        case slow
        case moderate
        case fast
        case wander
    }
    
    private enum SpecialEffect {
        case none
        case ghost
        case spin
        case pulse
    }

    // MARK: - Level Logic
    private func getLevelConfig(for level: Int) -> LevelConfig {
        // Boss levels (5, 10, 15...) handled separately, this config is for standard rounds
        switch level {
        case 1...2: return LevelConfig(poolSize: 8, sequenceLength: level, movementType: .none, specialEffect: .none)
        case 3...4: return LevelConfig(poolSize: 10, sequenceLength: level, movementType: .none, specialEffect: .none)
        case 5: return LevelConfig(poolSize: 10, sequenceLength: 3, movementType: .none, specialEffect: .none) // Boss placeholder config
        case 6...8: return LevelConfig(poolSize: 15, sequenceLength: 5, movementType: .slow, specialEffect: .none)
        case 9: return LevelConfig(poolSize: 15, sequenceLength: 6, movementType: .moderate, specialEffect: .ghost)
        case 10: return LevelConfig(poolSize: 15, sequenceLength: 6, movementType: .fast, specialEffect: .spin)
        case 11...15: return LevelConfig(poolSize: 20, sequenceLength: 7, movementType: .wander, specialEffect: .pulse)
        default:
            let baseSeq = 7 + (level - 11) / 2
            let effect: SpecialEffect = [.ghost, .spin, .pulse].randomElement() ?? .none
            let movement: MovementType = [.moderate, .fast, .wander].randomElement() ?? .fast
            let size = (level % 2 == 0) ? 15 : 20
            return LevelConfig(poolSize: size, sequenceLength: baseSeq, movementType: movement, specialEffect: effect)
        }
    }
    
    private var sequenceCount: Int {
        if isBossLevel { return 4 } // Boss sequences are fixed length but fast
        return getLevelConfig(for: level).sequenceLength
    }
    
    private let masterEmojiPool = [
        "🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼", "🐨", "🐯",
        "😂", "😍", "😎", "🤔", "😴", "🥳", "😱", "👻", "🤖", "👽",
        "🍎", "🍌", "🍇", "🍓", "🥝", "🍑", "🍍", "🍉", "🍒", "🥭",
        "🥦", "🥕", "🌽", "🍅", "🍆", "🥑", "🌶", "🥔", "🥬", "🍄",
        "⬅️", "➡️", "⬆️", "⬇️", "↗️", "↘️", "↕️", "↔️", "↩️", "↪️"
    ]
    private var activeEmojiPool: [String] = []
    private var currentSequence: [String] = []
    private var userSequence: [String] = []
    
    // Nodes
    private var heartNodes: [SKNode] = []
    private var countdownLabel = SKLabelNode(fontNamed: "Gameplay")
    private var centerDisplayLabel = SKLabelNode(fontNamed: "AppleColorEmoji")
    private var timerLabel = SKLabelNode(fontNamed: "Gameplay")
    private var levelLabel = SKLabelNode(fontNamed: "Gameplay")
    private var buttonNodes: [SKNode] = []
    private var stageNode: SKShapeNode!
    
    private var timerOverlay: SKShapeNode?
    private var flashOverlay: SKShapeNode?
    
    // State
    private var isAcceptingInput = false
    private var remainingTime = 0
    private var selectionTimer: Timer?
    
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        updateEnvironment()
        setupStage()
        setupBaseUI()
        setupOverlays()
        
        if let texture = doorTransitionTexture {
            performCustomDoorOpening(with: texture)
        } else {
            startNewRound()
        }
    }
    
    private func updateEnvironment() {
        // Clear old background
        children.filter { $0.name == "bg_element" }.forEach { $0.removeFromParent() }
        
        // 1-5: Day (Blue)
        // 6-10: Sunset (Orange)
        // 11-15: Night (Dark Blue)
        // 16+: Space (Black + Gravity)
        
        if level >= 16 {
            backgroundColor = .black
            physicsWorld.gravity = .zero // Space physics
            // Add Stars
            for _ in 0..<50 {
                let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...2))
                star.fillColor = .white
                star.position = CGPoint(x: CGFloat.random(in: 0...frame.width), y: CGFloat.random(in: 0...frame.height))
                star.alpha = CGFloat.random(in: 0.3...1.0)
                star.name = "bg_element"
                addChild(star)
            }
        } else if level >= 11 {
            backgroundColor = SKColor(red: 0.1, green: 0.1, blue: 0.3, alpha: 1.0) // Night
            // Moon
            let moon = SKShapeNode(circleOfRadius: 40)
            moon.fillColor = .lightGray
            moon.position = CGPoint(x: frame.maxX - 60, y: frame.maxY - 60)
            moon.name = "bg_element"
            addChild(moon)
        } else if level >= 6 {
            backgroundColor = SKColor(red: 1.0, green: 0.6, blue: 0.4, alpha: 1.0) // Sunset
            // Sun with sunglasses
            let sun = SKShapeNode(circleOfRadius: 50)
            sun.fillColor = .yellow
            sun.position = CGPoint(x: 80, y: frame.maxY - 80)
            sun.name = "bg_element"
            addChild(sun)
        } else {
            backgroundColor = SKColor(red: 0.25, green: 0.75, blue: 1.00, alpha: 1.0) // Day
            setupDayBackground()
        }
    }
    
    private func setupDayBackground() {
        let hill1 = SKShapeNode()
        let path1 = UIBezierPath()
        path1.move(to: CGPoint(x: 0, y: 0))
        path1.addLine(to: CGPoint(x: 0, y: frame.height * 0.25))
        path1.addQuadCurve(to: CGPoint(x: frame.width, y: frame.height * 0.15), controlPoint: CGPoint(x: frame.width * 0.5, y: frame.height * 0.35))
        path1.addLine(to: CGPoint(x: frame.width, y: 0))
        path1.close()
        hill1.path = path1.cgPath
        hill1.fillColor = SKColor(red: 0.4, green: 0.8, blue: 0.4, alpha: 1.0)
        hill1.strokeColor = .clear
        hill1.zPosition = -4
        hill1.name = "bg_element"
        addChild(hill1)
        
        for _ in 0..<4 { spawnCloud() }
    }
    
    private func spawnCloud() {
        let cloudContainer = SKNode()
        cloudContainer.name = "bg_element"
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
    
    private func performCustomDoorOpening(with texture: SKTexture) {
        let leftRect = CGRect(x: 0, y: 0, width: 0.5, height: 1.0)
        let rightRect = CGRect(x: 0.5, y: 0, width: 0.5, height: 1.0)
        
        let leftDoor = SKSpriteNode(texture: SKTexture(rect: leftRect, in: texture))
        leftDoor.size = CGSize(width: frame.width / 2, height: frame.height)
        leftDoor.anchorPoint = CGPoint(x: 1, y: 0.5)
        leftDoor.position = CGPoint(x: frame.midX, y: frame.midY)
        leftDoor.zPosition = 1000
        addChild(leftDoor)
        
        let rightDoor = SKSpriteNode(texture: SKTexture(rect: rightRect, in: texture))
        rightDoor.size = CGSize(width: frame.width / 2, height: frame.height)
        rightDoor.anchorPoint = CGPoint(x: 0, y: 0.5)
        rightDoor.position = CGPoint(x: frame.midX, y: frame.midY)
        rightDoor.zPosition = 1000
        addChild(rightDoor)
        
        let dist = frame.width / 2
        let p1D = dist * 0.3; let p1T = 0.3
        let p2D = dist * 0.1; let p2T = 1.0
        let p3D = dist * 0.6; let p3T = 0.2
        
        let leftSeq = SKAction.sequence([SKAction.moveBy(x: -p1D, y: 0, duration: p1T), SKAction.moveBy(x: -p2D, y: 0, duration: p2T), SKAction.moveBy(x: -p3D, y: 0, duration: p3T), SKAction.removeFromParent()])
        let rightSeq = SKAction.sequence([SKAction.moveBy(x: p1D, y: 0, duration: p1T), SKAction.moveBy(x: p2D, y: 0, duration: p2T), SKAction.moveBy(x: p3D, y: 0, duration: p3T), SKAction.removeFromParent()])
        
        leftDoor.run(leftSeq)
        rightDoor.run(rightSeq) { [weak self] in self?.startNewRound() }
    }
    
    // MARK: - Core Game Loop
    private func startNewRound() {
        selectionTimer?.invalidate()
        timerOverlay?.removeAllActions()
        timerOverlay?.alpha = 1
        timerOverlay?.fillColor = .clear
        timerOverlay?.lineWidth = 0
        userSequence = []
        currentSequence = []
        isAcceptingInput = false
        buttonNodes.forEach { $0.removeFromParent() }
        buttonNodes.removeAll()
        
        // --- BOSS CHECK ---
        if level % 5 == 0 {
            startBossRound()
            return
        }
        
        isBossLevel = false
        bossNode?.removeFromParent()
        levelLabel.text = "LEVEL \(level)"
        if let shadow = levelLabel.children.first as? SKLabelNode { shadow.text = "LEVEL \(level)" }
        
        updateEnvironment() // Update background if needed
        
        let config = getLevelConfig(for: level)
        activeEmojiPool = Array(masterEmojiPool.shuffled().prefix(config.poolSize))
        
        for _ in 0..<sequenceCount {
            if let randomEmoji = activeEmojiPool.randomElement() {
                currentSequence.append(randomEmoji)
            }
        }
        
        runCountdown(from: 3, then: { [weak self] in self?.showSequence() })
    }
    
    // MARK: - Boss Battle
    private func startBossRound() {
        isBossLevel = true
        bossRound = 0
        
        levelLabel.text = "BOSS BATTLE!"
        levelLabel.fontColor = .systemRed
        
        // Spawn Boss
        let boss = SKLabelNode(text: "👹")
        boss.fontSize = 150
        boss.position = CGPoint(x: frame.midX, y: frame.maxY - 200)
        boss.zPosition = 10
        boss.name = "boss"
        addChild(boss)
        bossNode = boss
        
        let shake = SKAction.sequence([SKAction.rotate(byAngle: 0.1, duration: 0.1), SKAction.rotate(byAngle: -0.2, duration: 0.1), SKAction.rotate(byAngle: 0.1, duration: 0.1)])
        boss.run(SKAction.repeatForever(shake))
        
        startNextBossPhase()
    }
    
    private func startNextBossPhase() {
        if bossRound >= 3 {
            // Boss Defeated
            bossNode?.run(SKAction.sequence([
                SKAction.scale(to: 0, duration: 0.5),
                SKAction.removeFromParent()
            ]))
            levelUp()
            return
        }
        
        userSequence = []
        currentSequence = []
        buttonNodes.forEach { $0.removeFromParent() }
        buttonNodes.removeAll()
        
        activeEmojiPool = Array(masterEmojiPool.shuffled().prefix(12)) // Fixed pool for boss
        
        // Generate Sequence
        for _ in 0..<4 { // Fixed length 4 for boss phases
            if let randomEmoji = activeEmojiPool.randomElement() {
                currentSequence.append(randomEmoji)
            }
        }
        
        runCountdown(from: 2, textOverride: "ATTACK \(bossRound + 1)!", then: { [weak self] in self?.showSequence() })
    }
    
    // MARK: - UI & Input Setup
    private func setupOverlays() {
        let cornerRadius: CGFloat = (view?.safeAreaInsets.bottom ?? 0) > 0 ? 44 : 0
        let rect = frame
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        
        timerOverlay = SKShapeNode(path: path.cgPath)
        timerOverlay?.position = .zero
        timerOverlay?.fillColor = .clear
        timerOverlay?.strokeColor = .systemYellow
        timerOverlay?.lineWidth = 0
        timerOverlay?.zPosition = 500
        addChild(timerOverlay!)
        
        flashOverlay = SKShapeNode(rectOf: self.size)
        flashOverlay?.position = CGPoint(x: frame.midX, y: frame.midY)
        flashOverlay?.fillColor = .systemRed
        flashOverlay?.strokeColor = .clear
        flashOverlay?.alpha = 0
        flashOverlay?.zPosition = 100
        addChild(flashOverlay!)
    }
    
    private func setupStage() {
        let size = CGSize(width: frame.width * 0.8, height: frame.width * 0.6)
        let shadow = SKShapeNode(rectOf: size, cornerRadius: 40)
        shadow.fillColor = .black.withAlphaComponent(0.3)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: frame.midX + 10, y: frame.midY + 110)
        shadow.zPosition = -1
        addChild(shadow)
        
        stageNode = SKShapeNode(rectOf: size, cornerRadius: 40)
        stageNode.fillColor = .white.withAlphaComponent(0.9)
        stageNode.strokeColor = SKColor(red: 0.25, green: 0.75, blue: 1.00, alpha: 1.0)
        stageNode.lineWidth = 8
        stageNode.position = CGPoint(x: frame.midX, y: frame.midY + 120)
        addChild(stageNode)
    }
    
    private func setupBaseUI() {
        let safeTop = view?.safeAreaInsets.top ?? 50
        for i in 0..<3 {
            let container = SKNode()
            container.position = CGPoint(x: 60 + (i * 60), y: Int(frame.maxY - safeTop - 50))
            addChild(container)
            let hShadow = SKLabelNode(text: "❤️")
            hShadow.fontSize = 35
            hShadow.fontColor = .black.withAlphaComponent(0.2)
            hShadow.position = CGPoint(x: 3, y: -3)
            container.addChild(hShadow)
            let heart = SKLabelNode(text: "❤️")
            heart.fontSize = 35
            heart.position = .zero
            container.addChild(heart)
            heartNodes.append(container)
        }
        
        timerLabel.fontSize = 50
        timerLabel.fontColor = .white
        let timerShadow = SKLabelNode(fontNamed: "Gameplay")
        timerShadow.text = "0"
        timerShadow.fontSize = 50
        timerShadow.fontColor = .black.withAlphaComponent(0.5)
        timerShadow.zPosition = -1
        timerShadow.position = CGPoint(x: 2, y: -2)
        timerShadow.name = "timerShadow"
        timerLabel.addChild(timerShadow)
        timerLabel.position = CGPoint(x: frame.maxX - 60, y: frame.maxY - safeTop - 50)
        timerLabel.alpha = 0
        timerLabel.zPosition = 50
        addChild(timerLabel)
        
        countdownLabel.fontSize = 80
        countdownLabel.fontColor = .systemYellow
        countdownLabel.position = CGPoint(x: frame.midX, y: frame.midY + 120)
        countdownLabel.zPosition = 20
        addChild(countdownLabel)
        
        centerDisplayLabel.fontSize = 112
        centerDisplayLabel.position = .zero
        centerDisplayLabel.alpha = 0
        stageNode.addChild(centerDisplayLabel)
        
        levelLabel.text = "LEVEL \(level)"
        levelLabel.fontSize = 32
        levelLabel.fontColor = .white
        let levelShadow = SKLabelNode(fontNamed: "Gameplay")
        levelShadow.text = "LEVEL \(level)"
        levelShadow.fontSize = 32
        levelShadow.fontColor = .black.withAlphaComponent(0.5)
        levelShadow.zPosition = -1
        levelShadow.position = CGPoint(x: 2, y: -2)
        levelLabel.addChild(levelShadow)
        levelLabel.position = CGPoint(x: frame.midX, y: stageNode.position.y - stageNode.frame.height/2 - 40)
        addChild(levelLabel)
        
        // --- CHEAT BUTTON (TESTING ONLY) ---
        let cheatBtn = SKLabelNode(fontNamed: "Gameplay")
        cheatBtn.text = "LVL++"
        cheatBtn.fontSize = 20
        cheatBtn.fontColor = .systemRed
        cheatBtn.position = CGPoint(x: frame.maxX - 80, y: 100) // Bottom right
        cheatBtn.name = "cheat_lvl_up"
        cheatBtn.zPosition = 999
        addChild(cheatBtn)
    }
    
    private func updateLivesUI() {
        for (index, node) in heartNodes.enumerated() {
            if let heart = node.children.last as? SKLabelNode {
                heart.text = index < lives ? "❤️" : "🖤"
                node.alpha = index < lives ? 1.0 : 0.4
            }
        }
    }
    
    private func setupInputButtons() {
        isAcceptingInput = true
        remainingTime = isBossLevel ? 10 : (7 * level) // Shorter time for boss
        updateTimerVisuals()
        
        selectionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.remainingTime -= 1
            self.updateTimerVisuals()
            if self.remainingTime <= 0 { self.timeUp() }
        }
        
        let config = getLevelConfig(for: level)
        let count = activeEmojiPool.count
        let cols = 5
        let rows = Int(ceil(Double(count) / Double(cols)))
        var btnSize: CGFloat = frame.width * 0.14
        if count > 15 { btnSize = frame.width * 0.12 }
        let spacing: CGFloat = 12
        let totalWidth = CGFloat(cols) * (btnSize + spacing) - spacing
        let totalHeight = CGFloat(rows) * (btnSize + spacing) - spacing
        let centerY = frame.height * 0.32
        let startX = frame.midX - totalWidth / 2 + btnSize / 2
        let startY = centerY + totalHeight / 2 - btnSize / 2
        
        // Use Selected Skin
        let skin = GameManager.shared.selectedSkin
        
        for i in 0..<activeEmojiPool.count {
            let container = SKNode()
            let col = i % cols
            let row = i / cols
            container.position = CGPoint(x: startX + CGFloat(col) * (btnSize + spacing), y: startY - CGFloat(row) * (btnSize + spacing))
            container.name = activeEmojiPool[i]
            
            // Container for physics (needed for Space level)
            if level >= 16 {
                let physBody = SKPhysicsBody(circleOfRadius: btnSize/2)
                physBody.affectedByGravity = false // We'll move them manually or let them float
                physBody.linearDamping = 0.5
                physBody.restitution = 0.8
                container.physicsBody = physBody
                // Apply random push for space
                container.physicsBody?.applyImpulse(CGVector(dx: CGFloat.random(in: -5...5), dy: CGFloat.random(in: -5...5)))
            }
            
            let shadow = SKShapeNode(circleOfRadius: btnSize/2)
            shadow.fillColor = .black.withAlphaComponent(0.3)
            shadow.strokeColor = .clear
            shadow.position = CGPoint(x: 0, y: -6)
            container.addChild(shadow)
            
            let body = SKShapeNode(circleOfRadius: btnSize/2)
            body.fillColor = skin.primaryColor
            body.strokeColor = skin.strokeColor
            body.lineWidth = 4
            body.name = "btn_body"
            container.addChild(body)
            
            let label = SKLabelNode(text: activeEmojiPool[i])
            label.fontSize = btnSize * 0.6
            label.verticalAlignmentMode = .center
            label.zPosition = 1
            label.name = activeEmojiPool[i]
            container.addChild(label)
            
            addChild(container)
            buttonNodes.append(container)
            container.setScale(0)
            container.run(SKAction.scale(to: 1.0, duration: 0.3))
            
            // --- Effects & Movement (Standard Levels) ---
            if !isBossLevel && level < 16 { // Disable standard movement for space/boss if needed, or adapt
                switch config.specialEffect {
                case .ghost:
                    container.run(SKAction.repeatForever(SKAction.sequence([SKAction.fadeAlpha(to: 0.2, duration: 1.0), SKAction.fadeAlpha(to: 1.0, duration: 1.0)])))
                case .spin:
                    container.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi*2, duration: 4.0)))
                    label.run(SKAction.repeatForever(SKAction.rotate(byAngle: -.pi*2, duration: 4.0)))
                case .pulse:
                    container.run(SKAction.repeatForever(SKAction.sequence([SKAction.scale(to: 1.1, duration: 0.6), SKAction.scale(to: 0.9, duration: 0.6)])))
                case .none: break
                }
                
                switch config.movementType {
                case .slow, .moderate, .fast:
                     let speed = (config.movementType == .slow) ? 2.5 : ((config.movementType == .moderate) ? 1.5 : 0.8)
                     let d = CGFloat.random(in: 20...50)
                     container.run(SKAction.repeatForever(SKAction.sequence([SKAction.moveBy(x: d, y: 0, duration: speed), SKAction.moveBy(x: -d*2, y: 0, duration: speed*2), SKAction.moveBy(x: d, y: 0, duration: speed)])))
                case .wander:
                     let p = CGMutablePath(); p.move(to: .zero)
                     for _ in 0..<4 { p.addLine(to: CGPoint(x: CGFloat.random(in: -30...30), y: CGFloat.random(in: -30...30))) }
                     p.closeSubpath()
                     container.run(SKAction.repeatForever(SKAction.follow(p, asOffset: true, orientToPath: false, speed: 40)))
                default: break
                }
            }
        }
    }
    
    private func runCountdown(from: Int, textOverride: String? = nil, then completion: @escaping () -> Void) {
        var count = from
        countdownLabel.alpha = 1
        let update = SKAction.run { [weak self] in
            guard let self = self else { return }
            if count > 0 {
                self.countdownLabel.text = "\(count)"
                self.countdownLabel.fontColor = (count == 1) ? .systemRed : .systemYellow
                self.playSound("tick.mp3")
                self.countdownLabel.setScale(0)
                self.countdownLabel.zRotation = -0.5
                let appear = SKAction.group([SKAction.scale(to: 1.2, duration: 0.2), SKAction.rotate(byAngle: 0.6, duration: 0.2), SKAction.fadeIn(withDuration: 0.1)])
                self.countdownLabel.run(SKAction.sequence([appear, SKAction.sequence([SKAction.scale(to: 1.0, duration: 0.1), SKAction.rotate(toAngle: 0, duration: 0.1)])]))
                count -= 1
            } else {
                self.countdownLabel.text = textOverride ?? "GO!"
                self.countdownLabel.fontColor = .systemGreen
                self.playSound("go.mp3")
                self.countdownLabel.setScale(1.5)
                self.countdownLabel.run(SKAction.group([SKAction.scale(to: 1.0, duration: 0.3), SKAction.fadeOut(withDuration: 0.5)]))
            }
        }
        let sequence = SKAction.sequence([update, SKAction.wait(forDuration: 1.0)])
        countdownLabel.run(SKAction.repeat(sequence, count: from + 1)) { completion() }
    }
    
    private func showSequence() {
        var delay = 0.5
        for emoji in currentSequence {
            let wait = SKAction.wait(forDuration: delay)
            let show = SKAction.run { [weak self] in
                guard let self = self else { return }
                self.centerDisplayLabel.text = emoji
                self.centerDisplayLabel.alpha = 1
                self.centerDisplayLabel.setScale(0.5)
                self.centerDisplayLabel.run(SKAction.scale(to: 1.0, duration: 0.2))
                self.stageNode.run(SKAction.sequence([SKAction.scale(to: 1.05, duration: 0.1), SKAction.scale(to: 1.0, duration: 0.1)]))
                self.playSound("pop.mp3")
            }
            let hideWait = SKAction.wait(forDuration: 0.8)
            let fade = SKAction.run { [weak self] in self?.centerDisplayLabel.alpha = 0 }
            run(SKAction.sequence([wait, show, hideWait, fade]))
            delay += 1.2
        }
        run(SKAction.wait(forDuration: delay)) { [weak self] in
            self?.runCountdown(from: 2, textOverride: "GO!", then: { self?.setupInputButtons() })
        }
    }
    
    // MARK: - Input & Verification
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = nodes(at: location)
        
        // Menu handling (Game Over)
        for node in nodes {
            if node.name == "btn_menu" {
                transitionToMenu()
                return
            } else if node.name == "restart_trigger_node" {
                restartGame()
                return
            } else if node.name == "cheat_lvl_up" { // CHEAT HANDLE
                levelUp()
                return
            }
        }
        
        guard isAcceptingInput else { return }
        
        for node in nodes {
            let parent = node.name == "btn_body" ? node.parent : node
            if let name = parent?.name, activeEmojiPool.contains(name) {
                hapticFeedback.impactOccurred()
                handleInput(emoji: name, node: parent!)
                break
            }
        }
    }
    
    private func handleInput(emoji: String, node: SKNode) {
        userSequence.append(emoji)
        playSound("tap.mp3")
        
        // Fever Logic
        let now = Date().timeIntervalSince1970
        if now - lastTapTime < 0.5 {
            comboCount += 1
            if comboCount > 3 {
                // Fever Effect
                let fire = SKShapeNode(circleOfRadius: 10)
                fire.fillColor = .orange
                fire.strokeColor = .red
                fire.position = node.position
                addChild(fire)
                fire.run(SKAction.sequence([SKAction.moveBy(x: 0, y: 50, duration: 0.5), SKAction.fadeOut(withDuration: 0.5), SKAction.removeFromParent()]))
            }
        } else {
            comboCount = 0
        }
        lastTapTime = now
        
        // Button Anim
        let press = SKAction.group([SKAction.scaleX(to: 1.2, y: 0.8, duration: 0.1), SKAction.moveBy(x: 0, y: -5, duration: 0.1)])
        let release = SKAction.group([SKAction.scale(to: 1.0, duration: 0.1), SKAction.moveBy(x: 0, y: 5, duration: 0.1)])
        node.run(SKAction.sequence([press, release]))
        
        if userSequence.count == currentSequence.count {
            isAcceptingInput = false
            selectionTimer?.invalidate()
            timerLabel.run(SKAction.fadeOut(withDuration: 0.3))
            timerOverlay?.run(SKAction.fadeOut(withDuration: 0.3))
            runCountdown(from: 1, textOverride: "...", then: { [weak self] in self?.verifyResults() })
        }
    }
    
    private func verifyResults() {
        var allCorrect = true
        for i in 0..<currentSequence.count {
            if userSequence[i] != currentSequence[i] { allCorrect = false; break }
        }
        
        var delay = 0.0
        for i in 0..<currentSequence.count {
            let wait = SKAction.wait(forDuration: delay)
            let show = SKAction.run { [weak self] in
                guard let self = self else { return }
                let correct = self.userSequence[i] == self.currentSequence[i]
                self.centerDisplayLabel.text = self.currentSequence[i]
                self.centerDisplayLabel.fontColor = correct ? .systemGreen : .systemRed
                self.centerDisplayLabel.alpha = 1
                self.playSound(correct ? "correct.mp3" : "wrong.mp3")
                
                if let btn = self.buttonNodes.first(where: { $0.name == self.userSequence[i] }),
                   let body = btn.childNode(withName: "btn_body") as? SKShapeNode {
                    body.fillColor = correct ? .systemGreen : .systemRed
                    if !correct {
                        self.flashOverlay?.run(SKAction.sequence([SKAction.fadeAlpha(to: 0.7, duration: 0.1), SKAction.fadeAlpha(to: 0, duration: 0.2)]))
                    } else {
                         btn.run(SKAction.sequence([SKAction.scale(to: 1.4, duration: 0.1), SKAction.scale(to: 1.0, duration: 0.1)]))
                    }
                }
            }
            let hide = SKAction.sequence([SKAction.wait(forDuration: 0.5), SKAction.run { self.centerDisplayLabel.alpha = 0 }])
            run(SKAction.sequence([wait, show, hide]))
            delay += 0.7
        }
        
        run(SKAction.wait(forDuration: delay + 0.5)) { [weak self] in
            guard let self = self else { return }
            if allCorrect {
                // Score Calculation
                let roundScore = (self.level * 10) + (self.comboCount * 5)
                self.currentScore += roundScore
                GameManager.shared.totalCoins += roundScore // Coins = Score for now
                
                if self.isBossLevel {
                    self.bossRound += 1
                    self.startNextBossPhase()
                } else {
                    self.levelUp()
                }
            } else {
                self.loseLife()
            }
        }
    }
    
    private func levelUp() {
        level += 1
        playSound("level_up.mp3")
        notificationFeedback.notificationOccurred(.success)
        
        // Effects (Flash + Particles)
        let bgFlash = SKShapeNode(rectOf: size)
        bgFlash.fillColor = .white; bgFlash.alpha = 0; bgFlash.zPosition = 140
        bgFlash.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(bgFlash)
        bgFlash.run(SKAction.sequence([SKAction.fadeAlpha(to: 0.5, duration: 0.1), SKAction.fadeOut(withDuration: 0.3), SKAction.removeFromParent()]))
        
        for _ in 0..<20 {
            let conf = SKShapeNode(rectOf: CGSize(width: 10, height: 10))
            conf.fillColor = [.red, .yellow, .green, .blue, .purple].randomElement()!
            conf.strokeColor = .clear
            conf.position = CGPoint(x: frame.midX, y: frame.midY + 100)
            conf.zPosition = 145
            addChild(conf)
            let angle = CGFloat.random(in: 0...(.pi * 2)); let dist = CGFloat.random(in: 100...300)
            let dest = CGPoint(x: frame.midX + cos(angle) * dist, y: frame.midY + 100 + sin(angle) * dist)
            conf.run(SKAction.group([SKAction.move(to: dest, duration: 0.8), SKAction.rotate(byAngle: .pi*4, duration: 0.8), SKAction.fadeOut(withDuration: 0.8)])) { conf.removeFromParent() }
        }
        
        let congrats = SKLabelNode(fontNamed: "Gameplay")
        congrats.text = "LEVEL UP!"
        congrats.fontSize = 70; congrats.fontColor = .systemYellow
        let shadow = SKLabelNode(fontNamed: "Gameplay")
        shadow.text = "LEVEL UP!"; shadow.fontSize = 70; shadow.fontColor = .black; shadow.zPosition = -1; shadow.position = CGPoint(x: 4, y: -4)
        congrats.addChild(shadow)
        congrats.position = CGPoint(x: frame.midX, y: frame.midY + 100); congrats.zPosition = 150
        addChild(congrats)
        congrats.setScale(0)
        
        congrats.run(SKAction.sequence([
            SKAction.group([SKAction.scale(to: 1.2, duration: 0.2), SKAction.fadeIn(withDuration: 0.2)]),
            SKAction.scale(to: 1.0, duration: 0.1),
            SKAction.wait(forDuration: 1.2),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ])) { [weak self] in self?.startNewRound() }
    }
    
    private func loseLife(reason: String = "WHOOPS!") {
        lives -= 1
        updateLivesUI()
        let oops = SKLabelNode(fontNamed: "Gameplay")
        oops.text = reason
        oops.fontColor = .systemRed
        let shadow = SKLabelNode(fontNamed: "Gameplay")
        shadow.text = reason; shadow.fontSize = 60; shadow.fontColor = .black; shadow.zPosition = -1; shadow.position = CGPoint(x: 4, y: -4)
        oops.addChild(shadow)
        oops.fontSize = 60; oops.position = CGPoint(x: frame.midX, y: frame.midY + 100); oops.zPosition = 150
        addChild(oops)
        oops.setScale(0)
        oops.run(SKAction.sequence([
            SKAction.group([SKAction.scale(to: 1.0, duration: 0.3), SKAction.fadeIn(withDuration: 0.3)]),
            SKAction.wait(forDuration: 0.8),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ])) { [weak self] in
            if self?.lives ?? 0 <= 0 { self?.gameOver() } else { self?.startNewRound() }
        }
    }
    
    private func gameOver() {
        playSound("game_over.mp3")
        // Update High Score
        if currentScore > GameManager.shared.highScore {
            GameManager.shared.highScore = currentScore
        }
        
        let overNode = createCartoonBoard(size: CGSize(width: frame.width * 0.85, height: 350), color: .darkGray)
        overNode.position = CGPoint(x: frame.midX, y: frame.midY); overNode.zPosition = 200
        addChild(overNode)
        
        let overText = SKLabelNode(fontNamed: "Gameplay")
        overText.text = "THE END!"
        overText.fontSize = 50; overText.fontColor = .white; overText.position = CGPoint(x: 0, y: 100)
        overNode.addChild(overText)
        
        let scoreText = SKLabelNode(fontNamed: "Gameplay")
        scoreText.text = "SCORE: \(currentScore)"
        scoreText.fontSize = 30; scoreText.fontColor = .systemYellow; scoreText.position = CGPoint(x: 0, y: 50)
        overNode.addChild(scoreText)
        
        let restartBtn = createCartoonButton(text: "TRY AGAIN", color: .systemGreen, size: CGSize(width: 200, height: 60))
        restartBtn.position = CGPoint(x: 0, y: -20); restartBtn.name = "restart_trigger_node"
        overNode.addChild(restartBtn)
        
        let menuBtn = createCartoonButton(text: "MENU", color: .systemBlue, size: CGSize(width: 200, height: 60))
        menuBtn.position = CGPoint(x: 0, y: -90); menuBtn.name = "btn_menu"
        overNode.addChild(menuBtn)
        
        isAcceptingInput = false
    }
    
    // MARK: - Helpers
    private func updateTimerVisuals() {
        let maxTime = isBossLevel ? 10 : (7 * level)
        let progress = CGFloat(remainingTime) / CGFloat(maxTime)
        timerLabel.text = "\(remainingTime)"
        if let shadow = timerLabel.childNode(withName: "timerShadow") as? SKLabelNode { shadow.text = "\(remainingTime)" }
        timerLabel.run(SKAction.sequence([SKAction.scale(to: 1.2, duration: 0.1), SKAction.scale(to: 1.0, duration: 0.1)]))
        timerOverlay?.fillColor = SKColor.systemYellow.withAlphaComponent((1.0 - progress) * 0.35)
        timerOverlay?.lineWidth = (1.0 - progress) * 40
        if remainingTime <= 3 {
            timerLabel.fontColor = .systemRed; timerOverlay?.strokeColor = .systemRed
            timerLabel.run(SKAction.sequence([SKAction.scale(to: 1.5, duration: 0.1), SKAction.scale(to: 1.0, duration: 0.1)]))
            timerOverlay?.run(SKAction.repeat(SKAction.sequence([SKAction.moveBy(x: 5, y: 0, duration: 0.05), SKAction.moveBy(x: -5, y: 0, duration: 0.05)]), count: 2))
        } else {
            timerLabel.fontColor = .white; timerOverlay?.strokeColor = .systemYellow
        }
    }
    
    private func timeUp() {
        selectionTimer?.invalidate(); isAcceptingInput = false
        timerLabel.run(SKAction.fadeOut(withDuration: 0.3)); timerOverlay?.run(SKAction.fadeOut(withDuration: 0.3))
        playSound("wrong.mp3"); notificationFeedback.notificationOccurred(.error)
        loseLife(reason: "TOO SLOW!")
    }
    
    private func restartGame() {
        lives = 3; level = 1; currentScore = 0; comboCount = 0
        removeAllChildren()
        updateEnvironment()
        setupStage(); setupBaseUI(); setupOverlays()
        startNewRound()
    }
    
    private func transitionToMenu() {
        let menuScene = MenuScene(size: self.size)
        menuScene.scaleMode = .aspectFill
        let transition = SKTransition.doorsCloseHorizontal(withDuration: 0.8)
        self.view?.presentScene(menuScene, transition: transition)
    }
    
    private func createCartoonBoard(size: CGSize, color: SKColor) -> SKNode {
        let container = SKNode()
        let shadow = SKShapeNode(rectOf: size, cornerRadius: 35)
        shadow.fillColor = .black.withAlphaComponent(0.4); shadow.strokeColor = .clear; shadow.position = CGPoint(x: 8, y: -8)
        container.addChild(shadow)
        let body = SKShapeNode(rectOf: size, cornerRadius: 35)
        body.fillColor = color; body.strokeColor = .white; body.lineWidth = 6
        container.addChild(body)
        return container
    }
    
    private func createCartoonButton(text: String, color: SKColor, size: CGSize) -> SKNode {
        let container = SKNode()
        let shadow = SKShapeNode(rectOf: size, cornerRadius: 20)
        shadow.fillColor = .black.withAlphaComponent(0.4); shadow.strokeColor = .clear; shadow.position = CGPoint(x: 0, y: -6)
        container.addChild(shadow)
        let body = SKShapeNode(rectOf: size, cornerRadius: 20)
        body.fillColor = color; body.strokeColor = .white; body.lineWidth = 4; body.name = "btn_body"
        container.addChild(body)
        let label = SKLabelNode(fontNamed: "Gameplay")
        label.text = text; label.fontSize = 24; label.fontColor = .white; label.verticalAlignmentMode = .center; label.zPosition = 1
        container.addChild(label)
        return container
    }
    
    private func playSound(_ fileName: String) {
        run(SKAction.playSoundFileNamed(fileName, waitForCompletion: false))
    }
}