import SpriteKit
import AVFoundation

class GameScene: SKScene, GameTimerDelegate, BossControllerDelegate, InputControllerDelegate, PauseOverlayDelegate {

    // MARK: - Properties
    var doorTransitionTexture: SKTexture?

    private var lives = 3
    private var level = 1

    // State Machine
    private var gameState: GameState = .idle {
        didSet { handleStateTransition(from: oldValue, to: gameState) }
    }

    // Controllers
    private var bgRenderer: BackgroundRenderer!
    private var animations: GameAnimations!
    private var timerController: GameTimerController!
    private var board: GameBoard!
    private var scoring: GameScoring!
    private var bossController: BossController!
    private var inputController: InputController!
    private var pauseOverlay: PauseOverlay?

    // Emoji State
    private var activeEmojiPool: [String] = []
    private var currentSequence: [String] = []
    private var userSequence: [String] = []

    // Daily challenge state
    private var dailyRounds: [DailyChallengeManager.DailyRound] = []
    private var dailyRoundIndex = 0

    // Power-up state
    private var shieldActive = false
    private var slowMoActive = false
    private var peekUsedThisRound = false

    // Nodes
    private var heartNodes: [SKNode] = []
    private var countdownLabel = SKLabelNode(fontNamed: "Gameplay")
    private var centerDisplayLabel = SKLabelNode(fontNamed: "AppleColorEmoji")
    private var timerLabel = SKLabelNode(fontNamed: "Gameplay")
    private var levelLabel = SKLabelNode(fontNamed: "Gameplay")
    private var stageNode: SKShapeNode?
    private var timerOverlay: SKShapeNode?
    private var flashOverlay: SKShapeNode?
    private var heatMeterNode: SKShapeNode?
    private var peekButton: SKNode?
    private var pauseButton: SKNode?

    private var jellyDripTimer: Timer?
    private var cachedMasterEmojiPool: [String] = []

    private let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedback = UINotificationFeedbackGenerator()

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        // Initialize controllers
        bgRenderer = BackgroundRenderer(scene: self)
        animations = GameAnimations(scene: self)
        timerController = GameTimerController(scene: self)
        timerController.delegate = self
        board = GameBoard(scene: self)
        scoring = GameScoring()
        scoring.reset()
        bossController = BossController(scene: self)
        bossController.delegate = self
        inputController = InputController()
        inputController.delegate = self

        cachedMasterEmojiPool = GameManager.shared.getActivePool(count: 30)

        StatsManager.shared.recordGameStart()
        StatsManager.shared.recordDailyPlay()

        bgRenderer.updateEnvironment(isFrenzyMode: false)
        setupStage()
        setupBaseUI()
        setupOverlays()
        setupHeatMeter()
        setupPauseButton()

        Task { @MainActor in
            AdManager.shared.hideBanner()
            AdManager.shared.cleanupCallbacks()

            AdManager.shared.onAdWillPresent = { [weak self] in
                self?.isPaused = true
            }
            AdManager.shared.onAdDidDismiss = { [weak self] in
                self?.isPaused = false
            }
        }

        // Daily challenge setup
        if GameManager.shared.currentMode == .dailyChallenge {
            DailyChallengeManager.shared.recordAttempt()
            dailyRounds = DailyChallengeManager.shared.generateChallenge(emojiPool: cachedMasterEmojiPool)
            dailyRoundIndex = 0
        }

        // Apply slow-mo power-up at session start
        if PowerUpManager.shared.hasPowerUp(.slowMo) {
            slowMoActive = PowerUpManager.shared.consume(.slowMo)
        }
        // Apply shield
        if PowerUpManager.shared.hasPowerUp(.shield) {
            shieldActive = PowerUpManager.shared.consume(.shield)
        }

