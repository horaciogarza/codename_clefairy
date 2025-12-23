import SpriteKit

class StoreScene: SKScene {

    // MARK: - Properties
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedback = UINotificationFeedbackGenerator()

    private var currentCategory: StoreCategory = .skins
    private var currentFilter: StoreFilter = .all

    private var coinLabel: SKLabelNode?
    private var contentNode: SKNode?
    private var scrollContentNode: SKNode?
    private var tabButtons: [StoreCategory: SKNode] = [:]
    private var filterButtons: [StoreFilter: SKNode] = [:]

    private var previewOverlay: SKNode?
    private var confirmOverlay: SKNode?

    // Scroll properties
    private var scrollOffset: CGFloat = 0
    private var maxScrollOffset: CGFloat = 0
    private var isDragging = false
    private var lastTouchY: CGFloat = 0
    private var velocity: CGFloat = 0

    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.95, green: 0.92, blue: 1.0, alpha: 1.0)
        setupBackground()
        setupHeader()
        setupTabs()
        setupFilters()
        setupContentArea()
        loadCategoryItems()
    }

    // MARK: - Background Setup
    private func setupBackground() {
        // Gradient-like background with shapes
        let topGradient = SKShapeNode(rectOf: CGSize(width: frame.width, height: frame.height * 0.4))
        topGradient.fillColor = SKColor(red: 0.6, green: 0.4, blue: 0.9, alpha: 0.15)
        topGradient.strokeColor = .clear
        topGradient.position = CGPoint(x: frame.midX, y: frame.maxY - frame.height * 0.2)
        topGradient.zPosition = -10
        addChild(topGradient)

        // Floating decorative shapes
        for _ in 0..<8 {
            let shape = SKShapeNode(circleOfRadius: CGFloat.random(in: 20...60))
            shape.fillColor = [
                SKColor(red: 1.0, green: 0.6, blue: 0.8, alpha: 0.1),
                SKColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 0.1),
                SKColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 0.1)
            ].randomElement()!
            shape.strokeColor = .clear
            shape.position = CGPoint(
                x: CGFloat.random(in: 0...frame.width),
                y: CGFloat.random(in: 0...frame.height)
            )
            shape.zPosition = -9
            addChild(shape)

            let float = SKAction.sequence([
                SKAction.moveBy(x: CGFloat.random(in: -20...20), y: CGFloat.random(in: 10...30), duration: Double.random(in: 3...5)),
                SKAction.moveBy(x: CGFloat.random(in: -20...20), y: CGFloat.random(in: (-30)...(-10)), duration: Double.random(in: 3...5))
            ])
            shape.run(SKAction.repeatForever(float))
        }
    }

    // MARK: - Header Setup
    private func setupHeader() {
        let safeTop = view?.safeAreaInsets.top ?? 50
        let headerY = frame.maxY - safeTop - 30

        // Back button
        let backBtn = createIconButton(emoji: "←", color: SKColor(red: 0.9, green: 0.5, blue: 0.6, alpha: 1.0))
        backBtn.position = CGPoint(x: 45, y: headerY)
        backBtn.name = "back_btn"
        addChild(backBtn)

        // Title
        let titleContainer = SKNode()
        titleContainer.position = CGPoint(x: frame.midX, y: headerY)
        addChild(titleContainer)

        let titleShadow = SKLabelNode(fontNamed: "Gameplay")
        titleShadow.text = "STORE"
        titleShadow.fontSize = 36
        titleShadow.fontColor = .black.withAlphaComponent(0.2)
        titleShadow.position = CGPoint(x: 2, y: -2)
        titleContainer.addChild(titleShadow)

        let title = SKLabelNode(fontNamed: "Gameplay")
        title.text = "STORE"
        title.fontSize = 36
        title.fontColor = SKColor(red: 0.4, green: 0.2, blue: 0.6, alpha: 1.0)
        titleContainer.addChild(title)

        let storeEmoji = SKLabelNode(text: "🛒")
        storeEmoji.fontSize = 30
        storeEmoji.position = CGPoint(x: -70, y: -5)
        titleContainer.addChild(storeEmoji)

        // Coin display
        let coinContainer = SKNode()
        coinContainer.position = CGPoint(x: frame.maxX - 80, y: headerY)
        addChild(coinContainer)

        let coinBg = SKShapeNode(rectOf: CGSize(width: 120, height: 40), cornerRadius: 20)
        coinBg.fillColor = .white.withAlphaComponent(0.95)
        coinBg.strokeColor = SKColor(red: 1.0, green: 0.75, blue: 0.2, alpha: 1.0)
        coinBg.lineWidth = 3
        coinContainer.addChild(coinBg)

        coinLabel = SKLabelNode(fontNamed: "Gameplay")
        coinLabel?.text = "💰 \(GameManager.shared.totalCoins)"
        coinLabel?.fontSize = 18
        coinLabel?.fontColor = .black
        coinLabel?.verticalAlignmentMode = .center
        coinContainer.addChild(coinLabel!)
    }

    // MARK: - Tab Setup
    private func setupTabs() {
        let safeBottom = view?.safeAreaInsets.bottom ?? 20
        let tabBarHeight: CGFloat = 80
        // Move slightly up for floating effect
        let tabY = safeBottom + tabBarHeight/2 + 5
        
        // Liquid Glass Tab Bar Background (Floating Pill)
        let barWidth = frame.width * 0.92
        let tabBarBg = SKShapeNode(rectOf: CGSize(width: barWidth, height: tabBarHeight), cornerRadius: 40)
        
        // Glass Effect: Red tint, low alpha
        tabBarBg.fillColor = SKColor.systemRed.withAlphaComponent(0.15)
        tabBarBg.strokeColor = SKColor.white.withAlphaComponent(0.4)
        tabBarBg.lineWidth = 1.5
        
        // Add a subtle glow/shadow
        let shadow = SKShapeNode(rectOf: CGSize(width: barWidth, height: tabBarHeight), cornerRadius: 40)
        shadow.fillColor = .clear
        shadow.strokeColor = SKColor.systemRed.withAlphaComponent(0.3)
        shadow.lineWidth = 4
        shadow.glowWidth = 6
        shadow.position = .zero
        tabBarBg.addChild(shadow)
        
        tabBarBg.position = CGPoint(x: frame.midX, y: tabY)
        tabBarBg.zPosition = 100
        addChild(tabBarBg)

        let categories = StoreCategory.allCases
        let tabWidth: CGFloat = barWidth / CGFloat(categories.count)
        let startX = frame.midX - barWidth/2 + tabWidth/2

        for (index, category) in categories.enumerated() {
            let tabBtn = createTabButton(category: category, width: tabWidth)
            tabBtn.position = CGPoint(x: startX + tabWidth * CGFloat(index), y: tabY)
            tabBtn.zPosition = 101
            tabBtn.name = "tab_\(category.rawValue)"
            addChild(tabBtn)
            tabButtons[category] = tabBtn
        }

        updateTabSelection()
    }

    private func createTabButton(category: StoreCategory, width: CGFloat) -> SKNode {
        let container = SKNode()
        
        // Touch area
        let bg = SKShapeNode(rectOf: CGSize(width: width, height: 60))
        bg.fillColor = .clear
        bg.strokeColor = .clear
        bg.name = "internal_bg" // Used for touch detection
        container.addChild(bg)

        // Icon using SF Symbols
        let iconName = getIconName(for: category)
        if let image = UIImage(systemName: iconName)?.withRenderingMode(.alwaysTemplate) {
            let texture = SKTexture(image: image)
            let sprite = SKSpriteNode(texture: texture)
            sprite.size = CGSize(width: 28, height: 26)
            sprite.color = .white
            sprite.colorBlendFactor = 1.0
            sprite.name = "internal_icon"
            sprite.position = CGPoint(x: 0, y: 0) // Centered if no label, or shift up
            container.addChild(sprite)
        }

        // Removed label for cleaner "liquid" look, or keep it very small/subtle? 
        // Let's keep it but very small and clean.
        let label = SKLabelNode(fontNamed: "Gameplay")
        label.text = category.rawValue
        label.fontSize = 9
        label.fontColor = .white
        label.position = CGPoint(x: 0, y: -20)
        label.name = "internal_label"
        label.alpha = 0.7
        container.addChild(label)
        
        // Adjust icon position to make room for label
        if let icon = container.childNode(withName: "internal_icon") {
            icon.position = CGPoint(x: 0, y: 5)
        }

        return container
    }
    
    private func getIconName(for category: StoreCategory) -> String {
        switch category {
        case .skins: return "paintpalette.fill"
        case .themes: return "photo.fill"
        case .emojis: return "face.smiling.fill"
        case .effects: return "sparkles"
        case .powerups: return "bolt.fill"
        }
    }

    private func updateTabSelection() {
        for (category, node) in tabButtons {
            let isSelected = (category == currentCategory)
            
            // Active: Bright Red/White hybrid. Inactive: Muted Red/Gray.
            let activeColor = SKColor.systemRed
            let inactiveColor = SKColor.systemRed.withAlphaComponent(0.4)
            
            if let icon = node.childNode(withName: "internal_icon") as? SKSpriteNode {
                icon.color = isSelected ? activeColor : inactiveColor
                
                // Pop animation for selected
                if isSelected {
                    // Reset scale first
                    icon.setScale(1.0)
                    icon.run(SKAction.sequence([
                        SKAction.scale(to: 1.3, duration: 0.15),
                        SKAction.scale(to: 1.0, duration: 0.1)
                    ]))
                    
                    // Add a subtle glow behind active icon
                    if node.childNode(withName: "active_glow") == nil {
                        let glow = SKShapeNode(circleOfRadius: 20)
                        glow.fillColor = SKColor.white.withAlphaComponent(0.3)
                        glow.strokeColor = .clear
                        glow.name = "active_glow"
                        glow.zPosition = -1
                        node.addChild(glow)
                        glow.run(SKAction.sequence([
                            SKAction.scale(to: 1.2, duration: 0.2),
                            SKAction.fadeOut(withDuration: 0.2),
                            SKAction.removeFromParent()
                        ]))
                    }
                }
            }
            
            if let label = node.childNode(withName: "internal_label") as? SKLabelNode {
                label.fontColor = isSelected ? activeColor : inactiveColor
                label.alpha = isSelected ? 1.0 : 0.6
            }
        }
    }

    // MARK: - Filter Setup
    private func setupFilters() {
        let safeTop = view?.safeAreaInsets.top ?? 50
        // Moved higher since tabs are at bottom
        let filterY = frame.maxY - safeTop - 90

        let filters = StoreFilter.allCases
        let filterWidth: CGFloat = 75

        let startX = frame.midX - (CGFloat(filters.count) * filterWidth) / 2 + filterWidth/2

        for (index, filter) in filters.enumerated() {
            let filterBtn = createFilterButton(filter: filter)
            filterBtn.position = CGPoint(x: startX + CGFloat(index) * filterWidth, y: filterY)
            filterBtn.name = "filter_\(filter.rawValue)"
            addChild(filterBtn)
            filterButtons[filter] = filterBtn
        }

        updateFilterSelection()
    }

    private func createFilterButton(filter: StoreFilter) -> SKNode {
        let container = SKNode()

        let bg = SKShapeNode(rectOf: CGSize(width: 70, height: 30), cornerRadius: 15)
        bg.fillColor = .white.withAlphaComponent(0.8)
        bg.strokeColor = .gray.withAlphaComponent(0.3)
        bg.lineWidth = 1
        bg.name = "filter_bg"
        container.addChild(bg)

        let label = SKLabelNode(fontNamed: "Gameplay")
        label.text = "\(filter.icon) \(filter.rawValue)"
        label.fontSize = 10
        label.fontColor = .darkGray
        label.verticalAlignmentMode = .center
        container.addChild(label)

        return container
    }

    private func updateFilterSelection() {
        for (filter, node) in filterButtons {
            if let bg = node.childNode(withName: "filter_bg") as? SKShapeNode {
                if filter == currentFilter {
                    bg.fillColor = SKColor(red: 0.5, green: 0.8, blue: 0.6, alpha: 1.0)
                    bg.strokeColor = SKColor(red: 0.3, green: 0.6, blue: 0.4, alpha: 1.0)
                } else {
                    bg.fillColor = .white.withAlphaComponent(0.8)
                    bg.strokeColor = .gray.withAlphaComponent(0.3)
                }
            }
        }
    }

    // MARK: - Content Area Setup
    private func setupContentArea() {
        let safeTop = view?.safeAreaInsets.top ?? 50
        let safeBottom = view?.safeAreaInsets.bottom ?? 0
        let tabBarHeight: CGFloat = 80
        
        let contentTop = frame.maxY - safeTop - 120
        let contentBottom = safeBottom + tabBarHeight + 10

        // Content container with clipping
        contentNode = SKNode()
        contentNode?.position = CGPoint(x: 0, y: contentBottom)
        contentNode?.zPosition = 1
        addChild(contentNode!)

        // Create a crop node for clipping
        let cropNode = SKCropNode()
        let maskShape = SKShapeNode(rectOf: CGSize(width: frame.width, height: contentTop - contentBottom))
        maskShape.fillColor = .white
        cropNode.maskNode = maskShape
        cropNode.position = CGPoint(x: frame.midX, y: (contentTop - contentBottom) / 2)
        contentNode?.addChild(cropNode)

        scrollContentNode = SKNode()
        let contentHeight = contentTop - contentBottom
        scrollContentNode?.position = CGPoint(x: -frame.midX, y: contentHeight / 2)
        cropNode.addChild(scrollContentNode!)
    }

    // MARK: - Load Items
    private func loadCategoryItems() {
        scrollContentNode?.removeAllChildren()
        scrollOffset = 0

        let safeTop = view?.safeAreaInsets.top ?? 50
        let safeBottom = view?.safeAreaInsets.bottom ?? 0
        let tabBarHeight: CGFloat = 80
        
        let contentTop = frame.maxY - safeTop - 120
        let contentBottom = safeBottom + tabBarHeight + 10
        let contentHeight = contentTop - contentBottom

        // Reset scroll position
        scrollContentNode?.position.y = contentHeight / 2

        var items: [(name: String, emoji: String, desc: String, cost: Int, isOwned: Bool, isSelected: Bool, id: String)] = []

        switch currentCategory {
        case .skins:
            for skin in ButtonSkin.allCases {
                let isOwned = GameManager.shared.unlockedSkins.contains(skin)
                let isSelected = GameManager.shared.selectedSkin == skin
                items.append((skin.rawValue, skin.previewEmoji, skin.description, skin.cost, isOwned, isSelected, "skin_\(skin.rawValue)"))
            }
        case .themes:
            for theme in BackgroundTheme.allCases {
                let isOwned = GameManager.shared.unlockedThemes.contains(theme)
                let isSelected = GameManager.shared.selectedTheme == theme
                items.append((theme.rawValue, theme.accentEmoji, theme.description, theme.cost, isOwned, isSelected, "theme_\(theme.rawValue)"))
            }
        case .emojis:
            for pack in EmojiPack.allCases {
                let isOwned = GameManager.shared.unlockedEmojiPacks.contains(pack)
                let isSelected = GameManager.shared.selectedEmojiPack == pack
                items.append((pack.rawValue, pack.previewEmoji, pack.description, pack.cost, isOwned, isSelected, "emoji_\(pack.rawValue)"))
            }
        case .effects:
            for effect in SpecialEffectPack.allCases {
                let isOwned = GameManager.shared.unlockedEffects.contains(effect)
                let isSelected = GameManager.shared.selectedEffect == effect
                items.append((effect.rawValue, effect.previewEmoji, effect.description, effect.cost, isOwned, isSelected, "effect_\(effect.rawValue)"))
            }
        case .powerups:
            for powerUp in PowerUp.allCases {
                let count = GameManager.shared.getPowerUpCount(powerUp)
                items.append((powerUp.rawValue, powerUp.previewEmoji, powerUp.description, powerUp.cost, false, false, "powerup_\(powerUp.rawValue)"))
            }
        }

        // Apply filter
        let filteredItems = items.filter { item in
            switch currentFilter {
            case .all: return true
            case .owned: return item.isOwned || currentCategory == .powerups
            case .affordable: return GameManager.shared.totalCoins >= item.cost
            case .notOwned: return !item.isOwned && currentCategory != .powerups
            }
        }

        let cardHeight: CGFloat = 110
        let spacing: CGFloat = 15
        let startY = contentHeight - cardHeight/2 - 10

        for (index, item) in filteredItems.enumerated() {
            let card = createItemCard(
                name: item.name,
                emoji: item.emoji,
                description: item.desc,
                cost: item.cost,
                isOwned: item.isOwned,
                isSelected: item.isSelected,
                itemId: item.id
            )
            card.position = CGPoint(x: frame.midX, y: startY - CGFloat(index) * (cardHeight + spacing))
            scrollContentNode?.addChild(card)
        }

        let totalContentHeight = CGFloat(filteredItems.count) * (cardHeight + spacing) + 20
        maxScrollOffset = max(0, totalContentHeight - contentHeight)

        // Show empty state if no items
        if filteredItems.isEmpty {
            let emptyLabel = SKLabelNode(fontNamed: "Gameplay")
            emptyLabel.text = "No items found"
            emptyLabel.fontSize = 20
            emptyLabel.fontColor = .gray
            emptyLabel.position = CGPoint(x: frame.midX, y: contentHeight / 2)
            scrollContentNode?.addChild(emptyLabel)
        }
    }

    // MARK: - Item Card
    private func createItemCard(name: String, emoji: String, description: String, cost: Int, isOwned: Bool, isSelected: Bool, itemId: String) -> SKNode {
        let container = SKNode()
        container.name = itemId

        let cardWidth = frame.width - 40
        let cardHeight: CGFloat = 100

        // Card shadow
        let shadow = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: 20)
        shadow.fillColor = .black.withAlphaComponent(0.15)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 4, y: -4)
        container.addChild(shadow)

        // Card background
        let cardBg = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: 20)
        cardBg.fillColor = .white
        cardBg.strokeColor = isSelected ? SKColor(red: 0.3, green: 0.8, blue: 0.4, alpha: 1.0) : SKColor(red: 0.85, green: 0.85, blue: 0.9, alpha: 1.0)
        cardBg.lineWidth = isSelected ? 4 : 2
        cardBg.name = "card_bg"
        container.addChild(cardBg)

        // Selected badge
        if isSelected {
            let badge = SKShapeNode(rectOf: CGSize(width: 70, height: 22), cornerRadius: 11)
            badge.fillColor = SKColor(red: 0.3, green: 0.8, blue: 0.4, alpha: 1.0)
            badge.strokeColor = .clear
            badge.position = CGPoint(x: cardWidth/2 - 50, y: cardHeight/2 - 15)
            container.addChild(badge)

            let badgeLabel = SKLabelNode(fontNamed: "Gameplay")
            badgeLabel.text = "IN USE"
            badgeLabel.fontSize = 10
            badgeLabel.fontColor = .white
            badgeLabel.verticalAlignmentMode = .center
            badgeLabel.position = badge.position
            container.addChild(badgeLabel)
        }

        // Preview circle
        let previewContainer = SKNode()
        previewContainer.position = CGPoint(x: -cardWidth/2 + 55, y: 0)
        container.addChild(previewContainer)

        let previewBg = SKShapeNode(circleOfRadius: 35)
        previewBg.fillColor = SKColor(red: 0.95, green: 0.93, blue: 0.98, alpha: 1.0)
        previewBg.strokeColor = SKColor(red: 0.8, green: 0.7, blue: 0.9, alpha: 1.0)
        previewBg.lineWidth = 2
        previewContainer.addChild(previewBg)

        let emojiLabel = SKLabelNode(text: emoji)
        emojiLabel.fontSize = 35
        emojiLabel.verticalAlignmentMode = .center
        previewContainer.addChild(emojiLabel)

        // Item info
        let nameLabel = SKLabelNode(fontNamed: "Gameplay")
        nameLabel.text = name.uppercased()
        nameLabel.fontSize = 18
        nameLabel.fontColor = .black
        nameLabel.horizontalAlignmentMode = .left
        nameLabel.position = CGPoint(x: -cardWidth/2 + 110, y: 15)
        container.addChild(nameLabel)

        let descLabel = SKLabelNode(fontNamed: "Gameplay")
        descLabel.text = description
        descLabel.fontSize = 12
        descLabel.fontColor = .gray
        descLabel.horizontalAlignmentMode = .left
        descLabel.position = CGPoint(x: -cardWidth/2 + 110, y: -5)
        container.addChild(descLabel)

        // Price/status
        let priceLabel = SKLabelNode(fontNamed: "Gameplay")
        if currentCategory == .powerups {
            let count = GameManager.shared.getPowerUpCount(PowerUp(rawValue: name) ?? .hint)
            priceLabel.text = "Owned: \(count)"
            priceLabel.fontColor = .systemBlue
        } else if isOwned {
            priceLabel.text = "OWNED"
            priceLabel.fontColor = .systemGreen
        } else {
            priceLabel.text = "💰 \(cost)"
            priceLabel.fontColor = GameManager.shared.totalCoins >= cost ? .black : .systemRed
        }
        priceLabel.fontSize = 14
        priceLabel.horizontalAlignmentMode = .left
        priceLabel.position = CGPoint(x: -cardWidth/2 + 110, y: -25)
        container.addChild(priceLabel)

        // Action buttons
        let buttonsContainer = SKNode()
        buttonsContainer.position = CGPoint(x: cardWidth/2 - 70, y: 0)
        container.addChild(buttonsContainer)

        // Try It button
        let tryBtn = createSmallButton(text: "TRY IT", color: SKColor(red: 0.4, green: 0.7, blue: 0.9, alpha: 1.0))
        tryBtn.position = CGPoint(x: 0, y: 20)
        tryBtn.name = "try_\(itemId)"
        buttonsContainer.addChild(tryBtn)

        // Buy/Equip button
        var actionBtnText = "BUY"
        var actionBtnColor = SKColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)

        if currentCategory == .powerups {
            actionBtnText = "BUY"
        } else if isSelected {
            actionBtnText = "EQUIPPED"
            actionBtnColor = SKColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
        } else if isOwned {
            actionBtnText = "EQUIP"
            actionBtnColor = SKColor(red: 0.3, green: 0.7, blue: 0.4, alpha: 1.0)
        }

        let actionBtn = createSmallButton(text: actionBtnText, color: actionBtnColor)
        actionBtn.position = CGPoint(x: 0, y: -20)
        actionBtn.name = "action_\(itemId)"
        buttonsContainer.addChild(actionBtn)

        // Pulse animation for preview
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 1.5),
            SKAction.scale(to: 0.95, duration: 1.5)
        ])
        previewContainer.run(SKAction.repeatForever(pulse))

        return container
    }

    private func createSmallButton(text: String, color: SKColor) -> SKNode {
        let container = SKNode()

        let bg = SKShapeNode(rectOf: CGSize(width: 80, height: 28), cornerRadius: 14)
        bg.fillColor = color
        bg.strokeColor = .white.withAlphaComponent(0.5)
        bg.lineWidth = 2
        bg.name = "btn_bg"
        container.addChild(bg)

        let label = SKLabelNode(fontNamed: "Gameplay")
        label.text = text
        label.fontSize = 11
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        container.addChild(label)

        return container
    }

    private func createIconButton(emoji: String, color: SKColor) -> SKNode {
        let container = SKNode()

        let shadow = SKShapeNode(circleOfRadius: 22)
        shadow.fillColor = .black.withAlphaComponent(0.2)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 2, y: -2)
        container.addChild(shadow)

        let bg = SKShapeNode(circleOfRadius: 22)
        bg.fillColor = color
        bg.strokeColor = .white
        bg.lineWidth = 3
        bg.name = "btn_bg"
        container.addChild(bg)

        let label = SKLabelNode(fontNamed: "Gameplay")
        label.text = emoji
        label.fontSize = 22
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        container.addChild(label)

        return container
    }

    // MARK: - Preview Overlay
    private func showPreview(for itemId: String) {
        previewOverlay?.removeFromParent()

        previewOverlay = SKNode()
        previewOverlay?.zPosition = 500

        let dimBg = SKShapeNode(rectOf: self.size)
        dimBg.fillColor = .black.withAlphaComponent(0.8)
        dimBg.strokeColor = .clear
        dimBg.position = CGPoint(x: frame.midX, y: frame.midY)
        dimBg.name = "preview_dismiss"
        previewOverlay?.addChild(dimBg)

        let previewCard = SKShapeNode(rectOf: CGSize(width: frame.width * 0.9, height: frame.height * 0.6), cornerRadius: 30)
        previewCard.fillColor = .white
        previewCard.strokeColor = SKColor(red: 0.7, green: 0.5, blue: 0.9, alpha: 1.0)
        previewCard.lineWidth = 4
        previewCard.position = CGPoint(x: frame.midX, y: frame.midY)
        previewOverlay?.addChild(previewCard)

        // Parse itemId
        let parts = itemId.split(separator: "_")
        guard parts.count >= 2 else { return }
        let category = String(parts[0])
        let itemName = parts.dropFirst().joined(separator: "_")

        var previewTitle = "PREVIEW"
        var previewEmoji = "👀"
        var previewContent: SKNode?

        switch category {
        case "skin":
            if let skin = ButtonSkin(rawValue: itemName) {
                previewTitle = skin.rawValue.uppercased()
                previewEmoji = skin.previewEmoji
                previewContent = createSkinPreview(skin: skin)
            }
        case "theme":
            if let theme = BackgroundTheme(rawValue: itemName) {
                previewTitle = theme.rawValue.uppercased()
                previewEmoji = theme.accentEmoji
                previewContent = createThemePreview(theme: theme)
            }
        case "emoji":
            if let pack = EmojiPack(rawValue: itemName) {
                previewTitle = pack.rawValue.uppercased()
                previewEmoji = pack.previewEmoji
                previewContent = createEmojiPreview(pack: pack)
            }
        case "effect":
            if let effect = SpecialEffectPack(rawValue: itemName) {
                previewTitle = effect.rawValue.uppercased()
                previewEmoji = effect.previewEmoji
                previewContent = createEffectPreview(effect: effect)
            }
        case "powerup":
            if let powerUp = PowerUp(rawValue: itemName) {
                previewTitle = powerUp.rawValue.uppercased()
                previewEmoji = powerUp.previewEmoji
                previewContent = createPowerUpPreview(powerUp: powerUp)
            }
        default:
            break
        }

        // Title
        let titleLabel = SKLabelNode(fontNamed: "Gameplay")
        titleLabel.text = "\(previewEmoji) \(previewTitle)"
        titleLabel.fontSize = 28
        titleLabel.fontColor = SKColor(red: 0.4, green: 0.2, blue: 0.6, alpha: 1.0)
        titleLabel.position = CGPoint(x: frame.midX, y: frame.midY + frame.height * 0.22)
        previewOverlay?.addChild(titleLabel)

        // Preview content
        if let content = previewContent {
            content.position = CGPoint(x: frame.midX, y: frame.midY)
            previewOverlay?.addChild(content)
        }

        // Close hint
        let closeLabel = SKLabelNode(fontNamed: "Gameplay")
        closeLabel.text = "TAP ANYWHERE TO CLOSE"
        closeLabel.fontSize = 14
        closeLabel.fontColor = .gray
        closeLabel.position = CGPoint(x: frame.midX, y: frame.midY - frame.height * 0.25)
        previewOverlay?.addChild(closeLabel)

        addChild(previewOverlay!)

        // Entry animation
        previewCard.setScale(0.8)
        previewCard.alpha = 0
        previewCard.run(SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.25),
            SKAction.fadeIn(withDuration: 0.2)
        ]))
    }

    private func createSkinPreview(skin: ButtonSkin) -> SKNode {
        let container = SKNode()

        // Sample buttons
        let emojis = ["🧠", "😊", "🎮", "⭐️"]
        let buttonSize: CGFloat = 60

        for (index, emoji) in emojis.enumerated() {
            let btnContainer = SKNode()
            let col = index % 2
            let row = index / 2
            btnContainer.position = CGPoint(x: CGFloat(col - 1) * 80 + 40, y: CGFloat(1 - row) * 80 - 40)

            let shadow = SKShapeNode(circleOfRadius: buttonSize/2)
            shadow.fillColor = .black.withAlphaComponent(0.2)
            shadow.strokeColor = .clear
            shadow.position = CGPoint(x: 3, y: -3)
            btnContainer.addChild(shadow)

            let btn = SKShapeNode(circleOfRadius: buttonSize/2)
            btn.fillColor = skin.buttonColor
            btn.strokeColor = skin.strokeColor
            btn.lineWidth = skin.strokeWidth
            if skin == .metal || skin == .galaxy { btn.glowWidth = 3 }
            btnContainer.addChild(btn)

            let label = SKLabelNode(text: emoji)
            label.fontSize = buttonSize * 0.6
            label.verticalAlignmentMode = .center
            btnContainer.addChild(label)

            container.addChild(btnContainer)

            // Animate based on skin type
            let anim: SKAction
            switch skin.animationType {
            case .squish:
                anim = SKAction.sequence([
                    SKAction.scaleX(to: 1.2, y: 0.8, duration: 0.3),
                    SKAction.scaleX(to: 0.9, y: 1.1, duration: 0.3),
                    SKAction.scale(to: 1.0, duration: 0.2)
                ])
            case .glitch:
                anim = SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.3, duration: 0.1),
                    SKAction.fadeAlpha(to: 1.0, duration: 0.1),
                    SKAction.moveBy(x: 5, y: 0, duration: 0.05),
                    SKAction.moveBy(x: -5, y: 0, duration: 0.05)
                ])
            case .heavy:
                anim = SKAction.sequence([
                    SKAction.rotate(byAngle: 0.1, duration: 0.05),
                    SKAction.rotate(byAngle: -0.2, duration: 0.1),
                    SKAction.rotate(toAngle: 0, duration: 0.05)
                ])
            default:
                anim = SKAction.sequence([
                    SKAction.scale(to: 1.15, duration: 0.15),
                    SKAction.scale(to: 1.0, duration: 0.15)
                ])
            }

            let delay = SKAction.wait(forDuration: Double(index) * 0.3)
            btnContainer.run(SKAction.sequence([delay, SKAction.repeatForever(SKAction.sequence([anim, SKAction.wait(forDuration: 1.0)]))]))
        }

        return container
    }

    private func createThemePreview(theme: BackgroundTheme) -> SKNode {
        let container = SKNode()

        // Mini scene preview
        let previewSize = CGSize(width: 250, height: 180)
        let bg = SKShapeNode(rectOf: previewSize, cornerRadius: 15)
        bg.fillColor = theme.primaryColor
        bg.strokeColor = .white
        bg.lineWidth = 3
        container.addChild(bg)

        // Secondary color accent
        let accent = SKShapeNode(rectOf: CGSize(width: previewSize.width, height: 50), cornerRadius: 0)
        accent.fillColor = theme.secondaryColor
        accent.strokeColor = .clear
        accent.position = CGPoint(x: 0, y: -65)
        container.addChild(accent)

        // Theme emoji
        let themeEmoji = SKLabelNode(text: theme.accentEmoji)
        themeEmoji.fontSize = 50
        themeEmoji.position = CGPoint(x: 80, y: 40)
        container.addChild(themeEmoji)

        // Sample elements
        if theme == .space || theme == .night {
            for _ in 0..<10 {
                let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...3))
                star.fillColor = .white
                star.position = CGPoint(x: CGFloat.random(in: -120...120), y: CGFloat.random(in: -80...80))
                container.addChild(star)
            }
        }

        // Animate
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.02, duration: 1.0),
            SKAction.scale(to: 0.98, duration: 1.0)
        ])
        container.run(SKAction.repeatForever(pulse))

        return container
    }

    private func createEmojiPreview(pack: EmojiPack) -> SKNode {
        let container = SKNode()

        // Display first 12 emojis in a grid
        let emojis = Array(pack.emojis.prefix(12))
        let cols = 4
        let spacing: CGFloat = 55

        for (index, emoji) in emojis.enumerated() {
            let col = index % cols
            let row = index / cols
            let x = CGFloat(col - cols/2) * spacing + spacing/2
            let y = CGFloat(1 - row) * spacing

            let label = SKLabelNode(text: emoji)
            label.fontSize = 35
            label.position = CGPoint(x: x, y: y)
            container.addChild(label)

            // Bounce animation
            let delay = SKAction.wait(forDuration: Double(index) * 0.1)
            let bounce = SKAction.sequence([
                SKAction.moveBy(x: 0, y: 10, duration: 0.3),
                SKAction.moveBy(x: 0, y: -10, duration: 0.3)
            ])
            label.run(SKAction.sequence([delay, SKAction.repeatForever(bounce)]))
        }

        // "And more..." label
        let moreLabel = SKLabelNode(fontNamed: "Gameplay")
        moreLabel.text = "+\(pack.emojis.count - 12) more!"
        moreLabel.fontSize = 16
        moreLabel.fontColor = .gray
        moreLabel.position = CGPoint(x: 0, y: -80)
        container.addChild(moreLabel)

        return container
    }

    private func createEffectPreview(effect: SpecialEffectPack) -> SKNode {
        let container = SKNode()

        // Demo area
        let demoBg = SKShapeNode(rectOf: CGSize(width: 220, height: 150), cornerRadius: 15)
        demoBg.fillColor = SKColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0)
        demoBg.strokeColor = .white
        demoBg.lineWidth = 2
        container.addChild(demoBg)

        // Spawn particles based on effect type
        let spawnParticle = SKAction.run { [weak container] in
            guard let container = container else { return }
            var particle: SKNode

            switch effect {
            case .confetti:
                let rect = SKShapeNode(rectOf: CGSize(width: 8, height: 8))
                rect.fillColor = [.red, .yellow, .green, .blue, .purple, .orange].randomElement()!
                rect.strokeColor = .clear
                particle = rect
            case .fireworks:
                let circle = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...6))
                circle.fillColor = [.red, .orange, .yellow, .white].randomElement()!
                circle.strokeColor = .clear
                particle = circle
            case .hearts:
                let heart = SKLabelNode(text: "❤️")
                heart.fontSize = CGFloat.random(in: 15...25)
                particle = heart
            case .stars:
                let star = SKLabelNode(text: "⭐️")
                star.fontSize = CGFloat.random(in: 12...20)
                particle = star
            case .bubbles:
                let bubble = SKShapeNode(circleOfRadius: CGFloat.random(in: 5...12))
                bubble.fillColor = .white.withAlphaComponent(0.4)
                bubble.strokeColor = .white.withAlphaComponent(0.6)
                bubble.lineWidth = 1
                particle = bubble
            case .lightning:
                let bolt = SKLabelNode(text: "⚡️")
                bolt.fontSize = CGFloat.random(in: 20...30)
                particle = bolt
            case .none:
                return
            }

            particle.position = CGPoint(x: CGFloat.random(in: -80...80), y: -60)
            particle.zPosition = 10
            container.addChild(particle)

            let moveUp = SKAction.moveBy(x: CGFloat.random(in: -30...30), y: 130, duration: Double.random(in: 1.0...2.0))
            let fade = SKAction.fadeOut(withDuration: 0.5)
            let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -2...2), duration: 1.5)

            particle.run(SKAction.sequence([
                SKAction.group([moveUp, rotate, SKAction.sequence([SKAction.wait(forDuration: 1.0), fade])]),
                SKAction.removeFromParent()
            ]))
        }

        if effect != .none {
            container.run(SKAction.repeatForever(SKAction.sequence([spawnParticle, SKAction.wait(forDuration: 0.15)])))
        } else {
            let noEffectLabel = SKLabelNode(fontNamed: "Gameplay")
            noEffectLabel.text = "No effects"
            noEffectLabel.fontSize = 18
            noEffectLabel.fontColor = .gray
            container.addChild(noEffectLabel)
        }

        return container
    }

    private func createPowerUpPreview(powerUp: PowerUp) -> SKNode {
        let container = SKNode()

        // Large emoji
        let emoji = SKLabelNode(text: powerUp.previewEmoji)
        emoji.fontSize = 80
        emoji.position = CGPoint(x: 0, y: 30)
        container.addChild(emoji)

        // Description
        let descLabel = SKLabelNode(fontNamed: "Gameplay")
        descLabel.text = powerUp.description
        descLabel.fontSize = 18
        descLabel.fontColor = .darkGray
        descLabel.position = CGPoint(x: 0, y: -40)
        container.addChild(descLabel)

        // Usage hint
        let hintLabel = SKLabelNode(fontNamed: "Gameplay")
        hintLabel.text = "Use during gameplay!"
        hintLabel.fontSize = 14
        hintLabel.fontColor = .gray
        hintLabel.position = CGPoint(x: 0, y: -70)
        container.addChild(hintLabel)

        // Pulse animation
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.5),
            SKAction.scale(to: 0.9, duration: 0.5)
        ])
        emoji.run(SKAction.repeatForever(pulse))

        return container
    }

    // MARK: - Confirmation Dialog
    private func showPurchaseConfirmation(itemId: String, name: String, cost: Int) {
        confirmOverlay?.removeFromParent()

        confirmOverlay = SKNode()
        confirmOverlay?.zPosition = 600

        let dimBg = SKShapeNode(rectOf: self.size)
        dimBg.fillColor = .black.withAlphaComponent(0.7)
        dimBg.strokeColor = .clear
        dimBg.position = CGPoint(x: frame.midX, y: frame.midY)
        confirmOverlay?.addChild(dimBg)

        let dialog = SKShapeNode(rectOf: CGSize(width: 280, height: 200), cornerRadius: 25)
        dialog.fillColor = .white
        dialog.strokeColor = SKColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
        dialog.lineWidth = 4
        dialog.position = CGPoint(x: frame.midX, y: frame.midY)
        confirmOverlay?.addChild(dialog)

        let titleLabel = SKLabelNode(fontNamed: "Gameplay")
        titleLabel.text = "CONFIRM PURCHASE"
        titleLabel.fontSize = 20
        titleLabel.fontColor = .black
        titleLabel.position = CGPoint(x: frame.midX, y: frame.midY + 60)
        confirmOverlay?.addChild(titleLabel)

        let itemLabel = SKLabelNode(fontNamed: "Gameplay")
        itemLabel.text = name
        itemLabel.fontSize = 18
        itemLabel.fontColor = .darkGray
        itemLabel.position = CGPoint(x: frame.midX, y: frame.midY + 25)
        confirmOverlay?.addChild(itemLabel)

        let costLabel = SKLabelNode(fontNamed: "Gameplay")
        costLabel.text = "💰 \(cost)"
        costLabel.fontSize = 24
        costLabel.fontColor = SKColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
        costLabel.position = CGPoint(x: frame.midX, y: frame.midY - 10)
        confirmOverlay?.addChild(costLabel)

        // Confirm button
        let confirmBtn = createSmallButton(text: "BUY NOW", color: SKColor(red: 0.3, green: 0.8, blue: 0.4, alpha: 1.0))
        confirmBtn.position = CGPoint(x: frame.midX - 55, y: frame.midY - 60)
        confirmBtn.name = "confirm_buy_\(itemId)"
        confirmBtn.setScale(1.3)
        confirmOverlay?.addChild(confirmBtn)

        // Cancel button
        let cancelBtn = createSmallButton(text: "CANCEL", color: SKColor(red: 0.8, green: 0.4, blue: 0.4, alpha: 1.0))
        cancelBtn.position = CGPoint(x: frame.midX + 55, y: frame.midY - 60)
        cancelBtn.name = "cancel_buy"
        cancelBtn.setScale(1.3)
        confirmOverlay?.addChild(cancelBtn)

        addChild(confirmOverlay!)

        // Animation
        dialog.setScale(0.8)
        dialog.run(SKAction.scale(to: 1.0, duration: 0.2))
    }

    // MARK: - Purchase Logic
    private func handlePurchase(itemId: String) {
        let parts = itemId.split(separator: "_")
        guard parts.count >= 2 else { return }
        let category = String(parts[0])
        let itemName = parts.dropFirst().joined(separator: "_")

        var success = false

        switch category {
        case "skin":
            if let skin = ButtonSkin(rawValue: itemName) {
                if GameManager.shared.unlockedSkins.contains(skin) {
                    GameManager.shared.selectedSkin = skin
                    success = true
                } else {
                    success = GameManager.shared.unlockSkin(skin)
                    if success { GameManager.shared.selectedSkin = skin }
                }
            }
        case "theme":
            if let theme = BackgroundTheme(rawValue: itemName) {
                if GameManager.shared.unlockedThemes.contains(theme) {
                    GameManager.shared.selectedTheme = theme
                    success = true
                } else {
                    success = GameManager.shared.unlockTheme(theme)
                    if success { GameManager.shared.selectedTheme = theme }
                }
            }
        case "emoji":
            if let pack = EmojiPack(rawValue: itemName) {
                if GameManager.shared.unlockedEmojiPacks.contains(pack) {
                    GameManager.shared.selectedEmojiPack = pack
                    success = true
                } else {
                    success = GameManager.shared.unlockEmojiPack(pack)
                    if success { GameManager.shared.selectedEmojiPack = pack }
                }
            }
        case "effect":
            if let effect = SpecialEffectPack(rawValue: itemName) {
                if GameManager.shared.unlockedEffects.contains(effect) {
                    GameManager.shared.selectedEffect = effect
                    success = true
                } else {
                    success = GameManager.shared.unlockEffect(effect)
                    if success { GameManager.shared.selectedEffect = effect }
                }
            }
        case "powerup":
            if let powerUp = PowerUp(rawValue: itemName) {
                success = GameManager.shared.purchasePowerUp(powerUp)
            }
        default:
            break
        }

        if success {
            hapticFeedback.impactOccurred()
            playSound("kaching.mp3")
            updateCoinDisplay()
            loadCategoryItems()
        } else {
            notificationFeedback.notificationOccurred(.error)
            showInsufficientFundsAlert()
        }
    }

    private func showInsufficientFundsAlert() {
        let alert = SKLabelNode(fontNamed: "Gameplay")
        alert.text = "NOT ENOUGH COINS!"
        alert.fontSize = 24
        alert.fontColor = .systemRed
        alert.position = CGPoint(x: frame.midX, y: frame.midY)
        alert.zPosition = 700
        alert.setScale(0)
        addChild(alert)

        alert.run(SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.1),
            SKAction.wait(forDuration: 1.0),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
    }

    private func updateCoinDisplay() {
        coinLabel?.text = "💰 \(GameManager.shared.totalCoins)"
    }

    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Handle preview overlay
        if previewOverlay != nil {
            previewOverlay?.removeFromParent()
            previewOverlay = nil
            return
        }

        // Handle confirm overlay
        if confirmOverlay != nil {
            let confirmNodes = nodes(at: location)
            for node in confirmNodes {
                if let name = node.name ?? node.parent?.name {
                    if name.starts(with: "confirm_buy_") {
                        let itemId = String(name.dropFirst(12))
                        confirmOverlay?.removeFromParent()
                        confirmOverlay = nil
                        handlePurchase(itemId: itemId)
                        return
                    } else if name == "cancel_buy" {
                        confirmOverlay?.removeFromParent()
                        confirmOverlay = nil
                        return
                    }
                }
            }
            confirmOverlay?.removeFromParent()
            confirmOverlay = nil
            return
        }

        let touchedNodes = nodes(at: location)

        for node in touchedNodes {
            let nodeName = node.name ?? node.parent?.name ?? node.parent?.parent?.name

            // Back button
            if nodeName == "back_btn" {
                animateTap(node.name == "back_btn" ? node : (node.parent ?? node)) {
                    self.transitionToMenu()
                }
                return
            }

            // Tab buttons
            if let name = nodeName, name.starts(with: "tab_") {
                let categoryName = String(name.dropFirst(4))
                if let category = StoreCategory(rawValue: categoryName) {
                    hapticFeedback.impactOccurred()
                    currentCategory = category
                    updateTabSelection()
                    loadCategoryItems()
                }
                return
            }

            // Filter buttons
            if let name = nodeName, name.starts(with: "filter_") {
                let filterName = String(name.dropFirst(7))
                if let filter = StoreFilter(rawValue: filterName) {
                    hapticFeedback.impactOccurred()
                    currentFilter = filter
                    updateFilterSelection()
                    loadCategoryItems()
                }
                return
            }

            // Try button
            if let name = nodeName, name.starts(with: "try_") {
                let itemId = String(name.dropFirst(4))
                hapticFeedback.impactOccurred()
                showPreview(for: itemId)
                return
            }

            // Action button (buy/equip)
            if let name = nodeName, name.starts(with: "action_") {
                let itemId = String(name.dropFirst(7))
                hapticFeedback.impactOccurred()

                // Get item info for confirmation
                let parts = itemId.split(separator: "_")
                if parts.count >= 2 {
                    let category = String(parts[0])
                    let itemName = parts.dropFirst().joined(separator: "_")

                    var cost = 0
                    var isOwned = false
                    var displayName = itemName

                    switch category {
                    case "skin":
                        if let skin = ButtonSkin(rawValue: itemName) {
                            cost = skin.cost
                            isOwned = GameManager.shared.unlockedSkins.contains(skin)
                            displayName = skin.rawValue
                        }
                    case "theme":
                        if let theme = BackgroundTheme(rawValue: itemName) {
                            cost = theme.cost
                            isOwned = GameManager.shared.unlockedThemes.contains(theme)
                            displayName = theme.rawValue
                        }
                    case "emoji":
                        if let pack = EmojiPack(rawValue: itemName) {
                            cost = pack.cost
                            isOwned = GameManager.shared.unlockedEmojiPacks.contains(pack)
                            displayName = pack.rawValue
                        }
                    case "effect":
                        if let effect = SpecialEffectPack(rawValue: itemName) {
                            cost = effect.cost
                            isOwned = GameManager.shared.unlockedEffects.contains(effect)
                            displayName = effect.rawValue
                        }
                    case "powerup":
                        if let powerUp = PowerUp(rawValue: itemName) {
                            cost = powerUp.cost
                            displayName = powerUp.rawValue
                        }
                    default:
                        break
                    }

                    if isOwned || (category == "powerup" && cost == 0) {
                        // Already owned, just equip
                        handlePurchase(itemId: itemId)
                    } else {
                        // Show purchase confirmation
                        showPurchaseConfirmation(itemId: itemId, name: displayName, cost: cost)
                    }
                }
                return
            }
        }

        // Start scroll
        if let contentNode = contentNode, location.y < contentNode.position.y + 500 {
            isDragging = true
            lastTouchY = location.y
            velocity = 0
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDragging, let touch = touches.first else { return }
        let location = touch.location(in: self)

        let deltaY = location.y - lastTouchY
        velocity = deltaY

        // Direct manipulation: content follows finger
        scrollOffset -= deltaY
        scrollOffset = max(0, min(scrollOffset, maxScrollOffset))

        // Update position smoothly
        let safeTop = view?.safeAreaInsets.top ?? 50
        let safeBottom = view?.safeAreaInsets.bottom ?? 0
        let contentHeight = frame.maxY - safeTop - 175 - safeBottom - 20
        scrollContentNode?.position.y = -scrollOffset + contentHeight/2

        lastTouchY = location.y
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDragging = false

        // Apply momentum for natural scrolling feel
        if abs(velocity) > 2 {
            let momentumAction = SKAction.customAction(withDuration: 0.8) { [weak self] _, elapsedTime in
                guard let self = self else { return }
                let progress = elapsedTime / 0.8
                let easeOut = 1.0 - pow(1.0 - progress, 3.0) // Cubic ease out
                let dampedVelocity = self.velocity * (1.0 - easeOut)

                self.scrollOffset -= dampedVelocity * 0.5
                self.scrollOffset = max(0, min(self.scrollOffset, self.maxScrollOffset))

                let safeTop = self.view?.safeAreaInsets.top ?? 50
                let safeBottom = self.view?.safeAreaInsets.bottom ?? 0
                let contentHeight = self.frame.maxY - safeTop - 175 - safeBottom - 20
                self.scrollContentNode?.position.y = -self.scrollOffset + contentHeight/2
            }
            run(momentumAction)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDragging = false
    }

    private func animateTap(_ node: SKNode, completion: @escaping () -> Void) {
        let scaleDown = SKAction.scale(to: 0.9, duration: 0.1)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
        node.run(SKAction.sequence([scaleDown, scaleUp])) {
            completion()
        }
    }

    // MARK: - Navigation
    private func transitionToMenu() {
        let menuScene = MenuScene(size: self.size)
        menuScene.scaleMode = .aspectFill
        let transition = SKTransition.push(with: .right, duration: 0.4)
        self.view?.presentScene(menuScene, transition: transition)
    }

    // MARK: - Sound
    private func playSound(_ fileName: String) {
        run(SKAction.playSoundFileNamed(fileName, waitForCompletion: false))
    }
}
