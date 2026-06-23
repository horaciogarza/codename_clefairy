import SpriteKit

class SettingsScene: SKScene {

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

        // Title
        let title = SKLabelNode(fontNamed: "Gameplay")
        title.text = "SETTINGS"
        title.fontSize = 36
        title.fontColor = .white
        title.position = CGPoint(x: frame.midX, y: frame.maxY - safeTop - 60)
        addChild(title)

        let shadow = SKLabelNode(fontNamed: "Gameplay")
        shadow.text = "SETTINGS"
        shadow.fontSize = 36
        shadow.fontColor = .black.withAlphaComponent(0.5)
        shadow.position = CGPoint(x: 2, y: -2)
        shadow.zPosition = -1
        title.addChild(shadow)

        var yPos = title.position.y - 80

        // Sound Toggle
        let soundToggle = createToggleRow(
            label: "SOUND",
            isOn: GameManager.shared.soundEnabled,
            y: yPos,
            name: "toggle_sound"
        )
        addChild(soundToggle)
        yPos -= 80

        // Haptics Toggle
        let hapticsToggle = createToggleRow(
            label: "HAPTICS",
            isOn: GameManager.shared.hapticsEnabled,
            y: yPos,
            name: "toggle_haptics"
        )
        addChild(hapticsToggle)
        yPos -= 100

        // How To Play
        let howToPlay = UIFactory.createCartoonButton(
            text: "HOW TO PLAY",
            color: .systemPink,
            size: CGSize(width: frame.width * 0.7, height: 60)
        )
        howToPlay.position = CGPoint(x: frame.midX, y: yPos)
        howToPlay.name = "how_to_play"
        addChild(howToPlay)
        yPos -= 80

        // Theme Picker
        let themesBtn = UIFactory.createCartoonButton(
            text: "THEMES",
            color: .systemPurple,
            size: CGSize(width: frame.width * 0.7, height: 60)
        )
        themesBtn.position = CGPoint(x: frame.midX, y: yPos)
        themesBtn.name = "themes"
        addChild(themesBtn)