        if let texture = doorTransitionTexture {
            animations.performCustomDoorOpening(with: texture) { [weak self] in
                self?.startNewRound()
            }
        } else {
            startNewRound()
        }
    }

    override func willMove(from view: SKView) {
        jellyDripTimer?.invalidate()
        timerController.invalidate()
        Task { @MainActor in
            AdManager.shared.cleanupCallbacks()
        }
    }

    // MARK: - State Machine

    private func handleStateTransition(from oldState: GameState, to newState: GameState) {
        // No-op for now — state is checked directly in methods
    }

    // MARK: - Pause

    func pauseGame() {
        guard gameState.canPause else { return }
        let previousState = gameState
        gameState = .paused(previous: previousState)
        timerController.invalidate()
        isPaused = true

        let overlay = PauseOverlay(size: self.size)
        overlay.delegate = self
        addChild(overlay)
        self.pauseOverlay = overlay
        isPaused = false // Allow overlay interaction
    }

    func pauseOverlayDidResume() {
        pauseOverlay?.removeFromParent()
        pauseOverlay = nil

        if case .paused(let prev) = gameState {
            gameState = prev
            // Restart timer if we were awaiting input
            if prev == .awaitingInput || prev == .bossAwaitingInput {
                let duration = timerController.remainingTime
                let mode = GameManager.shared.currentMode
                if (mode == .classic || mode == .dailyChallenge) && duration > 0 {
                    timerController.startTimer(duration: duration)
                }
            }
        }
    }

    func pauseOverlayDidRestart() {
        pauseOverlay?.removeFromParent()
        pauseOverlay = nil
        restartGame()
    }

    func pauseOverlayDidGoToMenu() {
        pauseOverlay?.removeFromParent()
        pauseOverlay = nil
        transitionToMenu()
    }

    // MARK: - Core Game Loop
    private func startNewRound() {
        timerController.invalidate()
        timerController.resetVisuals()
        userSequence = []
        currentSequence = []
        inputController.lock()
        board.clearButtons()
        peekButton?.removeFromParent()
        peekButton = nil
        peekUsedThisRound = false

        if GameManager.shared.currentMode == .dailyChallenge {
            if dailyRoundIndex >= dailyRounds.count {
                // Challenge complete
                DailyChallengeManager.shared.recordCompletion(score: scoring.currentScore)
                PowerUpManager.shared.awardDailyChallengeReward()
                gameOver()
                return
            }
            startDailyRound()
            return
        }

        if level % 5 == 0 {
            guard let stageNode = stageNode else { return }
            gameState = .bossWarning
            bossController.startBossRound(
                stageNode: stageNode,
                levelLabel: levelLabel,
                animations: animations,
                playSound: { [weak self] s in self?.playSound(s) }
            )
            return
        }

        gameState = .idle
        bossController.reset()

        let modeSuffix = GameManager.shared.currentMode == .zen ? " (ZEN)" : ""
        levelLabel.text = "LEVEL \(level)\(modeSuffix)"
        levelLabel.fontColor = .white
        if let shadow = levelLabel.children.first as? SKLabelNode { shadow.text = levelLabel.text }

        bgRenderer.updateEnvironment(isFrenzyMode: scoring.isFrenzyMode)
        let config = GameBoard.getLevelConfig(for: level)
        activeEmojiPool = Array(cachedMasterEmojiPool.shuffled().prefix(config.poolSize))
        for _ in 0..<GameBoard.sequenceCount(for: level, isBoss: false) {
            if let randomEmoji = activeEmojiPool.randomElement() {
                currentSequence.append(randomEmoji)
            }
        }

        gameState = .countdown(3)
        animations.runCountdown(from: 3, countdownLabel: countdownLabel, playSound: { [weak self] s in self?.playSound(s) }) { [weak self] in
            self?.gameState = .showingSequence
            self?.showSequence()
        }
    }

    private func startDailyRound() {
        let round = dailyRounds[dailyRoundIndex]
        let pool = Array(cachedMasterEmojiPool.prefix(round.poolSize))
        activeEmojiPool = pool

        currentSequence = round.emojiIndices.map { idx in
            pool[idx % pool.count]
        }

        levelLabel.text = "DAILY \(dailyRoundIndex + 1)/10"
        levelLabel.fontColor = .systemOrange
        if let shadow = levelLabel.children.first as? SKLabelNode { shadow.text = levelLabel.text }

        bgRenderer.updateEnvironment(isFrenzyMode: scoring.isFrenzyMode)

        gameState = .countdown(3)
        animations.runCountdown(from: 3, countdownLabel: countdownLabel, playSound: { [weak self] s in self?.playSound(s) }) { [weak self] in
            self?.gameState = .showingSequence
            self?.showSequence()
        }
    }

    private func showSequence() {
        guard let stageNode = stageNode else { return }
        animations.showSequence(currentSequence, centerDisplayLabel: centerDisplayLabel, stageNode: stageNode, playSound: { [weak self] s in self?.playSound(s) }) { [weak self] in
            guard let self = self else { return }
            self.animations.runCountdown(from: 2, countdownLabel: self.countdownLabel, textOverride: "GO!", playSound: { [weak self] s in self?.playSound(s) }) { [weak self] in
                self?.setupInputPhase()
            }
        }
    }

    private func setupInputPhase() {
        let isBoss = gameState.isBossPhase
        gameState = isBoss ? .bossAwaitingInput : .awaitingInput
        inputController.prepare(expectedSequenceLength: currentSequence.count)

        board.setupInputButtons(activeEmojiPool: activeEmojiPool, level: level, isBoss: isBoss)

        // Timer
        if GameManager.shared.currentMode == .classic {
            let duration = GameTimerController.timerDuration(for: level, isBoss: isBoss, hasSlowMo: slowMoActive)
            timerController.startTimer(duration: duration)
        } else if GameManager.shared.currentMode == .dailyChallenge {
            let duration = GameTimerController.timerDuration(for: dailyRoundIndex + 1, isBoss: false, hasSlowMo: slowMoActive)
            timerController.startTimer(duration: duration)
        } else {
            timerController.showZenMode()
        }

        // Show peek button if available
        if PowerUpManager.shared.hasPowerUp(.peek) && !peekUsedThisRound {
            showPeekButton()
        }
    }

    // MARK: - Power-ups

    private func showPeekButton() {
        let btn = UIFactory.createButtonWithIcon(
            text: "PEEK",
            systemName: "eye.fill",
            color: .systemPurple,
            size: CGSize(width: 130, height: 40),
            iconSize: 16
        )
        btn.position = CGPoint(x: frame.midX, y: (stageNode?.position.y ?? frame.midY) + (stageNode?.frame.height ?? 0) / 2 + 30)
        btn.name = "peek_button"
        btn.zPosition = 50
        addChild(btn)
        peekButton = btn
    }

    private func activatePeek() {
        guard PowerUpManager.shared.consume(.peek) else { return }
        peekUsedThisRound = true
        peekButton?.removeFromParent()
        peekButton = nil

        // Pause timer
        timerController.invalidate()
        inputController.lock()

        // Re-show sequence, then resume
        guard let stageNode = stageNode else { return }
        animations.showSequence(currentSequence, centerDisplayLabel: centerDisplayLabel, stageNode: stageNode, playSound: { [weak self] s in self?.playSound(s) }) { [weak self] in
            guard let self = self else { return }
            self.inputController.prepare(expectedSequenceLength: self.currentSequence.count - self.userSequence.count)
            if GameManager.shared.currentMode != .zen {
                self.timerController.startTimer(duration: self.timerController.remainingTime)
            }
        }
    }

    // MARK: - GameTimerDelegate
    func timerDidTick(remaining: Int) { }

    func timerDidExpire() {
        inputController.lock()
        timerController.hideTimer()
        playSound("wrong.mp3")
        if GameManager.shared.hapticsEnabled {
            notificationFeedback.notificationOccurred(.error)
        }
        loseLife(reason: "TOO SLOW!")
    }

    // MARK: - BossControllerDelegate
    func bossPhaseReady() {
        userSequence = []
        currentSequence = []
        board.clearButtons()
        activeEmojiPool = Array(cachedMasterEmojiPool.shuffled().prefix(12))
        for _ in 0..<4 {
            if let randomEmoji = activeEmojiPool.randomElement() {
                currentSequence.append(randomEmoji)
            }
        }
        gameState = .bossCountdown(2)
        animations.runCountdown(from: 2, countdownLabel: countdownLabel, textOverride: bossController.currentPhaseText, playSound: { [weak self] s in self?.playSound(s) }) { [weak self] in
            self?.gameState = .bossShowingSequence
            self?.showSequence()
        }
    }

    func bossDefeated() {
        gameState = .bossDefeated
    }

    // MARK: - InputControllerDelegate
    func inputDidReceiveEmoji(_ emoji: String, node: SKNode) {
        userSequence.append(emoji)
        playSound("tap.mp3")

        let result = scoring.processTap()
        updateHeatMeter()
        animations.showScorePopup(score: result.tapPoints, position: node.position)

        if result.frenzyTriggered {
            startFrenzy()
        }

        // Button press animation
        let press = SKAction.group([
            SKAction.scaleX(to: 1.2, y: 0.8, duration: 0.1),
            SKAction.moveBy(x: 0, y: -5, duration: 0.1)
        ])
        let release = SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.1),
            SKAction.moveBy(x: 0, y: 5, duration: 0.1)
        ])
        node.run(SKAction.sequence([press, release]))

        if GameManager.shared.hapticsEnabled {
            hapticFeedback.impactOccurred()
        }
    }

    func inputSequenceComplete() {
        timerController.invalidate()
        timerController.hideTimer()

        gameState = gameState.isBossPhase ? .bossVerifying : .verifying
        animations.runCountdown(from: 1, countdownLabel: countdownLabel, textOverride: "...", playSound: { [weak self] s in self?.playSound(s) }) { [weak self] in
            self?.verifyResults()
        }
    }

    // MARK: - Verification
    private func verifyResults() {
        let result = scoring.verifySequence(user: userSequence, expected: currentSequence)

        var delay = 0.0
        for i in 0..<currentSequence.count {
            let wait = SKAction.wait(forDuration: delay)
            let show = SKAction.run { [weak self] in
                guard let self = self else { return }
                let correct = i < result.perItemCorrect.count ? result.perItemCorrect[i] : false
                self.centerDisplayLabel.text = self.currentSequence[i]
                self.centerDisplayLabel.fontColor = correct ? .systemGreen : .systemRed
                self.centerDisplayLabel.alpha = 1
                self.playSound(correct ? "correct.mp3" : "wrong.mp3")

                if i < self.userSequence.count,
                   let btn = self.board.buttonNodes.first(where: { $0.name == self.userSequence[i] }),
                   let body = btn.childNode(withName: "btn_body") as? SKShapeNode {
                    body.fillColor = correct ? .systemGreen : .systemRed
                    if !correct {
                        self.flashOverlay?.run(SKAction.sequence([
                            SKAction.fadeAlpha(to: 0.7, duration: 0.1),
                            SKAction.fadeAlpha(to: 0, duration: 0.2)
                        ]))
                    } else {
                        btn.run(SKAction.sequence([
                            SKAction.scale(to: 1.4, duration: 0.1),
                            SKAction.scale(to: 1.0, duration: 0.1)
                        ]))
                    }
                }
            }
            let hide = SKAction.sequence([
                SKAction.wait(forDuration: 0.5),
                SKAction.run { [weak self] in self?.centerDisplayLabel.alpha = 0 }
            ])
            run(SKAction.sequence([wait, show, hide]))
            delay += 0.7
        }

        run(SKAction.wait(forDuration: delay + 0.5)) { [weak self] in
            guard let self = self else { return }
            self.processVerificationResult(result)
        }
    }

    private func processVerificationResult(_ result: GameScoring.VerifyResult) {
        let isBoss = gameState == .bossVerifying

        if isBoss {
            if result.allCorrect {
                let points = scoring.scoreRoundComplete(level: level, remainingTime: timerController.remainingTime, isBoss: true)
                animations.showScorePopup(score: points, position: CGPoint(x: frame.midX, y: frame.midY), isBonus: true)
                playSound("boss_defeat.mp3")

                // Try next boss phase
                let morePhases = bossController.advancePhase()
                if morePhases {
                    bossPhaseReady()
                } else {
                    // Boss fully defeated — interstitial ad
                    if let view = self.view, let vc = view.window?.rootViewController {
                        Task { @MainActor in
                            AdManager.shared.showInterstitial(from: vc)
                        }
                    }
                    scoring.recordBossDefeated()
                    PowerUpManager.shared.awardBossDefeatReward()
                    levelUp()
                }
            } else {
                // Failed a boss phase — lose a life
                playSound("wrong.mp3")
                bossController.reset()
                loseLife()
            }
        } else {
            if result.allCorrect {
                let remainingTime = GameManager.shared.currentMode == .zen ? 0 : timerController.remainingTime
                let points = scoring.scoreRoundComplete(level: level, remainingTime: remainingTime, isBoss: false)
                animations.showScorePopup(score: points, position: CGPoint(x: frame.midX, y: frame.midY), isBonus: true)
                levelUp()
            } else {
                loseLife()
            }
        }
    }

    // MARK: - Level Up
    private func levelUp() {
        level += 1
        gameState = .levelUp
        playSound("level_up.mp3")
        if GameManager.shared.hapticsEnabled {
            notificationFeedback.notificationOccurred(.success)
        }

        PowerUpManager.shared.checkLevelRewards(level: level)

        guard let stageNode = stageNode else { return }
        animations.showLevelUp(at: stageNode.position) { [weak self] in
            if GameManager.shared.currentMode == .dailyChallenge {
                self?.dailyRoundIndex += 1
            }
            self?.startNewRound()
        }
    }

    private func loseLife(reason: String = "WHOOPS!") {
        // Shield check
        if shieldActive {
            shieldActive = false
            // Show shield consumed animation using SF Symbol
            let shieldPos = stageNode?.position ?? CGPoint(x: frame.midX, y: frame.midY)
            if let shieldIcon = UIFactory.symbolSprite("shield.fill", pointSize: 60, color: .systemCyan, size: CGSize(width: 60, height: 70)) {
                shieldIcon.position = shieldPos
                shieldIcon.zPosition = 150
                addChild(shieldIcon)
                shieldIcon.run(SKAction.sequence([
                    SKAction.group([
                        SKAction.scale(to: 2.5, duration: 0.3),
                        SKAction.fadeOut(withDuration: 0.5)
                    ]),
                    SKAction.removeFromParent()
                ])) { [weak self] in
                    self?.startNewRound()
                }
            } else {
                startNewRound()
            }
            return
        }

        if GameManager.shared.currentMode == .zen {
            startNewRound()
            return
        }

        lives -= 1
        updateLivesUI()

        guard let stageNode = stageNode else { return }
        animations.showLoseLife(reason: reason, at: stageNode.position) { [weak self] in
            guard let self = self else { return }
            if self.lives <= 0 {
                self.gameOver()
            } else {
                if GameManager.shared.currentMode == .dailyChallenge {
                    self.dailyRoundIndex += 1
                }
                self.startNewRound()
            }
        }
    }

    // MARK: - Game Over
    private func gameOver() {
        gameState = .gameOver
        timerController.invalidate()
        removeAction(forKey: "frenzy_timer")
        playSound("game_over")

        // Record stats
        let isNewHighScore = scoring.currentScore > GameManager.shared.highScore
        if isNewHighScore { GameManager.shared.highScore = scoring.currentScore }

        StatsManager.shared.recordGameEnd(
            level: level,
            score: scoring.currentScore,
            bossesDefeated: scoring.bossesDefeatedThisSession,
            frenziesTriggered: scoring.frenziesTriggeredThisSession,
            bestCombo: scoring.bestComboThisSession,
            timePlayed: scoring.sessionTimePlayed()
        )

        let newAchievements = AchievementManager.shared.checkAchievements()
        ThemeManager.shared.checkUnlocks()

        Task { @MainActor in
            AdManager.shared.showBanner()
        }

        // Build game over screen
        let boardHeight: CGFloat = 520
        let overNode = UIFactory.createCartoonBoard(size: CGSize(width: frame.width * 0.85, height: boardHeight), color: .darkGray)
        overNode.position = CGPoint(x: frame.midX, y: frame.midY)
        overNode.zPosition = 200
        addChild(overNode)

        // Level reached
        let levelReached = SKLabelNode(fontNamed: "Gameplay")
        levelReached.text = "LEVEL \(level) REACHED"
        levelReached.fontSize = 22
        levelReached.fontColor = .systemCyan
        levelReached.position = CGPoint(x: 0, y: boardHeight / 2 - 50)
        overNode.addChild(levelReached)

        let overText = SKLabelNode(fontNamed: "Gameplay")
        overText.text = "GAME OVER"
        overText.fontSize = 40
        overText.fontColor = .white
        overText.position = CGPoint(x: 0, y: levelReached.position.y - 45)
        overNode.addChild(overText)

        if isNewHighScore {
            let hsContainer = SKNode()
            hsContainer.position = CGPoint(x: 0, y: overText.position.y - 35)
            overNode.addChild(hsContainer)

            if let starL = UIFactory.symbolSprite("star.fill", pointSize: 20, color: .systemYellow, size: CGSize(width: 20, height: 20)) {
                starL.position = CGPoint(x: -75, y: 2)
                hsContainer.addChild(starL)
            }
            if let starR = UIFactory.symbolSprite("star.fill", pointSize: 20, color: .systemYellow, size: CGSize(width: 20, height: 20)) {
                starR.position = CGPoint(x: 75, y: 2)
                hsContainer.addChild(starR)
            }

            let hsText = SKLabelNode(fontNamed: "Gameplay")
            hsText.text = "NEW BEST!"
            hsText.fontSize = 24
            hsText.fontColor = .systemYellow
            hsContainer.addChild(hsText)

            hsContainer.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.scale(to: 1.2, duration: 0.5),
                SKAction.scale(to: 1.0, duration: 0.5)
            ])))
        }

        // Animated score breakdown
        let stats: [(String, Int)] = [
            ("TOTAL SCORE", scoring.currentScore),
            ("TAP STREAKS", scoring.totalTapPoints),
            ("LEVELS BEAT", scoring.totalBaseLevelPoints),
            ("SPEED BONUS", scoring.totalSpeedBonusPoints),
            ("BOSS BONUS", scoring.totalBossPoints),
            ("FRENZY BONUS", scoring.totalFrenzyMultiplierPoints)
        ]

        for (i, stat) in stats.enumerated() {
            let label = SKLabelNode(fontNamed: "Gameplay")
            label.text = "\(stat.0): 0"
            label.fontSize = (i == 0) ? 22 : 14
            label.fontColor = (i == 0) ? .systemYellow : .lightGray
            label.position = CGPoint(x: 0, y: 30 - CGFloat(i * 30))
            overNode.addChild(label)

            // Animated counting
            let finalValue = stat.1
            let steps = 20
            let stepDuration = 0.5 / Double(steps)
            let startDelay = Double(i) * 0.3

            run(SKAction.wait(forDuration: startDelay)) {
                for step in 0...steps {
                    let delay = Double(step) * stepDuration
                    label.run(SKAction.sequence([
                        SKAction.wait(forDuration: delay),
                        SKAction.run {
                            let value = Int(Double(finalValue) * Double(step) / Double(steps))
                            label.text = "\(stat.0): \(value)"
                        }
                    ]))
                }
            }
        }

        // Buttons
        let buttonsY = -stats.count * 15 - 50

        let restartBtn = UIFactory.createButtonWithIcon(text: "TRY AGAIN", systemName: "arrow.counterclockwise", color: .systemGreen, size: CGSize(width: 210, height: 50), iconSize: 18)
        restartBtn.position = CGPoint(x: 0, y: CGFloat(buttonsY))
        restartBtn.name = "restart_trigger_node"
        overNode.addChild(restartBtn)

        let shareBtn = UIFactory.createButtonWithIcon(text: "SHARE", systemName: "square.and.arrow.up", color: .systemPurple, size: CGSize(width: 210, height: 50), iconSize: 18)
        shareBtn.position = CGPoint(x: 0, y: CGFloat(buttonsY) - 60)
        shareBtn.name = "share_score"
        overNode.addChild(shareBtn)

        let menuBtn = UIFactory.createButtonWithIcon(text: "MENU", systemName: "house.fill", color: .systemBlue, size: CGSize(width: 210, height: 50), iconSize: 18)
        menuBtn.position = CGPoint(x: 0, y: CGFloat(buttonsY) - 120)
        menuBtn.name = "btn_menu"
        overNode.addChild(menuBtn)

        // Show achievement toasts
        var toastDelay = 1.5
        for achievementId in newAchievements {
            run(SKAction.wait(forDuration: toastDelay)) { [weak self] in
                guard let self = self else { return }
                AchievementManager.showUnlockToast(achievementId: achievementId, in: self)
            }
            toastDelay += 3.0
        }
    }

    // MARK: - Share
    private func shareScore() {
        let text = "I reached Level \(level) with \(scoring.currentScore) points in MEMORANDUM! Can you beat that? 🧠🔥"
        guard let vc = view?.window?.rootViewController else { return }
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        vc.present(activityVC, animated: true)
    }

    // MARK: - Heat / Frenzy
    private func updateHeatMeter() {
        let color: SKColor = scoring.isFrenzyMode ? .systemRed : .systemYellow
        heatMeterNode?.fillColor = color
        let targetScale = max(0.01, scoring.heatValue)
        heatMeterNode?.run(SKAction.scaleX(to: targetScale, duration: 0.2))
    }

    private func startFrenzy() {
        playSound("frenzy.mp3")
        bgRenderer.updateEnvironment(isFrenzyMode: true)

        let flash = SKAction.repeat(SKAction.sequence([
            SKAction.run { [weak self] in self?.backgroundColor = .white },
            SKAction.wait(forDuration: 0.05),
            SKAction.run { [weak self] in self?.bgRenderer.updateEnvironment(isFrenzyMode: true) },
            SKAction.wait(forDuration: 0.05)
        ]), count: 3)
        run(flash)

        run(SKAction.sequence([
            SKAction.wait(forDuration: 10.0),
            SKAction.run { [weak self] in
                guard let self = self, self.gameState != .gameOver else { return }
                self.scoring.endFrenzy()
                self.bgRenderer.updateEnvironment(isFrenzyMode: false)
                self.updateHeatMeter()
            }
        ]), withKey: "frenzy_timer")
    }

    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = nodes(at: location)

        // Pause overlay intercepts all touches
        if let overlay = pauseOverlay {
            let overlayLocation = touch.location(in: overlay)
            _ = overlay.handleTouch(at: overlayLocation)
            return
        }

        for node in nodes {
            let target = node.name == "btn_body" ? node.parent : node
            let name = target?.name ?? node.name

            if name == "btn_menu" { transitionToMenu(); return }
            if name == "restart_trigger_node" { restartGame(); return }
            if name == "share_score" { shareScore(); return }
            if name == "pause_button" { pauseGame(); return }
            if name == "peek_button" { activatePeek(); return }
        }

        guard gameState.isAcceptingInput else { return }
        for node in nodes {
            let parent = node.name == "btn_body" ? node.parent : node
            if let name = parent?.name, activeEmojiPool.contains(name) {
                inputController.handleTouch(emoji: name, node: parent!)
                break
            }
        }
    }

    // MARK: - UI Setup

    private func setupStage() {
        let size = CGSize(width: frame.width * 0.8, height: frame.width * 0.6)
        let shiftY = self.size.height * 0.05

        stageNode?.removeFromParent()
        jellyDripTimer?.invalidate()

        let shadow = SKShapeNode(rectOf: size, cornerRadius: 40)
        shadow.fillColor = .black.withAlphaComponent(0.3)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: frame.midX + 10, y: frame.midY + 110 - shiftY)
        shadow.zPosition = -1
        addChild(shadow)

        let stage = SKShapeNode(rectOf: size, cornerRadius: 40)
        let theme = ThemeManager.shared.currentTheme
        stage.fillColor = theme.boardColor.withAlphaComponent(0.9)
        stage.strokeColor = theme.skyColor
        stage.lineWidth = 8
        stage.position = CGPoint(x: frame.midX, y: frame.midY + 120 - shiftY)
        addChild(stage)
        stageNode = stage
    }

    private static func makeHeartIcon(filled: Bool, size: CGFloat = 28) -> SKSpriteNode? {
        let name = filled ? "heart.fill" : "heart.slash"
        let color: UIColor = filled ? .systemRed : .gray
        guard let node = UIFactory.symbolSprite(name, pointSize: size, color: color, size: CGSize(width: size, height: size)) else { return nil }
        node.name = "heart_icon"
        return node
    }

    private func setupBaseUI() {
        let safeTop = view?.safeAreaInsets.top ?? 50

        let heartsContainer = SKNode()
        heartsContainer.position = CGPoint(x: 100, y: frame.maxY - safeTop - 40)
        heartsContainer.zPosition = 50
        addChild(heartsContainer)

        let heartsBg = SKShapeNode(rectOf: CGSize(width: 140, height: 46), cornerRadius: 23)
        heartsBg.fillColor = .white.withAlphaComponent(0.85)
        heartsBg.strokeColor = SKColor(red: 1.0, green: 0.4, blue: 0.5, alpha: 0.8)
        heartsBg.lineWidth = 3
        heartsContainer.addChild(heartsBg)

        for i in 0..<3 {
            let container = SKNode()
            container.position = CGPoint(x: -42 + (i * 42), y: 0)
            heartsContainer.addChild(container)

            if let heart = Self.makeHeartIcon(filled: true) {
                container.addChild(heart)
            }
            heartNodes.append(container)

            let delay = SKAction.wait(forDuration: Double(i) * 0.15)
            let beat = SKAction.sequence([
                SKAction.scale(to: 1.15, duration: 0.15),
                SKAction.scale(to: 1.0, duration: 0.15),
                SKAction.wait(forDuration: 0.5)
            ])
            container.run(SKAction.sequence([delay, SKAction.repeatForever(beat)]))
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
        timerLabel.position = CGPoint(x: frame.maxX - 60, y: heartsContainer.position.y - 70)
        timerLabel.zPosition = 50
        addChild(timerLabel)

        timerController.timerLabel = timerLabel

        countdownLabel.fontSize = 60
        countdownLabel.fontColor = .systemYellow
        countdownLabel.position = CGPoint(x: frame.maxX - 100, y: heartsContainer.position.y)
        countdownLabel.verticalAlignmentMode = .center
        countdownLabel.zPosition = 20
        addChild(countdownLabel)

        centerDisplayLabel.fontSize = 112
        centerDisplayLabel.position = .zero
        centerDisplayLabel.verticalAlignmentMode = .center
        centerDisplayLabel.alpha = 0
        stageNode?.addChild(centerDisplayLabel)

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

        if let stageNode = stageNode {
            levelLabel.position = CGPoint(x: frame.midX, y: stageNode.position.y - stageNode.frame.height / 2 - 40)
        }
        addChild(levelLabel)
    }

    private func setupOverlays() {
        let cornerRadius: CGFloat = 55.0
        let overlay = SKShapeNode(path: UIBezierPath(roundedRect: frame, cornerRadius: cornerRadius).cgPath)
        overlay.position = .zero
        overlay.fillColor = .clear
        overlay.strokeColor = .systemYellow
        overlay.lineWidth = 0
        overlay.zPosition = 500
        addChild(overlay)
        timerOverlay = overlay
        timerController.timerOverlay = overlay

        let flash = SKShapeNode(rectOf: self.size)
        flash.position = CGPoint(x: frame.midX, y: frame.midY)
        flash.fillColor = .systemRed
        flash.strokeColor = .clear
        flash.alpha = 0
        flash.zPosition = 100
        addChild(flash)
        flashOverlay = flash
    }

    private func setupHeatMeter() {
        let safeTop = view?.safeAreaInsets.top ?? 50
        let shiftY = size.height * 0.05
        let meterWidth: CGFloat = 120
        let meterHeight: CGFloat = 12

        let bg = SKShapeNode(rectOf: CGSize(width: meterWidth, height: meterHeight), cornerRadius: 6)
        bg.fillColor = .black.withAlphaComponent(0.3)
        bg.strokeColor = .white
        bg.lineWidth = 1
        bg.position = CGPoint(x: frame.midX, y: frame.maxY - safeTop - 80 - shiftY)
        bg.zPosition = 50
        addChild(bg)

        let progress = SKShapeNode(rectOf: CGSize(width: meterWidth - 2, height: meterHeight - 2), cornerRadius: 5)
        progress.fillColor = .systemYellow
        progress.strokeColor = .clear
        progress.xScale = 0.01
        progress.name = "heat_progress"
        bg.addChild(progress)
        heatMeterNode = progress

        // Frenzy label with flame icon
        let frenzyContainer = SKNode()
        frenzyContainer.position = CGPoint(x: 0, y: 12)
        bg.addChild(frenzyContainer)

        if let flameIcon = UIFactory.symbolSprite("flame.fill", pointSize: 10, color: .white, size: CGSize(width: 10, height: 10)) {
            flameIcon.position = CGPoint(x: -28, y: 0)
            frenzyContainer.addChild(flameIcon)
        }

        let label = SKLabelNode(fontNamed: "Gameplay")
        label.text = "FRENZY"
        label.fontSize = 10
        label.fontColor = .white
        label.position = CGPoint(x: 2, y: -3)
        frenzyContainer.addChild(label)
    }

    private func setupPauseButton() {
        let safeTop = view?.safeAreaInsets.top ?? 50
        let btn = PauseOverlay.createPauseButton(frame: frame, safeTop: safeTop)
        addChild(btn)
        pauseButton = btn
    }

    private func updateLivesUI() {
        let isZen = GameManager.shared.currentMode == .zen

        for (index, node) in heartNodes.enumerated() {
            let isAlive = isZen || index < lives

            // Replace heart icon
            node.childNode(withName: "heart_icon")?.removeFromParent()
            if let heart = Self.makeHeartIcon(filled: isAlive) {
                node.addChild(heart)
            }
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

    // MARK: - Utilities

    private func restartGame() {
        timerController.invalidate()
        removeAction(forKey: "frenzy_timer")
        lives = 3
        level = 1
        scoring.reset()
        shieldActive = false
        slowMoActive = false
        peekUsedThisRound = false
        heartNodes.removeAll()
        removeAllChildren()

        cachedMasterEmojiPool = GameManager.shared.getActivePool(count: 30)

        bgRenderer = BackgroundRenderer(scene: self)
        animations = GameAnimations(scene: self)
        board = GameBoard(scene: self)

        bgRenderer.updateEnvironment(isFrenzyMode: false)
        setupStage()
        setupBaseUI()
        setupOverlays()
        setupHeatMeter()
        setupPauseButton()

        if GameManager.shared.currentMode == .dailyChallenge {
            dailyRoundIndex = 0
            dailyRounds = DailyChallengeManager.shared.generateChallenge(emojiPool: cachedMasterEmojiPool)
        }

        if PowerUpManager.shared.hasPowerUp(.slowMo) {
            slowMoActive = PowerUpManager.shared.consume(.slowMo)
        }
        if PowerUpManager.shared.hasPowerUp(.shield) {
            shieldActive = PowerUpManager.shared.consume(.shield)
        }

        startNewRound()
    }

    private func transitionToMenu() {
        timerController.invalidate()
        let menuScene = MenuScene(size: self.size)
        menuScene.scaleMode = .aspectFill
        let transition = SKTransition.doorsCloseHorizontal(withDuration: 0.8)
        self.view?.presentScene(menuScene, transition: transition)
    }

    private func playSound(_ fileName: String) {
        guard GameManager.shared.soundEnabled else { return }
        run(SKAction.playSoundFileNamed(fileName, waitForCompletion: false))
    }
}
