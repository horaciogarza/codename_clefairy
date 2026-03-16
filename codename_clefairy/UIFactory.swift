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

    static func createCartoonButton(text: String, color: SKColor, size: CGSize, cornerRadius: CGFloat = 25) -> SKNode {
        let container = SKNode()

        let shadow = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
        shadow.fillColor = .black.withAlphaComponent(0.4)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -8)
        container.addChild(shadow)

        let body = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
        body.fillColor = color
        body.strokeColor = .white
        body.lineWidth = 6
        body.name = "btn_body"
        container.addChild(body)

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
        let container = SKNode()

        let shadow = SKShapeNode(rectOf: size, cornerRadius: 25)
        shadow.fillColor = .black.withAlphaComponent(0.4)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -8)
        container.addChild(shadow)

        let body = SKShapeNode(rectOf: size, cornerRadius: 25)
        body.fillColor = color
        body.strokeColor = .white
        body.lineWidth = 6
        body.name = "btn_body"
        container.addChild(body)

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
        let container = SKNode()

        let shadow = SKShapeNode(circleOfRadius: size / 2)
        shadow.fillColor = .black.withAlphaComponent(0.25)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 2, y: -3)
        container.addChild(shadow)

        let body = SKShapeNode(circleOfRadius: size / 2)
        body.fillColor = color
        body.strokeColor = .white
        body.lineWidth = 3
        body.name = "btn_body"
        container.addChild(body)

        if let icon = symbolSprite(systemName, pointSize: iconSize, color: .white, size: CGSize(width: iconSize, height: iconSize)) {
            icon.zPosition = 1
            container.addChild(icon)
        }

        return container
    }

    static func createIconButton(text: String, color: SKColor, size: CGFloat = 50) -> SKNode {
        let container = SKNode()

        let shadow = SKShapeNode(circleOfRadius: size / 2)
        shadow.fillColor = .black.withAlphaComponent(0.25)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 2, y: -3)
        container.addChild(shadow)

        let body = SKShapeNode(circleOfRadius: size / 2)
        body.fillColor = color
        body.strokeColor = .white
        body.lineWidth = 3
        body.name = "btn_body"
        container.addChild(body)

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
