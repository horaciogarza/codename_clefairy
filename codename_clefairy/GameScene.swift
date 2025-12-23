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
    
    // Use selected emoji pack from store
    private var masterEmojiPool: [String] {
        return GameManager.shared.selectedEmojiPack.emojis
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

        // Use selected theme from store
        let theme = GameManager.shared.selectedTheme

        // Apply theme colors with level-based variations
        if level >= 16 {
            // Space level - always dark with stars regardless of theme
            backgroundColor = .black
            physicsWorld.gravity = .zero
            for _ in 0..<50 {
                let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...2))
                star.fillColor = .white
                star.position = CGPoint(x: CGFloat.random(in: 0...frame.width), y: CGFloat.random(in: 0...frame.height))
                star.alpha = CGFloat.random(in: 0.3...1.0)
                star.name = "bg_element"
                addChild(star)
            }
        } else {
            // Apply selected theme
            backgroundColor = theme.primaryColor

            // Add theme-specific accent element
            let accentEmoji = SKLabelNode(text: theme.accentEmoji)
            accentEmoji.fontSize = 60
            accentEmoji.position = CGPoint(x: frame.maxX - 60, y: frame.maxY - 80)
            accentEmoji.name = "bg_element"
            accentEmoji.zPosition = -5
            addChild(accentEmoji)

            // Add secondary color element (hill or ground)
            let ground = SKShapeNode()
            let groundPath = UIBezierPath()
            groundPath.move(to: CGPoint(x: 0, y: 0))
            groundPath.addLine(to: CGPoint(x: 0, y: frame.height * 0.2))
            groundPath.addQuadCurve(to: CGPoint(x: frame.width, y: frame.height * 0.15), controlPoint: CGPoint(x: frame.width * 0.5, y: frame.height * 0.3))
            groundPath.addLine(to: CGPoint(x: frame.width, y: 0))
            groundPath.close()
            ground.path = groundPath.cgPath
            ground.fillColor = theme.secondaryColor
            ground.strokeColor = .clear
            ground.zPosition = -4
            ground.name = "bg_element"
            addChild(ground)

            // Add clouds for lighter themes
            if theme == .daylight || theme == .arctic || theme == .forest {
                for _ in 0..<4 { spawnCloud() }
            }

            // Add special effects for certain themes
            if theme == .space || theme == .night {
                for _ in 0..<20 {
                    let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...2))
                    star.fillColor = .white
                    star.position = CGPoint(x: CGFloat.random(in: 0...frame.width), y: CGFloat.random(in: frame.height * 0.4...frame.height))
                    star.alpha = CGFloat.random(in: 0.3...0.8)
                    star.name = "bg_element"
                    addChild(star)
                }
            }

            if theme == .volcano {
                // Add lava particles
                let spawnLava = SKAction.run { [weak self] in
                    guard let self = self else { return }
                    let lava = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...8))
                    lava.fillColor = [SKColor.red, SKColor.orange, SKColor.yellow].randomElement()!
                    lava.strokeColor = .clear
                    lava.position = CGPoint(x: CGFloat.random(in: 0...self.frame.width), y: 0)
                    lava.name = "bg_element"
                    lava.zPosition = -3
                    self.addChild(lava)
                    lava.run(SKAction.sequence([
                        SKAction.moveBy(x: CGFloat.random(in: -30...30), y: CGFloat.random(in: 50...100), duration: 1.5),
                        SKAction.fadeOut(withDuration: 0.5),
                        SKAction.removeFromParent()
                    ]))
                }
                run(SKAction.repeatForever(SKAction.sequence([spawnLava, SKAction.wait(forDuration: 0.5)])), withKey: "lava_particles")
            }

            if theme == .ocean {
                // Add bubble particles
                let spawnBubble = SKAction.run { [weak self] in
                    guard let self = self else { return }
                    let bubble = SKShapeNode(circleOfRadius: CGFloat.random(in: 4...10))
                    bubble.fillColor = .white.withAlphaComponent(0.3)
                    bubble.strokeColor = .white.withAlphaComponent(0.5)
                    bubble.lineWidth = 1
                    bubble.position = CGPoint(x: CGFloat.random(in: 0...self.frame.width), y: 0)
                    bubble.name = "bg_element"
                    bubble.zPosition = -3
                    self.addChild(bubble)
                    bubble.run(SKAction.sequence([
                        SKAction.moveBy(x: CGFloat.random(in: -20...20), y: self.frame.height + 50, duration: Double.random(in: 4...8)),
                        SKAction.removeFromParent()
                    ]))
                }
                run(SKAction.repeatForever(SKAction.sequence([spawnBubble, SKAction.wait(forDuration: 0.8)])), withKey: "bubble_particles")
            }

            if theme == .arctic {
                // Add snowflake particles
                let spawnSnow = SKAction.run { [weak self] in
                    guard let self = self else { return }
                    let snow = SKLabelNode(text: "❄️")
                    snow.fontSize = CGFloat.random(in: 10...20)
                    snow.position = CGPoint(x: CGFloat.random(in: 0...self.frame.width), y: self.frame.height + 20)
                    snow.name = "bg_element"
                    snow.zPosition = -3
                    snow.alpha = CGFloat.random(in: 0.5...0.9)
                    self.addChild(snow)
                    snow.run(SKAction.sequence([
                        SKAction.group([
                            SKAction.moveBy(x: CGFloat.random(in: -50...50), y: -(self.frame.height + 50), duration: Double.random(in: 5...10)),
                            SKAction.rotate(byAngle: CGFloat.random(in: -2...2), duration: 5)
                        ]),
                        SKAction.removeFromParent()
                    ]))
                }
                run(SKAction.repeatForever(SKAction.sequence([spawnSnow, SKAction.wait(forDuration: 0.6)])), withKey: "snow_particles")
            }
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

        // Create soft fluffy cloud using overlapping circles
        let baseRadius: CGFloat = CGFloat.random(in: 20...35)
        let numPuffs = Int.random(in: 4...6)

        // Main body puffs
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

        // Top puffs for fluffy look
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

        let duration = Double.random(in: 40...80)
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
        levelLabel.text = "LEVEL \(level)"
        if let shadow = levelLabel.children.first as? SKLabelNode { shadow.text = "LEVEL \(level)" }
        
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
            boss.fontSize = 150
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
        let cornerRadius: CGFloat = (view?.safeAreaInsets.bottom ?? 0) > 0 ? 44 : 0
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
        let skin = GameManager.shared.selectedSkin
        
        let size = CGSize(width: frame.width * 0.8, height: frame.width * 0.6)
        
        // Remove old stage components
        stageNode?.removeFromParent()
        jellyDripTimer?.invalidate()
        
        // Shadow
        let shadow = SKShapeNode(rectOf: size, cornerRadius: 40)
        shadow.fillColor = .black.withAlphaComponent(0.3)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: frame.midX + 10, y: frame.midY + 110)
        shadow.zPosition = -1
        addChild(shadow)
        
        stageNode = SKShapeNode(rectOf: size, cornerRadius: 40)
        stageNode.fillColor = skin.boardColor
        stageNode.strokeColor = skin.boardBorderColor
        stageNode.lineWidth = 8
        stageNode.position = CGPoint(x: frame.midX, y: frame.midY + 120)
        addChild(stageNode)
        
        // --- VISUAL EFFECTS PER SKIN ---
        
        // 1. METAL: Liquid Neon Border
        if skin == .metal {
            // Grid
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: -size.height/2)); path.addLine(to: CGPoint(x: 0, y: size.height/2))
            path.move(to: CGPoint(x: -size.width/2, y: 0)); path.addLine(to: CGPoint(x: size.width/2, y: 0))
            let lines = SKShapeNode(path: path)
            lines.strokeColor = .cyan.withAlphaComponent(0.2)
            lines.lineWidth = 2
            stageNode.addChild(lines)
            
            // Pulsing Liquid Border Overlay
            let glowBorder = SKShapeNode(rectOf: size, cornerRadius: 40)
            glowBorder.strokeColor = .cyan
            glowBorder.lineWidth = 4
            glowBorder.glowWidth = 10 // Neon Glow
            glowBorder.fillColor = .clear
            stageNode.addChild(glowBorder)
            
            let pulse = SKAction.sequence([
                SKAction.group([
                    SKAction.fadeAlpha(to: 0.5, duration: 0.5),
                    SKAction.scale(to: 1.02, duration: 0.5)
                ]),
                SKAction.group([
                    SKAction.fadeAlpha(to: 1.0, duration: 0.5),
                    SKAction.scale(to: 1.0, duration: 0.5)
                ])
            ])
            glowBorder.run(SKAction.repeatForever(pulse))
        }
        
        // 2. JELLY: Dropping Particles
        if skin == .jelly {
            jellyDripTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.spawnJellyDrip(size: size)
            }
        }
    }
    
    private func spawnJellyDrip(size: CGSize) {
        let drip = SKShapeNode(circleOfRadius: CGFloat.random(in: 4...8))
        drip.fillColor = UIColor(red: 1.0, green: 0.4, blue: 0.7, alpha: 0.8)
        drip.strokeColor = .clear
        
        // Spawn randomly at the bottom edge of the board
        let randomX = CGFloat.random(in: -size.width/2 ... size.width/2)
        drip.position = CGPoint(x: randomX, y: -size.height/2 + 10)
        drip.zPosition = -1 // Behind text
        stageNode.addChild(drip)
        
        let dropDistance = CGFloat.random(in: 50...100)
        let duration = Double.random(in: 1.0...2.0)
        
        let seq = SKAction.sequence([
            SKAction.moveBy(x: 0, y: -dropDistance, duration: duration),
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()
        ])
        drip.run(seq)
    }
    
    private func setupBaseUI() {
        let safeTop = view?.safeAreaInsets.top ?? 50

        // Hearts container with background
        let heartsContainer = SKNode()
        heartsContainer.position = CGPoint(x: 100, y: frame.maxY - safeTop - 50)
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
            container.addChild(hShadow)

            // Heart
            let heart = SKLabelNode(text: "❤️")
            heart.fontSize = 32
            heart.position = .zero
            heart.name = "heart_icon"
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
        timerLabel.position = CGPoint(x: frame.maxX - 60, y: frame.maxY - safeTop - 50); timerLabel.zPosition = 50; addChild(timerLabel)
        
        countdownLabel.fontSize = 80; countdownLabel.fontColor = .systemYellow; countdownLabel.position = CGPoint(x: frame.midX, y: frame.midY + 120); countdownLabel.zPosition = 20; addChild(countdownLabel)
        
        centerDisplayLabel.fontSize = 112; centerDisplayLabel.position = .zero; centerDisplayLabel.alpha = 0; stageNode.addChild(centerDisplayLabel)
        
        levelLabel.text = "LEVEL \(level)"; levelLabel.fontSize = 32; levelLabel.fontColor = .white
        let levelShadow = SKLabelNode(fontNamed: "Gameplay"); levelShadow.text = "LEVEL \(level)"; levelShadow.fontSize = 32; levelShadow.fontColor = .black.withAlphaComponent(0.5); levelShadow.zPosition = -1; levelShadow.position = CGPoint(x: 2, y: -2)
        levelLabel.addChild(levelShadow)
        levelLabel.position = CGPoint(x: frame.midX, y: stageNode.position.y - stageNode.frame.height/2 - 40); addChild(levelLabel)
        
    }
    
    private func updateLivesUI() {
        for (index, node) in heartNodes.enumerated() {
            if let heart = node.childNode(withName: "heart_icon") as? SKLabelNode {
                let isAlive = index < lives
                heart.text = isAlive ? "❤️" : "🖤"
                node.alpha = isAlive ? 1.0 : 0.35

                // Stop/restore heartbeat based on state
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
    
    private func setupInputButtons() {
        isAcceptingInput = true
        remainingTime = isBossLevel ? 10 : (7 * level)
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
        
        let skin = GameManager.shared.selectedSkin
        
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
            body.fillColor = skin.buttonColor
            body.strokeColor = skin.strokeColor
            body.lineWidth = skin.strokeWidth
            body.name = "btn_body"
            
            if skin == .metal { body.glowWidth = 2 }
            
            container.addChild(body)
            
            let label = SKLabelNode(text: activeEmojiPool[i])
            label.fontSize = btnSize * 0.6
            label.fontColor = skin.fontColor
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
        if now - lastTapTime < 0.5 {
            comboCount += 1
            if comboCount > 3 {
                let fire = SKShapeNode(circleOfRadius: 10); fire.fillColor = .orange; fire.strokeColor = .red; fire.position = node.position; addChild(fire)
                fire.run(SKAction.sequence([SKAction.moveBy(x: 0, y: 50, duration: 0.5), SKAction.fadeOut(withDuration: 0.5), SKAction.removeFromParent()]))
            }
        } else { comboCount = 0 }
        lastTapTime = now
        
        // --- Dynamic Press Animation ---
        let skin = GameManager.shared.selectedSkin
        switch skin.animationType {
        case .standard:
            let press = SKAction.group([SKAction.scaleX(to: 1.2, y: 0.8, duration: 0.1), SKAction.moveBy(x: 0, y: -5, duration: 0.1)])
            let release = SKAction.group([SKAction.scale(to: 1.0, duration: 0.1), SKAction.moveBy(x: 0, y: 5, duration: 0.1)])
            node.run(SKAction.sequence([press, release]))
        case .squish:
            node.run(SKAction.sequence([
                SKAction.scaleX(to: 1.3, y: 0.7, duration: 0.1),
                SKAction.scaleX(to: 0.8, y: 1.2, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]))
        case .glitch:
            let fade = SKAction.fadeAlpha(to: 0.2, duration: 0.05)
            let back = SKAction.fadeAlpha(to: 1.0, duration: 0.05)
            node.run(SKAction.sequence([fade, back, fade, back]))
        case .heavy:
            let left = SKAction.rotate(byAngle: 0.2, duration: 0.05)
            let right = SKAction.rotate(byAngle: -0.2, duration: 0.05)
            node.run(SKAction.sequence([left, right, left, right, SKAction.rotate(toAngle: 0, duration: 0.05)]))
        }
        
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
            if allCorrect {
                let roundScore = (self.level * 10) + (self.comboCount * 5)
                self.currentScore += roundScore; GameManager.shared.totalCoins += roundScore
                if self.isBossLevel { self.bossRound += 1; self.startNextBossPhase() } else { self.levelUp() }
            } else { self.loseLife() }
        }
    }
    
    private func levelUp() {
        level += 1; playSound("level_up.mp3"); notificationFeedback.notificationOccurred(.success)

        // --- Apply Selected Victory Effect from Store ---
        let selectedEffect = GameManager.shared.selectedEffect
        spawnVictoryEffect(selectedEffect)

        // --- Dynamic Level Up Effects based on Skin ---
        let skin = GameManager.shared.selectedSkin

        switch skin {
        case .classic:
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
        case .wood:
            // Falling Leaves
            for _ in 0..<15 {
                let leaf = SKShapeNode(rectOf: CGSize(width: 15, height: 8))
                leaf.fillColor = .green
                leaf.strokeColor = .clear
                leaf.position = CGPoint(x: CGFloat.random(in: 0...frame.width), y: frame.height + 20)
                leaf.zPosition = 145
                addChild(leaf)
                let dest = CGPoint(x: leaf.position.x + CGFloat.random(in: -50...50), y: -50)
                leaf.run(SKAction.group([
                    SKAction.move(to: dest, duration: Double.random(in: 2.0...3.0)),
                    SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 1.0)),
                    SKAction.fadeOut(withDuration: 3.0)
                ])) { leaf.removeFromParent() }
            }
        case .metal, .galaxy:
            // Digital Rain / Cosmic particles
            let particleColor: SKColor = (skin == .galaxy) ? SKColor(red: 0.6, green: 0.3, blue: 1.0, alpha: 1.0) : .cyan
            for _ in 0..<30 {
                let bit = SKShapeNode(rectOf: CGSize(width: 4, height: 12))
                bit.fillColor = particleColor
                bit.strokeColor = .clear
                bit.position = CGPoint(x: CGFloat.random(in: 0...frame.width), y: frame.height + 20)
                bit.zPosition = 145
                addChild(bit)
                let dest = CGPoint(x: bit.position.x, y: -50)
                bit.run(SKAction.sequence([
                    SKAction.move(to: dest, duration: Double.random(in: 0.5...1.0)),
                    SKAction.removeFromParent()
                ]))
            }
        case .jelly, .candy:
            // Rising Bubbles / Candy particles
            let bubbleColor: SKColor = (skin == .candy) ? SKColor(red: 1.0, green: 0.7, blue: 0.85, alpha: 0.6) : UIColor.white.withAlphaComponent(0.5)
            for _ in 0..<15 {
                let bub = SKShapeNode(circleOfRadius: CGFloat.random(in: 5...15))
                bub.fillColor = bubbleColor
                bub.strokeColor = .clear
                bub.position = CGPoint(x: CGFloat.random(in: 0...frame.width), y: -50)
                bub.zPosition = 145
                addChild(bub)
                let dest = CGPoint(x: bub.position.x, y: frame.height + 50)
                bub.run(SKAction.sequence([
                    SKAction.move(to: dest, duration: Double.random(in: 2.0...4.0)),
                    SKAction.removeFromParent()
                ]))
            }
        }
        
        let congrats = SKLabelNode(fontNamed: "Gameplay"); congrats.text = "LEVEL UP!"; congrats.fontSize = 70; congrats.fontColor = .systemYellow; let shadow = SKLabelNode(fontNamed: "Gameplay"); shadow.text = "LEVEL UP!"; shadow.fontSize = 70; shadow.fontColor = .black; shadow.zPosition = -1; shadow.position = CGPoint(x: 4, y: -4); congrats.addChild(shadow); congrats.position = CGPoint(x: frame.midX, y: frame.midY + 100); congrats.zPosition = 150; addChild(congrats); congrats.setScale(0)
        congrats.run(SKAction.sequence([SKAction.group([SKAction.scale(to: 1.2, duration: 0.2), SKAction.fadeIn(withDuration: 0.2)]), SKAction.scale(to: 1.0, duration: 0.1), SKAction.wait(forDuration: 1.2), SKAction.fadeOut(withDuration: 0.3), SKAction.removeFromParent()])) { [weak self] in self?.startNewRound() }
    }
    
    private func loseLife(reason: String = "WHOOPS!") {
        lives -= 1; updateLivesUI()
        let oops = SKLabelNode(fontNamed: "Gameplay"); oops.text = reason; oops.fontColor = .systemRed; let shadow = SKLabelNode(fontNamed: "Gameplay"); shadow.text = reason; shadow.fontSize = 60; shadow.fontColor = .black; shadow.zPosition = -1; shadow.position = CGPoint(x: 4, y: -4); oops.addChild(shadow); oops.fontSize = 60; oops.position = CGPoint(x: frame.midX, y: frame.midY + 100); oops.zPosition = 150; addChild(oops); oops.setScale(0)
        oops.run(SKAction.sequence([SKAction.group([SKAction.scale(to: 1.0, duration: 0.3), SKAction.fadeIn(withDuration: 0.3)]), SKAction.wait(forDuration: 0.8), SKAction.fadeOut(withDuration: 0.3), SKAction.removeFromParent()])) { [weak self] in if self?.lives ?? 0 <= 0 { self?.gameOver() } else { self?.startNewRound() } }
    }
    
    private func gameOver() {
        playSound("game_over.mp3")
        if currentScore > GameManager.shared.highScore { GameManager.shared.highScore = currentScore }
        let overNode = createCartoonBoard(size: CGSize(width: frame.width * 0.85, height: 350), color: .darkGray); overNode.position = CGPoint(x: frame.midX, y: frame.midY); overNode.zPosition = 200; addChild(overNode)
        let overText = SKLabelNode(fontNamed: "Gameplay"); overText.text = "THE END!"; overText.fontSize = 50; overText.fontColor = .white; overText.position = CGPoint(x: 0, y: 100); overNode.addChild(overText)
        let scoreText = SKLabelNode(fontNamed: "Gameplay"); scoreText.text = "SCORE: \(currentScore)"; scoreText.fontSize = 30; scoreText.fontColor = .systemYellow; scoreText.position = CGPoint(x: 0, y: 50); overNode.addChild(scoreText)
        let restartBtn = createCartoonButton(text: "TRY AGAIN", color: .systemGreen, size: CGSize(width: 200, height: 60)); restartBtn.position = CGPoint(x: 0, y: -20); restartBtn.name = "restart_trigger_node"; overNode.addChild(restartBtn)
        let menuBtn = createCartoonButton(text: "MENU", color: .systemBlue, size: CGSize(width: 200, height: 60)); menuBtn.position = CGPoint(x: 0, y: -90); menuBtn.name = "btn_menu"; overNode.addChild(menuBtn); isAcceptingInput = false
    }
    
    private func updateTimerVisuals() {
        let maxTime = isBossLevel ? 10 : (7 * level); let progress = CGFloat(remainingTime) / CGFloat(maxTime); timerLabel.text = "\(remainingTime)"; if let shadow = timerLabel.childNode(withName: "timerShadow") as? SKLabelNode { shadow.text = "\(remainingTime)" }; timerLabel.run(SKAction.sequence([SKAction.scale(to: 1.2, duration: 0.1), SKAction.scale(to: 1.0, duration: 0.1)]))
        timerOverlay?.fillColor = SKColor.systemYellow.withAlphaComponent((1.0 - progress) * 0.35); timerOverlay?.lineWidth = (1.0 - progress) * 40
        if remainingTime <= 3 { timerLabel.fontColor = .systemRed; timerOverlay?.strokeColor = .systemRed; timerLabel.run(SKAction.sequence([SKAction.scale(to: 1.5, duration: 0.1), SKAction.scale(to: 1.0, duration: 0.1)])); timerOverlay?.run(SKAction.repeat(SKAction.sequence([SKAction.moveBy(x: 5, y: 0, duration: 0.05), SKAction.moveBy(x: -5, y: 0, duration: 0.05)]), count: 2)) }
        else { timerLabel.fontColor = .white; timerOverlay?.strokeColor = .systemYellow }
    }
    
    private func timeUp() { selectionTimer?.invalidate(); isAcceptingInput = false; timerLabel.run(SKAction.fadeOut(withDuration: 0.3)); timerOverlay?.run(SKAction.fadeOut(withDuration: 0.3)); playSound("wrong.mp3"); notificationFeedback.notificationOccurred(.error); loseLife(reason: "TOO SLOW!") }

    // MARK: - Victory Effects from Store
    private func spawnVictoryEffect(_ effect: SpecialEffectPack) {
        guard effect != .none else { return }

        let centerX = frame.midX
        let centerY = frame.midY + 100

        switch effect {
        case .confetti:
            for _ in 0..<25 {
                let conf = SKShapeNode(rectOf: CGSize(width: 8, height: 8))
                conf.fillColor = [.red, .yellow, .green, .blue, .purple, .orange, .cyan, .magenta].randomElement()!
                conf.strokeColor = .clear
                conf.position = CGPoint(x: centerX, y: centerY)
                conf.zPosition = 200
                addChild(conf)
                let angle = CGFloat.random(in: 0...(.pi * 2))
                let dist = CGFloat.random(in: 80...250)
                let dest = CGPoint(x: centerX + cos(angle) * dist, y: centerY + sin(angle) * dist - 100)
                conf.run(SKAction.sequence([
                    SKAction.group([
                        SKAction.move(to: dest, duration: 1.0),
                        SKAction.rotate(byAngle: .pi * 4, duration: 1.0),
                        SKAction.fadeOut(withDuration: 1.0)
                    ]),
                    SKAction.removeFromParent()
                ]))
            }
        case .fireworks:
            for burst in 0..<3 {
                run(SKAction.wait(forDuration: Double(burst) * 0.3)) { [weak self] in
                    guard let self = self else { return }
                    let burstX = centerX + CGFloat.random(in: -80...80)
                    let burstY = centerY + CGFloat.random(in: -50...50)
                    for _ in 0..<15 {
                        let spark = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
                        spark.fillColor = [.red, .orange, .yellow, .white, .cyan].randomElement()!
                        spark.strokeColor = .clear
                        spark.position = CGPoint(x: burstX, y: burstY)
                        spark.zPosition = 200
                        self.addChild(spark)
                        let angle = CGFloat.random(in: 0...(.pi * 2))
                        let dist = CGFloat.random(in: 40...120)
                        let dest = CGPoint(x: burstX + cos(angle) * dist, y: burstY + sin(angle) * dist)
                        spark.run(SKAction.sequence([
                            SKAction.group([
                                SKAction.move(to: dest, duration: 0.6),
                                SKAction.fadeOut(withDuration: 0.6)
                            ]),
                            SKAction.removeFromParent()
                        ]))
                    }
                }
            }
        case .hearts:
            for _ in 0..<15 {
                let heart = SKLabelNode(text: ["❤️", "💕", "💖", "💗", "💝"].randomElement()!)
                heart.fontSize = CGFloat.random(in: 20...35)
                heart.position = CGPoint(x: CGFloat.random(in: centerX - 100...centerX + 100), y: centerY - 50)
                heart.zPosition = 200
                addChild(heart)
                let floatUp = SKAction.moveBy(x: CGFloat.random(in: -40...40), y: CGFloat.random(in: 150...250), duration: Double.random(in: 1.5...2.5))
                heart.run(SKAction.sequence([
                    SKAction.group([floatUp, SKAction.sequence([SKAction.wait(forDuration: 1.5), SKAction.fadeOut(withDuration: 0.5)])]),
                    SKAction.removeFromParent()
                ]))
            }
        case .stars:
            for _ in 0..<20 {
                let star = SKLabelNode(text: ["⭐️", "🌟", "✨", "💫"].randomElement()!)
                star.fontSize = CGFloat.random(in: 15...30)
                star.position = CGPoint(x: centerX, y: centerY)
                star.zPosition = 200
                star.alpha = 0
                addChild(star)
                let angle = CGFloat.random(in: 0...(.pi * 2))
                let dist = CGFloat.random(in: 60...180)
                let dest = CGPoint(x: centerX + cos(angle) * dist, y: centerY + sin(angle) * dist)
                star.run(SKAction.sequence([
                    SKAction.group([
                        SKAction.move(to: dest, duration: 0.8),
                        SKAction.fadeIn(withDuration: 0.2),
                        SKAction.sequence([SKAction.wait(forDuration: 0.5), SKAction.fadeOut(withDuration: 0.3)]),
                        SKAction.rotate(byAngle: .pi, duration: 0.8)
                    ]),
                    SKAction.removeFromParent()
                ]))
            }
        case .bubbles:
            for _ in 0..<18 {
                let bubble = SKShapeNode(circleOfRadius: CGFloat.random(in: 8...20))
                bubble.fillColor = .white.withAlphaComponent(0.4)
                bubble.strokeColor = .white.withAlphaComponent(0.7)
                bubble.lineWidth = 2
                bubble.position = CGPoint(x: CGFloat.random(in: 50...frame.width - 50), y: -20)
                bubble.zPosition = 200
                addChild(bubble)
                let floatUp = SKAction.moveBy(x: CGFloat.random(in: -30...30), y: frame.height + 50, duration: Double.random(in: 2.0...4.0))
                bubble.run(SKAction.sequence([floatUp, SKAction.removeFromParent()]))
            }
        case .lightning:
            for _ in 0..<8 {
                let bolt = SKLabelNode(text: "⚡️")
                bolt.fontSize = CGFloat.random(in: 30...50)
                bolt.position = CGPoint(x: CGFloat.random(in: 50...frame.width - 50), y: frame.height + 20)
                bolt.zPosition = 200
                bolt.alpha = 0
                addChild(bolt)
                let flash = SKAction.sequence([
                    SKAction.fadeIn(withDuration: 0.05),
                    SKAction.moveBy(x: CGFloat.random(in: -20...20), y: -frame.height - 50, duration: 0.3),
                    SKAction.fadeOut(withDuration: 0.1),
                    SKAction.removeFromParent()
                ])
                bolt.run(SKAction.sequence([SKAction.wait(forDuration: Double.random(in: 0...0.5)), flash]))
            }
            // Screen flash
            let flash = SKShapeNode(rectOf: self.size)
            flash.fillColor = .white
            flash.strokeColor = .clear
            flash.position = CGPoint(x: frame.midX, y: frame.midY)
            flash.zPosition = 199
            flash.alpha = 0
            addChild(flash)
            flash.run(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.3, duration: 0.05),
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.removeFromParent()
            ]))
        case .none:
            break
        }
    }
    
    private func restartGame() { lives = 3; level = 1; currentScore = 0; comboCount = 0; removeAllChildren(); updateEnvironment(); setupStage(); setupBaseUI(); setupOverlays(); startNewRound() }
    private func transitionToMenu() { let menuScene = MenuScene(size: self.size); menuScene.scaleMode = .aspectFill; let transition = SKTransition.doorsCloseHorizontal(withDuration: 0.8); self.view?.presentScene(menuScene, transition: transition) }
    private func createCartoonBoard(size: CGSize, color: SKColor) -> SKNode { let container = SKNode(); let shadow = SKShapeNode(rectOf: size, cornerRadius: 35); shadow.fillColor = .black.withAlphaComponent(0.4); shadow.strokeColor = .clear; shadow.position = CGPoint(x: 8, y: -8); container.addChild(shadow); let body = SKShapeNode(rectOf: size, cornerRadius: 35); body.fillColor = color; body.strokeColor = .white; body.lineWidth = 6; container.addChild(body); return container }
    private func createCartoonButton(text: String, color: SKColor, size: CGSize) -> SKNode { let container = SKNode(); let shadow = SKShapeNode(rectOf: size, cornerRadius: 20); shadow.fillColor = .black.withAlphaComponent(0.4); shadow.strokeColor = .clear; shadow.position = CGPoint(x: 0, y: -6); container.addChild(shadow); let body = SKShapeNode(rectOf: size, cornerRadius: 20); body.fillColor = color; body.strokeColor = .white; body.lineWidth = 4; body.name = "btn_body"; container.addChild(body); let label = SKLabelNode(fontNamed: "Gameplay"); label.text = text; label.fontSize = 24; label.fontColor = .white; label.verticalAlignmentMode = .center; label.zPosition = 1; container.addChild(label); return container }
    private func playSound(_ fileName: String) { run(SKAction.playSoundFileNamed(fileName, waitForCompletion: false)) }
}