        // Back — anchored above the banner so it never overlaps on small screens
        let backBtnY = safeBottom + bannerHeight + 45
        let backBtn = UIFactory.createCartoonButton(
            text: "BACK",
            color: .systemBlue,
            size: CGSize(width: frame.width * 0.5, height: 60)
        )
        backBtn.position = CGPoint(x: frame.midX, y: max(backBtnY, yPos - 100))
        backBtn.name = "back"
        addChild(backBtn)
    }

    private func createToggleRow(label: String, isOn: Bool, y: CGFloat, name: String) -> SKNode {
        let container = SKNode()
        container.position = CGPoint(x: frame.midX, y: y)
        container.name = name

        let bg = SKShapeNode(rectOf: CGSize(width: frame.width * 0.7, height: 60), cornerRadius: 15)
        bg.fillColor = .white.withAlphaComponent(0.15)
        bg.strokeColor = .white.withAlphaComponent(0.3)
        bg.lineWidth = 2
        container.addChild(bg)

        let labelNode = SKLabelNode(fontNamed: "Gameplay")
        labelNode.text = label
        labelNode.fontSize = 22
        labelNode.fontColor = .white
        labelNode.horizontalAlignmentMode = .left
        labelNode.verticalAlignmentMode = .center
        labelNode.position = CGPoint(x: -frame.width * 0.3, y: 0)
        container.addChild(labelNode)

        let stateLabel = SKLabelNode(fontNamed: "Gameplay")
        stateLabel.text = isOn ? "ON" : "OFF"
        stateLabel.fontSize = 22
        stateLabel.fontColor = isOn ? .systemGreen : .systemRed
        stateLabel.horizontalAlignmentMode = .right
        stateLabel.verticalAlignmentMode = .center
        stateLabel.position = CGPoint(x: frame.width * 0.3, y: 0)
        stateLabel.name = "state_label"
        container.addChild(stateLabel)

        return container
    }

    private func showThemePicker() {
        if childNode(withName: "theme_overlay") != nil { return }

        let overlay = SKShapeNode(rectOf: self.size)
        overlay.fillColor = .black.withAlphaComponent(0.8)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: frame.midX, y: frame.midY)
        overlay.zPosition = 100
        overlay.name = "theme_overlay"
        addChild(overlay)

        let title = SKLabelNode(fontNamed: "Gameplay")
        title.text = "THEMES"
        title.fontSize = 28
        title.fontColor = .white
        title.position = CGPoint(x: 0, y: frame.height * 0.35)
        title.zPosition = 101
        overlay.addChild(title)

        let themes = ThemeManager.allThemes
        var yPos: CGFloat = frame.height * 0.25

        for theme in themes {
            let row = SKNode()
            row.position = CGPoint(x: 0, y: yPos)
            row.zPosition = 101

            let isUnlocked = theme.isUnlocked()
            let isSelected = ThemeManager.shared.currentTheme.id == theme.id

            let bg = SKShapeNode(rectOf: CGSize(width: frame.width * 0.7, height: 50), cornerRadius: 12)
            bg.fillColor = isSelected ? theme.skyColor.withAlphaComponent(0.8) : .white.withAlphaComponent(0.1)
            bg.strokeColor = isSelected ? .systemYellow : (isUnlocked ? .white.withAlphaComponent(0.3) : .gray.withAlphaComponent(0.3))
            bg.lineWidth = isSelected ? 3 : 1
            row.addChild(bg)

            let nameLabel = SKLabelNode(fontNamed: "Gameplay")
            nameLabel.text = isUnlocked ? theme.name : "🔒 \(theme.name)"
            nameLabel.fontSize = 16
            nameLabel.fontColor = isUnlocked ? .white : .gray
            nameLabel.horizontalAlignmentMode = .left
            nameLabel.verticalAlignmentMode = .center
            nameLabel.position = CGPoint(x: -frame.width * 0.28, y: 5)
            row.addChild(nameLabel)

            if !isUnlocked {
                let reqLabel = SKLabelNode(fontNamed: "Gameplay")
                reqLabel.text = theme.unlockRequirement
                reqLabel.fontSize = 10
                reqLabel.fontColor = .gray
                reqLabel.horizontalAlignmentMode = .left
                reqLabel.verticalAlignmentMode = .center
                reqLabel.position = CGPoint(x: -frame.width * 0.28, y: -10)
                row.addChild(reqLabel)
            }

            if isUnlocked {
                row.name = "theme_\(theme.id)"
            }

            overlay.addChild(row)
            yPos -= 60
        }

        let closeBtn = UIFactory.createCartoonButton(text: "CLOSE", color: .systemRed, size: CGSize(width: 150, height: 45))
        closeBtn.position = CGPoint(x: 0, y: yPos - 20)
        closeBtn.zPosition = 101
        closeBtn.name = "close_themes"
        overlay.addChild(closeBtn)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = self.nodes(at: location)

        for node in nodes {
            let target = node.name == "btn_body" ? node.parent : node

            if let overlay = childNode(withName: "theme_overlay") {
                // Handle theme overlay touches
                if let name = target?.name, name.hasPrefix("theme_") {
                    let themeId = String(name.dropFirst(6))
                    ThemeManager.shared.setCurrentTheme(themeId)
                    hapticFeedback.impactOccurred()
                    overlay.removeFromParent()
                    // Refresh background
                    children.filter { $0.name == nil || !$0.name!.starts(with: "toggle_") }.forEach { $0.removeFromParent() }
                    removeAllChildren()
                    bgRenderer = BackgroundRenderer(scene: self)
                    bgRenderer?.setupMenuBackground()
                    setupUI()
                    return
                }
                if target?.name == "close_themes" || node.name == "close_themes" {
                    hapticFeedback.impactOccurred()
                    overlay.removeFromParent()
                    return
                }
                return
            }

            let nodeName = target?.name ?? node.name

            if nodeName == "toggle_sound" {
                GameManager.shared.soundEnabled.toggle()
                updateToggleState(name: "toggle_sound", isOn: GameManager.shared.soundEnabled)
                hapticFeedback.impactOccurred()
                return
            }

            if nodeName == "toggle_haptics" {
                GameManager.shared.hapticsEnabled.toggle()
                updateToggleState(name: "toggle_haptics", isOn: GameManager.shared.hapticsEnabled)
                hapticFeedback.impactOccurred()
                return
            }

            if nodeName == "how_to_play" {
                UIFactory.animateTap(target ?? node) { [weak self] in
                    guard let self = self else { return }
                    self.hapticFeedback.impactOccurred()
                    let onboarding = OnboardingScene(size: self.size)
                    onboarding.scaleMode = .aspectFill
                    let transition = SKTransition.moveIn(with: .up, duration: 0.5)
                    self.view?.presentScene(onboarding, transition: transition)
                }
                return
            }

            if nodeName == "themes" {
                UIFactory.animateTap(target ?? node) { [weak self] in
                    self?.hapticFeedback.impactOccurred()
                    self?.showThemePicker()
                }
                return
            }

            if nodeName == "back" {
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

    private func updateToggleState(name: String, isOn: Bool) {
        guard let toggle = childNode(withName: name) else { return }
        if let stateLabel = toggle.childNode(withName: "state_label") as? SKLabelNode {
            stateLabel.text = isOn ? "ON" : "OFF"
            stateLabel.fontColor = isOn ? .systemGreen : .systemRed
        }
    }
}
