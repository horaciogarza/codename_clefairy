import SpriteKit

struct UIFactory {

    // MARK: - SF Symbol Rendering

    /// Renders an SF Symbol into a tinted bitmap that survives SKTexture conversion.
    /// `withTintColor` alone doesn't work because SKTexture rasterizes template images as black.
    static func renderSymbol(_ systemName: String, pointSize: CGFloat, weight: UIImage.SymbolWeight = .bold, color: UIColor = .white) -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
        guard let symbol = UIImage(systemName: systemName, withConfiguration: config) else { return nil }

        let renderer = UIGraphicsImageRenderer(size: symbol.size)
        return renderer.image { _ in
            color.set()
            symbol.withRenderingMode(.alwaysTemplate).draw(in: CGRect(origin: .zero, size: symbol.size))
        }
    }

    static func symbolSprite(_ systemName: String, pointSize: CGFloat, weight: UIImage.SymbolWeight = .bold, color: UIColor = .white, size: CGSize? = nil) -> SKSpriteNode? {
        guard let img = renderSymbol(systemName, pointSize: pointSize, weight: weight, color: color) else { return nil }
        let node = SKSpriteNode(texture: SKTexture(image: img))
        if let size = size {
            node.size = size
        }
        return node
    }

    // MARK: - Buttons

    /// Builds a chunky 8-bit button base: sharp corners, a hard offset drop-shadow
    /// block, a thick black outline, and bevel highlight/shade strips. All tappable
    /// pieces are named "btn_body" so the scenes' touch routing keeps working.
    private static func pixelButtonBase(size: CGSize, color: SKColor) -> SKNode {
        let container = SKNode()

        // Hard, solid drop shadow (no soft alpha falloff — classic pixel look).
        let shadow = SKShapeNode(rectOf: size, cornerRadius: 0)
        shadow.fillColor = .black.withAlphaComponent(0.55)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 5, y: -6)
        container.addChild(shadow)

        // Body with a thick black outline.
        let body = SKShapeNode(rectOf: size, cornerRadius: 0)
        body.fillColor = color
        body.strokeColor = .black
        body.lineWidth = 4
        body.name = "btn_body"
        container.addChild(body)

        // Top highlight + bottom shade strips for a beveled pixel edge.
        let stripWidth = size.width - 18
        let highlight = SKShapeNode(rectOf: CGSize(width: stripWidth, height: 5), cornerRadius: 0)
        highlight.fillColor = adjustBrightness(color, by: 0.22)
        highlight.strokeColor = .clear
        highlight.position = CGPoint(x: 0, y: size.height / 2 - 11)
        highlight.zPosition = 0.5
        highlight.name = "btn_body"
        container.addChild(highlight)

        let shade = SKShapeNode(rectOf: CGSize(width: stripWidth, height: 5), cornerRadius: 0)
        shade.fillColor = adjustBrightness(color, by: -0.22)
        shade.strokeColor = .clear
        shade.position = CGPoint(x: 0, y: -size.height / 2 + 11)
        shade.zPosition = 0.5
        shade.name = "btn_body"
        container.addChild(shade)

        return container
    }

    private static func adjustBrightness(_ color: SKColor, by delta: CGFloat) -> SKColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return SKColor(
            red: max(0, min(1, r + delta)),
            green: max(0, min(1, g + delta)),
            blue: max(0, min(1, b + delta)),
            alpha: a
        )
    }

    static func createCartoonButton(text: String, color: SKColor, size: CGSize, cornerRadius: CGFloat = 25) -> SKNode {
        let container = pixelButtonBase(size: size, color: color)

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

    static func createButtonWithIcon(text: String, systemName: String, color: SKColor, size: CGSize, iconSize: CGFloat = 20) -> SKNode {
        let container = pixelButtonBase(size: size, color: color)

        if let icon = symbolSprite(systemName, pointSize: iconSize, color: .white, size: CGSize(width: iconSize, height: iconSize)) {
            // Measure text width to center the icon+gap+text group
            let label = SKLabelNode(fontNamed: "Gameplay")
            label.text = text
            label.fontSize = size.height * 0.35
            label.fontColor = .white
            label.verticalAlignmentMode = .center
            label.zPosition = 1
            label.name = "btn_label"

            let gap: CGFloat = 8
            let totalWidth = iconSize + gap + label.frame.width
            let groupX = -totalWidth / 2

            icon.position = CGPoint(x: groupX + iconSize / 2, y: 0)
            icon.zPosition = 1
            container.addChild(icon)

            label.horizontalAlignmentMode = .left
            label.position = CGPoint(x: groupX + iconSize + gap, y: 0)
            container.addChild(label)
        } else {
            let label = SKLabelNode(fontNamed: "Gameplay")
            label.text = text
            label.fontSize = size.height * 0.4
            label.fontColor = .white
            label.verticalAlignmentMode = .center
            label.zPosition = 1
            label.name = "btn_label"
            container.addChild(label)
        }

        return container
    }

    // MARK: - Boards / Panels

    static func createCartoonBoard(size: CGSize, color: SKColor, cornerRadius: CGFloat = 35) -> SKNode {
        let container = SKNode()

        let shadow = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
        shadow.fillColor = .black.withAlphaComponent(0.4)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 8, y: -8)
        container.addChild(shadow)

        let body = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
        body.fillColor = color
        body.strokeColor = .white
        body.lineWidth = 6
        container.addChild(body)

        return container
    }

    static func createCartoonPanel(size: CGSize, color: SKColor, cornerRadius: CGFloat = 20) -> SKNode {
        let container = SKNode()

        let shadow = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
        shadow.fillColor = .black.withAlphaComponent(0.4)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 8, y: -8)
        container.addChild(shadow)

        let body = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
        body.fillColor = color
        body.strokeColor = .white
        body.lineWidth = 6
        container.addChild(body)

        return container
    }

    // MARK: - Icon Buttons (circular)

    static func createIconButton(systemName: String, color: SKColor, size: CGFloat = 50, iconSize: CGFloat = 22) -> SKNode {
        let container = pixelButtonBase(size: CGSize(width: size, height: size), color: color)

        if let icon = symbolSprite(systemName, pointSize: iconSize, color: .white, size: CGSize(width: iconSize, height: iconSize)) {
            icon.zPosition = 1
            container.addChild(icon)
        }

        return container
    }

    static func createIconButton(text: String, color: SKColor, size: CGFloat = 50) -> SKNode {
        let container = pixelButtonBase(size: CGSize(width: size, height: size), color: color)

        let label = SKLabelNode(fontNamed: "AppleColorEmoji")
        label.text = text
        label.fontSize = 24
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.zPosition = 1
        container.addChild(label)

        return container
    }

    // MARK: - Animation

    static func animateTap(_ node: SKNode, completion: @escaping () -> Void) {
        let scaleDown = SKAction.scale(to: 0.9, duration: 0.1)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
        node.run(SKAction.sequence([scaleDown, scaleUp])) {
            completion()
        }
    }
}
