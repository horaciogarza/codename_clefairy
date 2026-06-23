import SpriteKit

class StatsScene: SKScene {

    private let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    private var bgRenderer: BackgroundRenderer?

    override func didMove(to view: SKView) {
        bgRenderer = BackgroundRenderer(scene: self)
        bgRenderer?.setupMenuBackground()
        setupUI()

        Task { @MainActor in
            AdManager.shared.showBanner()
        }
    }

    private func setupUI() {
        let safeTop = view?.safeAreaInsets.top ?? 50
        let safeBottom = view?.safeAreaInsets.bottom ?? 20
        let bannerHeight: CGFloat = 60
        let stats = StatsManager.shared

        // Title
        let title = SKLabelNode(fontNamed: "Gameplay")
        title.text = "STATISTICS"
        title.fontSize = 36
        title.fontColor = .white
        title.position = CGPoint(x: frame.midX, y: frame.maxY - safeTop - 60)
        addChild(title)

        let shadow = SKLabelNode(fontNamed: "Gameplay")
        shadow.text = "STATISTICS"
        shadow.fontSize = 36
        shadow.fontColor = .black.withAlphaComponent(0.5)
        shadow.position = CGPoint(x: 2, y: -2)
        shadow.zPosition = -1
        title.addChild(shadow)

        // Stats list
        let statItems: [(String, String)] = [
            ("GAMES PLAYED", "\(stats.totalGamesPlayed)"),
            ("HIGHEST LEVEL", "\(stats.highestLevelReached)"),
            ("HIGH SCORE", "\(GameManager.shared.highScore)"),
            ("BOSSES DEFEATED", "\(stats.totalBossesDefeated)"),
            ("FRENZIES TRIGGERED", "\(stats.totalFrenziesTriggered)"),
            ("BEST COMBO", "\(stats.bestComboStreak)"),
            ("TIME PLAYED", formatTime(stats.totalTimePlayed)),
            ("CURRENT STREAK", "\(stats.currentDailyStreak) days"),
            ("LONGEST STREAK", "\(stats.longestDailyStreak) days"),
            ("ACHIEVEMENTS", "\(AchievementManager.shared.unlockedCount)/\(AchievementManager.allAchievements.count)"),
        ]

        // Back button anchored above the banner so it never overlaps on small screens
        let backBtnY = safeBottom + bannerHeight + 45
        let backBtn = UIFactory.createCartoonButton(
            text: "BACK",
            color: .systemBlue,
            size: CGSize(width: frame.width * 0.5, height: 55)
        )
        backBtn.position = CGPoint(x: frame.midX, y: backBtnY)
        backBtn.name = "back"
        addChild(backBtn)

        // Distribute rows evenly in the space between title and back button
        let rowsTop = title.position.y - 65
        let rowsBottom = backBtnY + 50
        let availableHeight = rowsTop - rowsBottom
        let spacing = min(48, max(36, availableHeight / CGFloat(statItems.count)))

        var yPos = rowsTop

        for (label, value) in statItems {
            let row = SKNode()
            row.position = CGPoint(x: frame.midX, y: yPos)

            let bg = SKShapeNode(rectOf: CGSize(width: frame.width * 0.85, height: 38), cornerRadius: 10)
            bg.fillColor = .white.withAlphaComponent(0.1)
            bg.strokeColor = .clear
            row.addChild(bg)

            let labelNode = SKLabelNode(fontNamed: "Gameplay")
            labelNode.text = label
            labelNode.fontSize = 13
            labelNode.fontColor = .lightGray
            labelNode.horizontalAlignmentMode = .left
            labelNode.verticalAlignmentMode = .center
            labelNode.position = CGPoint(x: -frame.width * 0.38, y: 0)
            row.addChild(labelNode)

            let valueNode = SKLabelNode(fontNamed: "Gameplay")
            valueNode.text = value
            valueNode.fontSize = 15
            valueNode.fontColor = .white
            valueNode.horizontalAlignmentMode = .right
            valueNode.verticalAlignmentMode = .center
            valueNode.position = CGPoint(x: frame.width * 0.38, y: 0)
            row.addChild(valueNode)

            addChild(row)
            yPos -= spacing
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = self.nodes(at: location)

        for node in nodes {
            let target = node.name == "btn_body" ? node.parent : node

            if target?.name == "back" || node.name == "back" {
                UIFactory.animateTap(target ?? node) { [weak self] in
                    guard let self = self else { return }
                    self.hapticFeedback.impactOccurred()
                    let menu = MenuScene(size: self.size)
                    menu.scaleMode = .aspectFill
                    let transition = SKTransition.fade(withDuration: 0.5)
                    self.view?.presentScene(menu, transition: transition)
                }
                return
            }
        }
    }
}
