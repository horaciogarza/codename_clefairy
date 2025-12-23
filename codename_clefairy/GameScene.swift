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
    
    // Session Statistics for Summary
    private var totalTapPoints = 0
    private var totalBaseLevelPoints = 0
    private var totalSpeedBonusPoints = 0
    private var totalBossPoints = 0
    private var totalFrenzyMultiplierPoints = 0
    
    // Heat/Combo System
    private var heatValue: CGFloat = 0 // 0 to 1.0
    private var heatMeterNode: SKShapeNode?
    private var isFrenzyMode = false
    
    // Boss State
    private var isBossLevel = false
    private var bossRound = 0
    private var bossNode: SKLabelNode?
    
    // Visual Effects State
    private var jellyDripTimer: Timer?
    
    // Config
    private struct LevelConfig {
        let poolSize: Int
        let sequenceLength: Int
        let movementType: MovementType
        let specialEffect: SpecialEffect
    }

    private enum MovementType { case none, slow, moderate, fast, wander }
    private enum SpecialEffect { case none, ghost, spin, pulse }

    // MARK: - Level Logic
    private func getLevelConfig(for level: Int) -> LevelConfig {
        switch level {
        case 1...2: return LevelConfig(poolSize: 8, sequenceLength: level, movementType: .none, specialEffect: .none)
        case 3...4: return LevelConfig(poolSize: 10, sequenceLength: level, movementType: .none, specialEffect: .none)
        case 5: return LevelConfig(poolSize: 10, sequenceLength: 3, movementType: .none, specialEffect: .none)
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
        if isBossLevel { return 4 }
        return getLevelConfig(for: level).sequenceLength
    }
    
    // Use thematic emoji pool (holiday-aware)
    private var masterEmojiPool: [String] {
        return GameManager.shared.getActivePool(count: 30)
    }
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
        setupHeatMeter()
        
        Task { @MainActor in
            AdManager.shared.hideBanner()
            
            // Pause logic for Interstitials
            AdManager.shared.onAdWillPresent = { [weak self] in
                self?.isPaused = true
                self?.isAcceptingInput = false
            }
            
            AdManager.shared.onAdDidDismiss = { [weak self] in
                self?.isPaused = false
                self?.isAcceptingInput = true
            }
        }
        
        if let texture = doorTransitionTexture {
            performCustomDoorOpening(with: texture)
        } else {
            startNewRound()
        }
    }
    
    override func willMove(from view: SKView) {
        jellyDripTimer?.invalidate()
    }
    
    private func updateEnvironment() {
        children.filter { $0.name == "bg_element" }.forEach { $0.removeFromParent() }

        // Standard daylight theme
        backgroundColor = SKColor(red: 0.25, green: 0.75, blue: 1.00, alpha: 1.0)
        
        // Reactive background color based on frenzy
        if isFrenzyMode {
            backgroundColor = SKColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0)
        }

        // Add standard hills
        let ground = SKShapeNode()
        let groundPath = UIBezierPath()
        groundPath.move(to: CGPoint(x: 0, y: 0))
        groundPath.addLine(to: CGPoint(x: 0, y: frame.height * 0.2))
        groundPath.addQuadCurve(to: CGPoint(x: frame.width, y: frame.height * 0.15), controlPoint: CGPoint(x: frame.width * 0.5, y: frame.height * 0.3))
        groundPath.addLine(to: CGPoint(x: frame.width, y: 0))
        groundPath.close()
        ground.path = groundPath.cgPath
        ground.fillColor = isFrenzyMode ? .orange : SKColor(red: 0.4, green: 0.8, blue: 0.4, alpha: 1.0)
        ground.strokeColor = .clear
        ground.zPosition = -4
        ground.name = "bg_element"
        addChild(ground)

        // Add clouds - reactive count
        let cloudCount = isFrenzyMode ? 8 : 4
        for _ in 0..<cloudCount { spawnCloud() }
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

        let baseRadius: CGFloat = CGFloat.random(in: 20...35)
        let numPuffs = Int.random(in: 4...6)

        for i in 0..<numPuffs {
            let puffRadius = baseRadius * CGFloat.random(in: 0.6...1.0)
            let puff = SKShapeNode(circleOfRadius: puffRadius)
            puff.fillColor = .white
            puff.strokeColor = .clear
            let xPos = CGFloat(i) * baseRadius * 0.8
            let yPos = CGFloat.random(in: -baseRadius * 0.2...baseRadius * 0.2)
            puff.position = CGPoint(x: xPos, y: yPos)
            cloudContainer.addChild(puff)
        }

        for i in 0..<(numPuffs - 1) {
            let puffRadius = baseRadius * CGFloat.random(in: 0.5...0.8)
            let puff = SKShapeNode(circleOfRadius: puffRadius)
            puff.fillColor = .white
            puff.strokeColor = .clear
            let xPos = CGFloat(i) * baseRadius * 0.8 + baseRadius * 0.4
            let yPos = baseRadius * CGFloat.random(in: 0.4...0.7)
            puff.position = CGPoint(x: xPos, y: yPos)
            cloudContainer.addChild(puff)
        }

        cloudContainer.alpha = CGFloat.random(in: 0.7...0.9)
        cloudContainer.position = CGPoint(x: CGFloat.random(in: -100...frame.width), y: CGFloat.random(in: frame.midY...frame.maxY - 100))
        cloudContainer.zPosition = -6
        addChild(cloudContainer)

        // Reactive cloud speed
        let baseDuration = Double.random(in: 40...80)
        let duration = isFrenzyMode ? baseDuration / 4 : baseDuration
        
        let move = SKAction.moveBy(x: frame.width + 300, y: 0, duration: duration)
        let reset = SKAction.moveBy(x: -(frame.width + 500), y: 0, duration: 0)
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
        
        if level % 5 == 0 { startBossRound(); return }
        
        isBossLevel = false
        bossNode?.removeFromParent()
        
        let modeSuffix = GameManager.shared.currentMode == .zen ? " (ZEN)" : ""
        levelLabel.text = "LEVEL \(level)\(modeSuffix)"
        if let shadow = levelLabel.children.first as? SKLabelNode { shadow.text = levelLabel.text }
        
        updateEnvironment()
        let config = getLevelConfig(for: level)
        activeEmojiPool = Array(masterEmojiPool.shuffled().prefix(config.poolSize))
        for _ in 0..<sequenceCount { if let randomEmoji = activeEmojiPool.randomElement() { currentSequence.append(randomEmoji) } }
        runCountdown(from: 3, then: { [weak self] in self?.showSequence() })
    }
    
    private func startBossRound() {
        isBossLevel = true
        bossRound = 0

        // Dramatic screen flash
        let flashOverlayBoss = SKShapeNode(rectOf: self.size)
        flashOverlayBoss.position = CGPoint(x: frame.midX, y: frame.midY)
        flashOverlayBoss.fillColor = .red
        flashOverlayBoss.strokeColor = .clear
        flashOverlayBoss.alpha = 0
        flashOverlayBoss.zPosition = 200
        addChild(flashOverlayBoss)

        flashOverlayBoss.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.4, duration: 0.1),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))

        // Warning text
        let warningLabel = SKLabelNode(fontNamed: "Gameplay")
        warningLabel.text = "⚠️ BOSS INCOMING ⚠️"
        warningLabel.fontSize = 28
        warningLabel.fontColor = .systemRed
        warningLabel.position = CGPoint(x: frame.midX, y: frame.midY + 200)
        warningLabel.zPosition = 150
        warningLabel.alpha = 0
        addChild(warningLabel)

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
        run(SKAction.wait(forDuration: 1.5)) { [weak self] in
            guard let self = self else { return }

            self.levelLabel.text = "BOSS BATTLE!"
            self.levelLabel.fontColor = .systemRed
            if let shadow = self.levelLabel.children.first as? SKLabelNode {
                shadow.text = "BOSS BATTLE!"
            }

            // Create boss with dramatic entrance
            let boss = SKLabelNode(text: "🐙")
            boss.fontSize = 142.5 // Reduced by 5% from 150
            boss.position = CGPoint(x: self.frame.midX, y: self.frame.maxY + 150)
            boss.zPosition = 10
            boss.name = "boss"
            boss.setScale(0.3)
            self.addChild(boss)
            self.bossNode = boss

            // Entrance animation - slam down
            let targetY = self.frame.maxY - 200
            let dropDown = SKAction.move(to: CGPoint(x: self.frame.midX, y: targetY), duration: 0.5)
            dropDown.timingMode = .easeIn
            let scaleUp = SKAction.scale(to: 1.0, duration: 0.5)
            let impact = SKAction.run { [weak self] in
                guard let self = self else { return }
                // Screen shake
                let shake = SKAction.sequence([
                    SKAction.moveBy(x: 10, y: 0, duration: 0.05),
                    SKAction.moveBy(x: -20, y: 0, duration: 0.05),
                    SKAction.moveBy(x: 15, y: -5, duration: 0.05),
                    SKAction.moveBy(x: -10, y: 5, duration: 0.05),
                    SKAction.moveBy(x: 5, y: 0, duration: 0.05)
                ])
                self.stageNode.run(shake)
                self.playSound("boss_appear.mp3")

                // Impact particles
                for _ in 0..<12 {
                    let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 5...12))
                    particle.fillColor = [SKColor.red, SKColor.orange, SKColor.yellow].randomElement()!
                    particle.strokeColor = .clear
                    particle.position = CGPoint(x: self.frame.midX, y: targetY - 50)
                    particle.zPosition = 9
                    self.addChild(particle)

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

            boss.run(SKAction.sequence([
                SKAction.group([dropDown, scaleUp]),
                impact
            ])) {
                // Idle wobble after entrance
                let wobble = SKAction.sequence([
                    SKAction.scaleX(to: 1.1, y: 0.9, duration: 0.5),
                    SKAction.scaleX(to: 0.9, y: 1.1, duration: 0.5)
                ])
                boss.run(SKAction.repeatForever(wobble))
                self.startNextBossPhase()
            }
        }
    }
    
    private func startNextBossPhase() {
        if bossRound >= 3 {
            bossNode?.run(SKAction.sequence([SKAction.scale(to: 0, duration: 0.5), SKAction.removeFromParent()]))
            levelUp()
            return
        }
        userSequence = []
        currentSequence = []
        buttonNodes.forEach { $0.removeFromParent() }
        buttonNodes.removeAll()
        activeEmojiPool = Array(masterEmojiPool.shuffled().prefix(12))
        for _ in 0..<4 { if let randomEmoji = activeEmojiPool.randomElement() { currentSequence.append(randomEmoji) } }
        runCountdown(from: 2, textOverride: "ATTACK \(bossRound + 1)!", then: { [weak self] in self?.showSequence() })
    }
    
    // MARK: - UI & Input Setup
    private func setupOverlays() {
        // Modern iPhone corner radius approximation (iPhone 16/17 etc)
        let cornerRadius: CGFloat = 55.0 
        timerOverlay = SKShapeNode(path: UIBezierPath(roundedRect: frame, cornerRadius: cornerRadius).cgPath)
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
        let shiftY = self.size.height * 0.05 // Rollback to 5%
        
        // Remove old stage components
        stageNode?.removeFromParent()
        jellyDripTimer?.invalidate()
        
        // Shadow
        let shadow = SKShapeNode(rectOf: size, cornerRadius: 40)
        shadow.fillColor = .black.withAlphaComponent(0.3)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: frame.midX + 10, y: frame.midY + 110 - shiftY)
        shadow.zPosition = -1
        addChild(shadow)
        
        stageNode = SKShapeNode(rectOf: size, cornerRadius: 40)
        stageNode.fillColor = .white.withAlphaComponent(0.9)
        stageNode.strokeColor = SKColor(red: 0.25, green: 0.75, blue: 1.00, alpha: 1.0)
        stageNode.lineWidth = 8
        stageNode.position = CGPoint(x: frame.midX, y: frame.midY + 120 - shiftY)
        addChild(stageNode)
    }
    
    private func setupBaseUI() {
        let safeTop = view?.safeAreaInsets.top ?? 50

        // Hearts container with background - ALIGNED LEFT
        let heartsContainer = SKNode()
        heartsContainer.position = CGPoint(x: 100, y: frame.maxY - safeTop - 40)
        heartsContainer.zPosition = 50
        addChild(heartsContainer)

        // Subtle background pill for hearts
        let heartsBg = SKShapeNode(rectOf: CGSize(width: 160, height: 50), cornerRadius: 25)
        heartsBg.fillColor = .white.withAlphaComponent(0.85)
        heartsBg.strokeColor = SKColor(red: 1.0, green: 0.4, blue: 0.5, alpha: 0.8)
        heartsBg.lineWidth = 3
        heartsContainer.addChild(heartsBg)

        for i in 0..<3 {
            let container = SKNode()
            container.position = CGPoint(x: -50 + (i * 50), y: 0)
            heartsContainer.addChild(container)

            // Shadow
            let hShadow = SKLabelNode(text: "❤️")
            hShadow.fontSize = 32
            hShadow.alpha = 0.2
            hShadow.position = CGPoint(x: 2, y: -2)
            hShadow.zPosition = -1
            hShadow.verticalAlignmentMode = .center
            container.addChild(hShadow)

            // Heart
            let heart = SKLabelNode(text: "❤️")
            heart.fontSize = 32
            heart.position = .zero
            heart.name = "heart_icon"
            heart.verticalAlignmentMode = .center
            container.addChild(heart)

            heartNodes.append(container)

            // Subtle heartbeat animation with stagger
            let delay = SKAction.wait(forDuration: Double(i) * 0.15)
            let beat = SKAction.sequence([
                SKAction.scale(to: 1.15, duration: 0.15),
                SKAction.scale(to: 1.0, duration: 0.15),
                SKAction.wait(forDuration: 0.5)
            ])
            container.run(SKAction.sequence([delay, SKAction.repeatForever(beat)]))
        }
        
        timerLabel.fontSize = 50; timerLabel.fontColor = .white
        let timerShadow = SKLabelNode(fontNamed: "Gameplay"); timerShadow.text = "0"; timerShadow.fontSize = 50; timerShadow.fontColor = .black.withAlphaComponent(0.5); timerShadow.zPosition = -1; timerShadow.position = CGPoint(x: 2, y: -2); timerShadow.name = "timerShadow"
        timerLabel.addChild(timerShadow)
        timerLabel.position = CGPoint(x: frame.maxX - 60, y: heartsContainer.position.y - 70); timerLabel.zPosition = 50; addChild(timerLabel)
        
        // Countdown Label - ALIGNED RIGHT
        countdownLabel.fontSize = 60; countdownLabel.fontColor = .systemYellow; 
        countdownLabel.position = CGPoint(x: frame.maxX - 100, y: heartsContainer.position.y); 
        countdownLabel.verticalAlignmentMode = .center
        countdownLabel.zPosition = 20; addChild(countdownLabel)
        
        centerDisplayLabel.fontSize = 112; centerDisplayLabel.position = .zero; 
        centerDisplayLabel.verticalAlignmentMode = .center
        centerDisplayLabel.alpha = 0; stageNode.addChild(centerDisplayLabel)
        
        levelLabel.text = "LEVEL \(level)"; levelLabel.fontSize = 32; levelLabel.fontColor = .white
        let levelShadow = SKLabelNode(fontNamed: "Gameplay"); levelShadow.text = "LEVEL \(level)"; levelShadow.fontSize = 32; levelShadow.fontColor = .black.withAlphaComponent(0.5); levelShadow.zPosition = -1; levelShadow.position = CGPoint(x: 2, y: -2)
        levelLabel.addChild(levelShadow)
        levelLabel.position = CGPoint(x: frame.midX, y: stageNode.position.y - stageNode.frame.height/2 - 40); addChild(levelLabel)
        
    }
    
    private func updateLivesUI() {
        let isZen = GameManager.shared.currentMode == .zen
        
        for (index, node) in heartNodes.enumerated() {
            if let heart = node.childNode(withName: "heart_icon") as? SKLabelNode {
                let isAlive = isZen || index < lives
                heart.text = isAlive ? "❤️" : "🖤"
                node.alpha = isAlive ? 1.0 : 0.35

                if isAlive {
                    if node.action(forKey: "heartbeat") == nil {
                        let beat = SKAction.sequence([
                            SKAction.scale(to: 1.15, duration: 0.15),
                            SKAction.scale(to: 1.0, duration: 0.15),
                            SKAction.wait(forDuration: 0.5)
                        ])
                        node.run(SKAction.repeatForever(beat), withKey: "heartbeat")
                    }
                } else {
                    node.removeAction(forKey: "heartbeat")
                    node.setScale(1.0)
                }
            }
        }
    }
    
    private func setupHeatMeter() {
        let safeTop = view?.safeAreaInsets.top ?? 50
        let shiftY = size.height * 0.05 // Rollback to 5%
        
        // Meter background
        let meterWidth: CGFloat = 120
        let meterHeight: CGFloat = 12
        let bg = SKShapeNode(rectOf: CGSize(width: meterWidth, height: meterHeight), cornerRadius: 6)
        bg.fillColor = .black.withAlphaComponent(0.3)
        bg.strokeColor = .white
        bg.lineWidth = 1
        bg.position = CGPoint(x: frame.midX, y: frame.maxY - safeTop - 80 - shiftY)
        bg.zPosition = 50
        addChild(bg)
        
        // Progress bar
        let progress = SKShapeNode(rectOf: CGSize(width: meterWidth - 2, height: meterHeight - 2), cornerRadius: 5)
        progress.fillColor = .systemYellow
        progress.strokeColor = .clear
        progress.position = CGPoint(x: 0, y: 0)
        progress.xScale = 0.01 // Start empty
        progress.name = "heat_progress"
        bg.addChild(progress)
        
        heatMeterNode = progress
        
        let label = SKLabelNode(fontNamed: "Gameplay")
        label.text = "FRENZY"
        label.fontSize = 10
        label.fontColor = .white
        label.position = CGPoint(x: 0, y: 10)
        bg.addChild(label)
    }
    
    private func updateHeatMeter() {
        let color: SKColor = isFrenzyMode ? .systemRed : .systemYellow
        heatMeterNode?.fillColor = color
        
        let targetScale = max(0.01, heatValue)
        let scale = SKAction.scaleX(to: targetScale, duration: 0.2)
        heatMeterNode?.run(scale)
        
        if heatValue >= 1.0 && !isFrenzyMode {
            startFrenzy()
        }
    }
    
    private func startFrenzy() {
        isFrenzyMode = true
        playSound("frenzy.mp3")
        updateEnvironment()
        
        let flash = SKAction.repeat(SKAction.sequence([
            SKAction.run { [weak self] in self?.backgroundColor = .white },
            SKAction.wait(forDuration: 0.05),
            SKAction.run { [weak self] in self?.updateEnvironment() },
            SKAction.wait(forDuration: 0.05)
        ]), count: 3)
        run(flash)
        
        run(SKAction.wait(forDuration: 10.0)) { [weak self] in
            self?.endFrenzy()
        }
    }
    
    private func endFrenzy() {
        isFrenzyMode = false
        heatValue = 0
        updateEnvironment()
        updateHeatMeter()
    }
    
    private func setupInputButtons() {
        isAcceptingInput = true
        
        // Zen Mode: No timer
        if GameManager.shared.currentMode == .classic {
            remainingTime = isBossLevel ? 10 : (7 * level)
            updateTimerVisuals()
            
            selectionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.remainingTime -= 1
                self.updateTimerVisuals()
                if self.remainingTime <= 0 { self.timeUp() }
            }
        } else {
            timerLabel.text = "∞"
            if let shadow = timerLabel.childNode(withName: "timerShadow") as? SKLabelNode { shadow.text = "∞" }
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
        let shiftY = size.height * 0.05 // Rollback to 5%
        let centerY = frame.height * 0.32 - shiftY
        let startX = frame.midX - totalWidth / 2 + btnSize / 2
        let startY = centerY + totalHeight / 2 - btnSize / 2
        
        for i in 0..<activeEmojiPool.count {
            let container = SKNode()
            let col = i % cols
            let row = i / cols
            container.position = CGPoint(x: startX + CGFloat(col) * (btnSize + spacing), y: startY - CGFloat(row) * (btnSize + spacing))
            container.name = activeEmojiPool[i]
            
            if level >= 16 {
                let physBody = SKPhysicsBody(circleOfRadius: btnSize/2)
                physBody.affectedByGravity = false
                physBody.linearDamping = 0.5
                physBody.restitution = 0.8
                container.physicsBody = physBody
                container.physicsBody?.applyImpulse(CGVector(dx: CGFloat.random(in: -5...5), dy: CGFloat.random(in: -5...5)))
            }
            
            let shadow = SKShapeNode(circleOfRadius: btnSize/2)
            shadow.fillColor = .black.withAlphaComponent(0.3)
            shadow.strokeColor = .clear
            shadow.position = CGPoint(x: 0, y: -6)
            container.addChild(shadow)
            
            let body = SKShapeNode(circleOfRadius: btnSize/2)
            body.fillColor = .white
            body.strokeColor = SKColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0)
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
            
            addChild(container)
            buttonNodes.append(container)
            container.setScale(0)
            container.run(SKAction.scale(to: 1.0, duration: 0.3))
            
            if !isBossLevel && level < 16 {
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
                self.countdownLabel.text = "\(count)"; self.countdownLabel.fontColor = (count == 1) ? .systemRed : .systemYellow
                self.playSound("tick.mp3")
                self.countdownLabel.setScale(0); self.countdownLabel.zRotation = -0.5
                let appear = SKAction.group([SKAction.scale(to: 1.2, duration: 0.2), SKAction.rotate(byAngle: 0.6, duration: 0.2), SKAction.fadeIn(withDuration: 0.1)])
                self.countdownLabel.run(SKAction.sequence([appear, SKAction.sequence([SKAction.scale(to: 1.0, duration: 0.1), SKAction.rotate(toAngle: 0, duration: 0.1)])]))
                count -= 1
            } else {
                self.countdownLabel.text = textOverride ?? "GO!"; self.countdownLabel.fontColor = .systemGreen
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
                self.centerDisplayLabel.text = emoji; self.centerDisplayLabel.alpha = 1; self.centerDisplayLabel.setScale(0.5)
                self.centerDisplayLabel.run(SKAction.scale(to: 1.0, duration: 0.2))
                self.stageNode.run(SKAction.sequence([SKAction.scale(to: 1.05, duration: 0.1), SKAction.scale(to: 1.0, duration: 0.1)]))
                self.playSound("pop.mp3")
            }
            let hideWait = SKAction.wait(forDuration: 0.8); let fade = SKAction.run { [weak self] in self?.centerDisplayLabel.alpha = 0 }
            run(SKAction.sequence([wait, show, hideWait, fade])); delay += 1.2
        }
        run(SKAction.wait(forDuration: delay)) { [weak self] in self?.runCountdown(from: 2, textOverride: "GO!", then: { self?.setupInputButtons() }) }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = nodes(at: location)
        for node in nodes {
            if node.name == "btn_menu" { transitionToMenu(); return }
            else if node.name == "restart_trigger_node" { restartGame(); return }
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
        userSequence.append(emoji); playSound("tap.mp3")
        let now = Date().timeIntervalSince1970
        
        // Heat System Logic
        if now - lastTapTime < 0.6 {
            heatValue = min(1.0, heatValue + 0.15)
            comboCount += 1
        } else {
            heatValue = max(0, heatValue - 0.05)
            comboCount = 0
        }
        updateHeatMeter()
        
        // Immediate Points for correct sequence so far
        let tapPoints = 5 + (comboCount * 2)
        currentScore += tapPoints
        totalTapPoints += tapPoints
        showScorePopup(score: tapPoints, position: node.position)
        
        lastTapTime = now
        
        // --- Standard Press Animation ---
        let press = SKAction.group([SKAction.scaleX(to: 1.2, y: 0.8, duration: 0.1), SKAction.moveBy(x: 0, y: -5, duration: 0.1)])
        let release = SKAction.group([SKAction.scale(to: 1.0, duration: 0.1), SKAction.moveBy(x: 0, y: 5, duration: 0.1)])
        node.run(SKAction.sequence([press, release]))
        
        if userSequence.count == currentSequence.count {
            isAcceptingInput = false; selectionTimer?.invalidate()
            timerLabel.run(SKAction.fadeOut(withDuration: 0.3)); timerOverlay?.run(SKAction.fadeOut(withDuration: 0.3))
            runCountdown(from: 1, textOverride: "...", then: { [weak self] in self?.verifyResults() })
        }
    }
    
    private func verifyResults() {
        var allCorrect = true
        for i in 0..<currentSequence.count { if userSequence[i] != currentSequence[i] { allCorrect = false; break } }
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
                if let btn = self.buttonNodes.first(where: { $0.name == self.userSequence[i] }), let body = btn.childNode(withName: "btn_body") as? SKShapeNode {
                    body.fillColor = correct ? .systemGreen : .systemRed
                    if !correct { self.flashOverlay?.run(SKAction.sequence([SKAction.fadeAlpha(to: 0.7, duration: 0.1), SKAction.fadeAlpha(to: 0, duration: 0.2)])) }
                    else { btn.run(SKAction.sequence([SKAction.scale(to: 1.4, duration: 0.1), SKAction.scale(to: 1.0, duration: 0.1)])) }
                }
            }
            let hide = SKAction.sequence([SKAction.wait(forDuration: 0.5), SKAction.run { self.centerDisplayLabel.alpha = 0 }])
            run(SKAction.sequence([wait, show, hide])); delay += 0.7
        }
        run(SKAction.wait(forDuration: delay + 0.5)) { [weak self] in
            guard let self = self else { return }
            
            if self.isBossLevel {
                if allCorrect {
                    // Win: 2x points + base
                    let baseScore = (self.level * 20)
                    let speedBonus = self.remainingTime * 10
                    let totalBossPoints = baseScore + speedBonus
                    
                    self.currentScore += totalBossPoints
                    self.totalBossPoints += totalBossPoints
                    
                    self.showScorePopup(score: totalBossPoints, position: CGPoint(x: self.frame.midX, y: self.frame.midY), isBonus: true)
                    self.playSound("boss_defeat.mp3")
                } else {
                    self.playSound("wrong.mp3")
                }
                
                self.bossNode?.run(SKAction.sequence([
                    SKAction.scale(to: 0, duration: 0.5),
                    SKAction.removeFromParent()
                ]))
                
                // Trigger Post-Boss Interstitial Ad
                if let view = self.view, let vc = view.window?.rootViewController {
                    Task { @MainActor in
                        AdManager.shared.showInterstitial(from: vc)
                    }
                }
                
                self.levelUp()
                
            } else {
                if allCorrect {
                    // Base points for finishing
                    let baseLevelScore = (self.level * 10)
                    let speedBonus = self.remainingTime * 5
                    let roundTotalBeforeFrenzy = baseLevelScore + speedBonus
                    
                    self.totalBaseLevelPoints += baseLevelScore
                    self.totalSpeedBonusPoints += speedBonus
                    
                    var totalRoundPoints = roundTotalBeforeFrenzy
                    if self.isFrenzyMode {
                        let frenzyBonus = totalRoundPoints // 2x means another +1x
                        self.totalFrenzyMultiplierPoints += frenzyBonus
                        totalRoundPoints += frenzyBonus
                    }
                    
                    self.currentScore += totalRoundPoints
                    self.showScorePopup(score: totalRoundPoints, position: CGPoint(x: self.frame.midX, y: self.frame.midY), isBonus: true)
                    self.levelUp()
                } else {
                    self.loseLife()
                }
            }
        }
    }
    
    private func levelUp() {
        level += 1; playSound("level_up.mp3"); notificationFeedback.notificationOccurred(.success)

        // Confetti
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
        
        let congrats = SKLabelNode(fontNamed: "Gameplay"); congrats.text = "LEVEL UP!"; congrats.fontSize = 70; congrats.fontColor = .systemYellow; congrats.verticalAlignmentMode = .center; let shadow = SKLabelNode(fontNamed: "Gameplay"); shadow.text = "LEVEL UP!"; shadow.fontSize = 70; shadow.fontColor = .black; shadow.zPosition = -1; shadow.position = CGPoint(x: 4, y: -4); shadow.verticalAlignmentMode = .center; congrats.addChild(shadow); congrats.position = stageNode.position; congrats.zPosition = 150; addChild(congrats); congrats.setScale(0)
        congrats.run(SKAction.sequence([SKAction.group([SKAction.scale(to: 1.2, duration: 0.2), SKAction.fadeIn(withDuration: 0.2)]), SKAction.scale(to: 1.0, duration: 0.1), SKAction.wait(forDuration: 1.2), SKAction.fadeOut(withDuration: 0.3), SKAction.removeFromParent()])) { [weak self] in self?.startNewRound() }
    }
    
    private func loseLife(reason: String = "WHOOPS!") {
        lives -= 1; updateLivesUI()
        let oops = SKLabelNode(fontNamed: "Gameplay"); oops.text = reason; oops.fontColor = .systemRed; oops.verticalAlignmentMode = .center; let shadow = SKLabelNode(fontNamed: "Gameplay"); shadow.text = reason; shadow.fontSize = 60; shadow.fontColor = .black; shadow.zPosition = -1; shadow.position = CGPoint(x: 4, y: -4); shadow.verticalAlignmentMode = .center; oops.addChild(shadow); oops.fontSize = 60; oops.position = stageNode.position; oops.zPosition = 150; addChild(oops); oops.setScale(0)
        oops.run(SKAction.sequence([SKAction.group([SKAction.scale(to: 1.0, duration: 0.3), SKAction.fadeIn(withDuration: 0.3)]), SKAction.wait(forDuration: 0.8), SKAction.fadeOut(withDuration: 0.3), SKAction.removeFromParent()])) { [weak self] in if self?.lives ?? 0 <= 0 { self?.gameOver() } else { self?.startNewRound() } }
    }
    
    private func gameOver() {
        playSound("game_over")
        Task { @MainActor in
            AdManager.shared.showBanner()
        }
        let isNewHighScore = currentScore > GameManager.shared.highScore
        if isNewHighScore { GameManager.shared.highScore = currentScore }
        
        let boardHeight: CGFloat = 450
        let overNode = createCartoonBoard(size: CGSize(width: frame.width * 0.85, height: boardHeight), color: .darkGray)
        overNode.position = CGPoint(x: frame.midX, y: frame.midY)
        overNode.zPosition = 200
        addChild(overNode)
        
        let overText = SKLabelNode(fontNamed: "Gameplay")
        overText.text = "GAME OVER"
        overText.fontSize = 40
        overText.fontColor = .white
        overText.position = CGPoint(x: 0, y: boardHeight/2 - 60)
        overNode.addChild(overText)
        
        if isNewHighScore {
            let hsText = SKLabelNode(fontNamed: "Gameplay")
            hsText.text = "NEW BEST!"
            hsText.fontSize = 24
            hsText.fontColor = .systemYellow
            hsText.position = CGPoint(x: 0, y: overText.position.y - 40)
            overNode.addChild(hsText)
            
            let scaleAction = SKAction.repeatForever(SKAction.sequence([
                SKAction.scale(to: 1.2, duration: 0.5),
                SKAction.scale(to: 1.0, duration: 0.5)
            ]))
            hsText.run(scaleAction)
        }
        
        // Breakdown
        let stats = [
            ("TOTAL SCORE", "\(currentScore)"),
            ("TAP STREAKS", "\(totalTapPoints)"),
            ("LEVELS BEAT", "\(totalBaseLevelPoints)"),
            ("SPEED BONUS", "\(totalSpeedBonusPoints)"),
            ("BOSS BONUS", "\(totalBossPoints)"),
            ("FRENZY BONUS", "\(totalFrenzyMultiplierPoints)")
        ]
        
        for (i, stat) in stats.enumerated() {
            let label = SKLabelNode(fontNamed: "Gameplay")
            label.text = "\(stat.0): \(stat.1)"
            label.fontSize = (i == 0) ? 22 : 14
            label.fontColor = (i == 0) ? .systemYellow : .lightGray
            label.position = CGPoint(x: 0, y: 60 - CGFloat(i * 30))
            overNode.addChild(label)
        }
        
        let restartBtn = createCartoonButton(text: "TRY AGAIN", color: .systemGreen, size: CGSize(width: 200, height: 50))
        restartBtn.position = CGPoint(x: 0, y: -stats.count * 15 - 60)
        restartBtn.name = "restart_trigger_node"
        overNode.addChild(restartBtn)
        
        let menuBtn = createCartoonButton(text: "MENU", color: .systemBlue, size: CGSize(width: 200, height: 50))
        menuBtn.position = CGPoint(x: 0, y: restartBtn.position.y - 65)
        menuBtn.name = "btn_menu"
        overNode.addChild(menuBtn)
        
        isAcceptingInput = false
    }
    
    private func updateTimerVisuals() {
        let maxTime = isBossLevel ? 10 : (7 * level); let progress = CGFloat(remainingTime) / CGFloat(maxTime); timerLabel.text = "\(remainingTime)"; if let shadow = timerLabel.childNode(withName: "timerShadow") as? SKLabelNode { shadow.text = "\(remainingTime)" }; timerLabel.run(SKAction.sequence([SKAction.scale(to: 1.2, duration: 0.1), SKAction.scale(to: 1.0, duration: 0.1)]))
        timerOverlay?.fillColor = SKColor.systemYellow.withAlphaComponent((1.0 - progress) * 0.35); timerOverlay?.lineWidth = (1.0 - progress) * 40
        if remainingTime <= 3 { timerLabel.fontColor = .systemRed; timerOverlay?.strokeColor = .systemRed; timerLabel.run(SKAction.sequence([SKAction.scale(to: 1.5, duration: 0.1), SKAction.scale(to: 1.0, duration: 0.1)])); timerOverlay?.run(SKAction.repeat(SKAction.sequence([SKAction.moveBy(x: 5, y: 0, duration: 0.05), SKAction.moveBy(x: -5, y: 0, duration: 0.05)]), count: 2)) }
        else { timerLabel.fontColor = .white; timerOverlay?.strokeColor = .systemYellow }
    }
    
    private func timeUp() { selectionTimer?.invalidate(); isAcceptingInput = false; timerLabel.run(SKAction.fadeOut(withDuration: 0.3)); timerOverlay?.run(SKAction.fadeOut(withDuration: 0.3)); playSound("wrong.mp3"); notificationFeedback.notificationOccurred(.error); loseLife(reason: "TOO SLOW!") }

    private func showScorePopup(score: Int, position: CGPoint, isBonus: Bool = false) {
        let label = SKLabelNode(fontNamed: "Gameplay")
        label.text = "+\(score)"
        label.fontSize = isBonus ? 32 : 24
        label.fontColor = isBonus ? .systemYellow : .white
        label.position = position
        label.zPosition = 100
        addChild(label)
        
        let moveUp = SKAction.moveBy(x: 0, y: 50, duration: 0.8)
        let fadeOut = SKAction.fadeOut(withDuration: 0.8)
        let scaleUp = SKAction.scale(to: 1.5, duration: 0.2)
        
        label.run(SKAction.sequence([
            SKAction.group([moveUp, fadeOut, scaleUp]),
            SKAction.removeFromParent()
        ]))
    }
    
    private func restartGame() { lives = 3; level = 1; currentScore = 0; comboCount = 0; heatValue = 0; isFrenzyMode = false; removeAllChildren(); updateEnvironment(); setupStage(); setupBaseUI(); setupOverlays(); setupHeatMeter(); startNewRound() }
    private func transitionToMenu() { let menuScene = MenuScene(size: self.size); menuScene.scaleMode = .aspectFill; let transition = SKTransition.doorsCloseHorizontal(withDuration: 0.8); self.view?.presentScene(menuScene, transition: transition) }
    private func createCartoonBoard(size: CGSize, color: SKColor) -> SKNode { let container = SKNode(); let shadow = SKShapeNode(rectOf: size, cornerRadius: 35); shadow.fillColor = .black.withAlphaComponent(0.4); shadow.strokeColor = .clear; shadow.position = CGPoint(x: 8, y: -8); container.addChild(shadow); let body = SKShapeNode(rectOf: size, cornerRadius: 35); body.fillColor = color; body.strokeColor = .white; body.lineWidth = 6; container.addChild(body); return container }
    private func createCartoonButton(text: String, color: SKColor, size: CGSize) -> SKNode { let container = SKNode(); let shadow = SKShapeNode(rectOf: size, cornerRadius: 20); shadow.fillColor = .black.withAlphaComponent(0.4); shadow.strokeColor = .clear; shadow.position = CGPoint(x: 0, y: -6); container.addChild(shadow); let body = SKShapeNode(rectOf: size, cornerRadius: 20); body.fillColor = color; body.strokeColor = .white; body.lineWidth = 4; body.name = "btn_body"; container.addChild(body); let label = SKLabelNode(fontNamed: "Gameplay"); label.text = text; label.fontSize = 24; label.fontColor = .white; label.verticalAlignmentMode = .center; label.zPosition = 1; container.addChild(label); return container }
    private func playSound(_ fileName: String) { run(SKAction.playSoundFileNamed(fileName, waitForCompletion: false)) }
}