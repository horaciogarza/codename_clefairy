import SpriteKit

class MenuScene: SKScene {

    private let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedback = UINotificationFeedbackGenerator()
    private var bgRenderer: BackgroundRenderer?

    override func didMove(to view: SKView) {
        bgRenderer = BackgroundRenderer(scene: self)
        bgRenderer?.setupMenuBackground()
        setupUI()

        Task { @MainActor in
            AdManager.shared.showBanner()
        }
    }

    // MARK: - UI

    func setupUI() {
        let shiftY = size.height * 0.05
        let theme = ThemeManager.shared.currentTheme

        // --- Title ---
        let titleNode = SKNode()
        titleNode.position = CGPoint(x: frame.midX, y: frame.midY + (frame.height * 0.3))
        titleNode.zPosition = 5
        addChild(titleNode)

        let titleText = "MEMORANDUM"
        let colors: [SKColor] = [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .magenta, .red, .orange]
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
            shadow.fontColor = .black.withAlphaComponent(0.4)
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

        // --- High Score & Streak ---
        let statsLine = SKNode()
        statsLine.position = CGPoint(x: frame.midX, y: titleNode.position.y - 55)
        statsLine.zPosition = 5
        addChild(statsLine)

        let streak = StatsManager.shared.currentDailyStreak

        let highScoreLabel = SKLabelNode(fontNamed: "Gameplay")
        highScoreLabel.text = "BEST: \(GameManager.shared.highScore)"
        highScoreLabel.fontSize = 18
        highScoreLabel.fontColor = .white
        highScoreLabel.horizontalAlignmentMode = .center
        highScoreLabel.position = CGPoint(x: streak > 0 ? -55 : 0, y: 0)
        statsLine.addChild(highScoreLabel)

        if streak > 0 {
            // Fire icon via SF Symbol
            let streakContainer = SKNode()
            streakContainer.position = CGPoint(x: 65, y: 0)
            statsLine.addChild(streakContainer)

            if let fireIcon = UIFactory.symbolSprite("flame.fill", pointSize: 14, color: .systemOrange, size: CGSize(width: 16, height: 16)) {
                fireIcon.position = CGPoint(x: -35, y: 1)
                streakContainer.addChild(fireIcon)
            }

            let streakLabel = SKLabelNode(fontNamed: "Gameplay")
            streakLabel.text = "\(streak)-DAY STREAK"
            streakLabel.fontSize = 14
            streakLabel.fontColor = .systemOrange
            streakLabel.horizontalAlignmentMode = .left
            streakLabel.verticalAlignmentMode = .center
            streakLabel.position = CGPoint(x: -22, y: 0)
            streakContainer.addChild(streakLabel)
        }

        // --- Layout from bottom up, accounting for banner ad ---
        let safeBottom = view?.safeAreaInsets.bottom ?? 20
        let bannerHeight: CGFloat = 60 // AdMob adaptive banner (~50pt + margin)
        let bottomAnchor = safeBottom + bannerHeight + 10

        // --- How To Play (bottom center) ---
        let infoBtn = UIFactory.createButtonWithIcon(
            text: "HOW TO PLAY",
            systemName: "questionmark.circle.fill",
            color: .systemPink,
            size: CGSize(width: 185, height: 44),
            iconSize: 15
        )
        infoBtn.position = CGPoint(x: frame.midX, y: bottomAnchor + 22)
        infoBtn.name = "info"
        infoBtn.zPosition = 5
        addChild(infoBtn)

        // --- Bottom Icon Row ---
        let iconY = infoBtn.position.y + 62
        let iconSpacing: CGFloat = 68
        let startX = frame.midX - (iconSpacing * 1.5)

        let settingsBtn = UIFactory.createIconButton(systemName: "gearshape.fill", color: .systemGray, size: 50, iconSize: 22)
        settingsBtn.position = CGPoint(x: startX, y: iconY)
        settingsBtn.name = "settings"
        settingsBtn.zPosition = 5
        addChild(settingsBtn)

        let statsBtn = UIFactory.createIconButton(systemName: "chart.bar.fill", color: .systemIndigo, size: 50, iconSize: 22)
        statsBtn.position = CGPoint(x: startX + iconSpacing, y: iconY)
        statsBtn.name = "stats"
        statsBtn.zPosition = 5
        addChild(statsBtn)

        let themesBtn = UIFactory.createIconButton(systemName: "paintbrush.fill", color: .systemPurple, size: 50, iconSize: 22)
        themesBtn.position = CGPoint(x: startX + iconSpacing * 2, y: iconY)
        themesBtn.name = "themes_btn"
        themesBtn.zPosition = 5
        addChild(themesBtn)

        let achievementsBtn = UIFactory.createIconButton(systemName: "trophy.fill", color: .systemYellow, size: 50, iconSize: 22)
        achievementsBtn.position = CGPoint(x: startX + iconSpacing * 3, y: iconY)
        achievementsBtn.name = "achievements"
        achievementsBtn.zPosition = 5
        addChild(achievementsBtn)

        // --- Daily Challenge ---
        let dailyCompleted = DailyChallengeManager.shared.hasCompletedToday

        let dailyBtn = UIFactory.createButtonWithIcon(
            text: dailyCompleted ? "DAILY (DONE)" : "DAILY",
            systemName: dailyCompleted ? "checkmark.circle.fill" : "calendar",
            color: dailyCompleted ? .gray : .systemOrange,
            size: CGSize(width: frame.width * 0.72, height: 60),
            iconSize: 19
        )
        dailyBtn.position = CGPoint(x: frame.midX, y: iconY + 68)
        dailyBtn.name = "play_daily"
        dailyBtn.zPosition = 5
        addChild(dailyBtn)

        // --- Play Zen ---
        let playZenBtn = UIFactory.createButtonWithIcon(
            text: "PLAY ZEN",
            systemName: "leaf.fill",
            color: .systemBlue,
            size: CGSize(width: frame.width * 0.72, height: 60),
            iconSize: 19
        )
        playZenBtn.position = CGPoint(x: frame.midX, y: dailyBtn.position.y + 76)
        playZenBtn.name = "play_zen"
        playZenBtn.zPosition = 5
        addChild(playZenBtn)

        // --- Play Classic (main CTA) ---
        let playClassicBtn = UIFactory.createButtonWithIcon(
            text: "PLAY CLASSIC",
            systemName: "play.fill",
            color: .systemGreen,
            size: CGSize(width: frame.width * 0.72, height: 72),
            iconSize: 21
        )
        playClassicBtn.position = CGPoint(x: frame.midX, y: playZenBtn.position.y + 80)
        playClassicBtn.name = "play_classic"
        playClassicBtn.zPosition = 5
        addChild(playClassicBtn)

        let classicPulse = SKAction.sequence([
            SKAction.scale(to: 1.04, duration: 0.7),
            SKAction.scale(to: 0.96, duration: 0.7)
        ])
        playClassicBtn.run(SKAction.repeatForever(classicPulse))

        // --- First launch ---
        if !UserDefaults.standard.bool(forKey: "HasLaunchedBefore") {
            UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
            run(SKAction.wait(forDuration: 0.1)) { [weak self] in
                self?.transitionToOnboarding()
            }
        }
    }

    // MARK: - Navigation

    private func transitionToOnboarding() {
        let onboarding = OnboardingScene(size: self.size)
        onboarding.scaleMode = .aspectFill
        let transition = SKTransition.moveIn(with: .up, duration: 0.5)
        view?.presentScene(onboarding, transition: transition)
    }

    // MARK: - Achievements Popup

    private func showAchievementsPopup() {
        if childNode(withName: "popup_overlay") != nil { return }

        let overlay = SKShapeNode(rectOf: self.size)
        overlay.fillColor = .black.withAlphaComponent(0.85)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: frame.midX, y: frame.midY)
        overlay.zPosition = 100
        overlay.name = "popup_overlay"
        addChild(overlay)

        // Header
        let headerIcon = SKNode()
        headerIcon.position = CGPoint(x: 0, y: frame.height * 0.37)
        headerIcon.zPosition = 101
        overlay.addChild(headerIcon)

        if let trophy = UIFactory.symbolSprite("trophy.fill", pointSize: 28, color: .systemYellow, size: CGSize(width: 30, height: 30)) {
            trophy.position = CGPoint(x: -80, y: 2)
            headerIcon.addChild(trophy)
        }

        let title = SKLabelNode(fontNamed: "Gameplay")
        title.text = "ACHIEVEMENTS"
        title.fontSize = 26
        title.fontColor = .systemYellow
        title.horizontalAlignmentMode = .left
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: -58, y: 0)
        headerIcon.addChild(title)

        // Count badge
        let unlockedCount = AchievementManager.shared.unlockedCount
        let totalCount = AchievementManager.allAchievements.count
        let countLabel = SKLabelNode(fontNamed: "Gameplay")
        countLabel.text = "\(unlockedCount)/\(totalCount)"
        countLabel.fontSize = 14
        countLabel.fontColor = .lightGray
        countLabel.position = CGPoint(x: 0, y: frame.height * 0.33)
        countLabel.zPosition = 101
        overlay.addChild(countLabel)

        var yPos: CGFloat = frame.height * 0.27

        for achievement in AchievementManager.allAchievements {
            let isUnlocked = AchievementManager.shared.isUnlocked(achievement.id)

            let row = SKNode()
            row.position = CGPoint(x: 0, y: yPos)
            row.zPosition = 101

            let bg = SKShapeNode(rectOf: CGSize(width: frame.width * 0.78, height: 40), cornerRadius: 10)
            bg.fillColor = isUnlocked ? .white.withAlphaComponent(0.12) : .black.withAlphaComponent(0.3)
            bg.strokeColor = isUnlocked ? .systemYellow.withAlphaComponent(0.4) : .gray.withAlphaComponent(0.15)
            bg.lineWidth = 1
            row.addChild(bg)

            // Status icon
            let iconName = isUnlocked ? "checkmark.seal.fill" : "lock.fill"
            let iconColor: UIColor = isUnlocked ? .systemYellow : .gray
            if let icon = UIFactory.symbolSprite(iconName, pointSize: 16, weight: .medium, color: iconColor, size: CGSize(width: 18, height: 18)) {
                icon.position = CGPoint(x: -frame.width * 0.33, y: 0)
                row.addChild(icon)
            }

            let nameLabel = SKLabelNode(fontNamed: "Gameplay")
            nameLabel.text = achievement.name
            nameLabel.fontSize = 12
            nameLabel.fontColor = isUnlocked ? .white : .gray
            nameLabel.horizontalAlignmentMode = .left
            nameLabel.verticalAlignmentMode = .center
            nameLabel.position = CGPoint(x: -frame.width * 0.25, y: 5)
            row.addChild(nameLabel)

            let descLabel = SKLabelNode(fontNamed: "Gameplay")
            descLabel.text = achievement.description
            descLabel.fontSize = 9
            descLabel.fontColor = isUnlocked ? .lightGray : .darkGray
            descLabel.horizontalAlignmentMode = .left
            descLabel.verticalAlignmentMode = .center
            descLabel.position = CGPoint(x: -frame.width * 0.25, y: -8)
            row.addChild(descLabel)

            overlay.addChild(row)
            yPos -= 44
        }

        // Close button with icon
        let closeBtn = UIFactory.createButtonWithIcon(
            text: "CLOSE",
            systemName: "xmark",
            color: .systemRed,
            size: CGSize(width: 150, height: 45),
            iconSize: 14
        )
        closeBtn.position = CGPoint(x: 0, y: yPos - 20)
        closeBtn.zPosition = 101
        closeBtn.name = "close_popup"
        overlay.addChild(closeBtn)
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = self.nodes(at: location)

        // Handle popup
        if let overlay = childNode(withName: "popup_overlay") {
            for node in nodes {
                let target = node.name == "btn_body" ? node.parent : node
                if target?.name == "close_popup" || node.name == "close_popup" {
                    overlay.removeFromParent()
                    haptic()
                    return
                }
            }
            overlay.removeFromParent()
            haptic()
            return
        }

        for node in nodes {
            let parent = (node.name == "btn_body" || node.name == "btn_label") ? node.parent : node
            let nodeName = parent?.name ?? node.name
            let feedbackTarget = parent ?? node

            switch nodeName {
            case "play_classic":
                UIFactory.animateTap(feedbackTarget) { [weak self] in
                    self?.haptic()
                    GameManager.shared.currentMode = .classic
                    self?.transitionToGame()
                }
            case "play_zen":
                UIFactory.animateTap(feedbackTarget) { [weak self] in
                    self?.haptic()
                    GameManager.shared.currentMode = .zen
                    self?.transitionToGame()
                }
            case "play_daily":
                guard !DailyChallengeManager.shared.hasCompletedToday else { return }
                UIFactory.animateTap(feedbackTarget) { [weak self] in
                    self?.haptic()
                    GameManager.shared.currentMode = .dailyChallenge
                    self?.transitionToGame()
                }
            case "info":
                UIFactory.animateTap(feedbackTarget) { [weak self] in
                    self?.haptic()
                    self?.transitionToOnboarding()
                }
            case "settings":
                UIFactory.animateTap(feedbackTarget) { [weak self] in
                    guard let self = self else { return }
                    self.haptic()
                    let settings = SettingsScene(size: self.size)
                    settings.scaleMode = .aspectFill
                    self.view?.presentScene(settings, transition: SKTransition.fade(withDuration: 0.5))
                }
            case "stats":
                UIFactory.animateTap(feedbackTarget) { [weak self] in
                    guard let self = self else { return }
                    self.haptic()
                    let statsScene = StatsScene(size: self.size)
                    statsScene.scaleMode = .aspectFill
                    self.view?.presentScene(statsScene, transition: SKTransition.fade(withDuration: 0.5))
                }
            case "themes_btn":
                UIFactory.animateTap(feedbackTarget) { [weak self] in
                    guard let self = self else { return }
                    self.haptic()
                    let settings = SettingsScene(size: self.size)
                    settings.scaleMode = .aspectFill
                    self.view?.presentScene(settings, transition: SKTransition.fade(withDuration: 0.5))
                }
            case "achievements":
                UIFactory.animateTap(feedbackTarget) { [weak self] in
                    self?.haptic()
                    self?.showAchievementsPopup()
                }
            default:
                break
            }
        }
    }

    // MARK: - Transitions

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

    // MARK: - Helpers

    private func haptic() {
        guard GameManager.shared.hapticsEnabled else { return }
        hapticFeedback.impactOccurred()
    }

    private func playSound(_ fileName: String) {
        guard GameManager.shared.soundEnabled else { return }
        run(SKAction.playSoundFileNamed(fileName, waitForCompletion: false))
    }
}
