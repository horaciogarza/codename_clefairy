import SpriteKit

class BackgroundRenderer {
    weak var scene: SKScene?

    init(scene: SKScene) {
        self.scene = scene
    }

    func updateEnvironment(isFrenzyMode: Bool) {
        guard let scene = scene else { return }
        let theme = ThemeManager.shared.currentTheme

        scene.children.filter { $0.name == "bg_element" }.forEach { $0.removeFromParent() }

        scene.backgroundColor = isFrenzyMode ? theme.frenzyBgColor : theme.skyColor

        // Hills
        let ground = SKShapeNode()
        let groundPath = UIBezierPath()
        groundPath.move(to: CGPoint(x: 0, y: 0))
        groundPath.addLine(to: CGPoint(x: 0, y: scene.frame.height * 0.2))
        groundPath.addQuadCurve(
            to: CGPoint(x: scene.frame.width, y: scene.frame.height * 0.15),
            controlPoint: CGPoint(x: scene.frame.width * 0.5, y: scene.frame.height * 0.3)
        )
        groundPath.addLine(to: CGPoint(x: scene.frame.width, y: 0))
        groundPath.close()
        ground.path = groundPath.cgPath
        ground.fillColor = isFrenzyMode ? theme.frenzyHillColor : theme.hillColor
        ground.strokeColor = .clear
        ground.zPosition = -4
        ground.name = "bg_element"
        scene.addChild(ground)

        let cloudCount = isFrenzyMode ? 8 : 4
        for _ in 0..<cloudCount {
            spawnCloud(isFrenzyMode: isFrenzyMode)
        }
    }

    func setupDayBackground() {
        guard let scene = scene else { return }
        let theme = ThemeManager.shared.currentTheme

        let hill1 = SKShapeNode()
        let path1 = UIBezierPath()
        path1.move(to: CGPoint(x: 0, y: 0))
        path1.addLine(to: CGPoint(x: 0, y: scene.frame.height * 0.25))
        path1.addQuadCurve(
            to: CGPoint(x: scene.frame.width, y: scene.frame.height * 0.15),
            controlPoint: CGPoint(x: scene.frame.width * 0.5, y: scene.frame.height * 0.35)
        )
        path1.addLine(to: CGPoint(x: scene.frame.width, y: 0))
        path1.close()
        hill1.path = path1.cgPath
        hill1.fillColor = theme.hillColor
        hill1.strokeColor = .clear
        hill1.zPosition = -4
        hill1.name = "bg_element"
        scene.addChild(hill1)

        for _ in 0..<4 {
            spawnCloud(isFrenzyMode: false)
        }
    }

    func spawnCloud(isFrenzyMode: Bool) {
        guard let scene = scene else { return }

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
        cloudContainer.position = CGPoint(
            x: CGFloat.random(in: -100...scene.frame.width),
            y: CGFloat.random(in: scene.frame.midY...scene.frame.maxY - 100)
        )
        cloudContainer.zPosition = -6
        scene.addChild(cloudContainer)

        let baseDuration = Double.random(in: 40...80)
        let duration = isFrenzyMode ? baseDuration / 4 : baseDuration

        let move = SKAction.moveBy(x: scene.frame.width + 300, y: 0, duration: duration)
        let reset = SKAction.moveBy(x: -(scene.frame.width + 500), y: 0, duration: 0)
        cloudContainer.run(SKAction.repeatForever(SKAction.sequence([move, reset])))
    }

    // Menu-style background with pixeled clouds
    func setupMenuBackground() {
        guard let scene = scene else { return }
        let theme = ThemeManager.shared.currentTheme

        scene.backgroundColor = theme.skyColor

        // Hill 1
        let hill1 = SKShapeNode()
        let path1 = UIBezierPath()
        path1.move(to: CGPoint(x: 0, y: 0))
        path1.addLine(to: CGPoint(x: 0, y: scene.frame.height * 0.3))
        path1.addQuadCurve(
            to: CGPoint(x: scene.frame.width, y: scene.frame.height * 0.2),
            controlPoint: CGPoint(x: scene.frame.width * 0.5, y: scene.frame.height * 0.4)
        )
        path1.addLine(to: CGPoint(x: scene.frame.width, y: 0))
        path1.close()
        hill1.path = path1.cgPath
        hill1.fillColor = theme.hillColor
        hill1.strokeColor = .clear
        hill1.zPosition = -4
        scene.addChild(hill1)

        // Hill 2
        let hill2 = SKShapeNode()
        let path2 = UIBezierPath()
        path2.move(to: CGPoint(x: 0, y: 0))
        path2.addLine(to: CGPoint(x: 0, y: scene.frame.height * 0.15))
        path2.addQuadCurve(
            to: CGPoint(x: scene.frame.width, y: scene.frame.height * 0.25),
            controlPoint: CGPoint(x: scene.frame.width * 0.4, y: scene.frame.height * 0.05)
        )
        path2.addLine(to: CGPoint(x: scene.frame.width, y: 0))
        path2.close()
        hill2.path = path2.cgPath
        hill2.fillColor = theme.hillColorDark
        hill2.strokeColor = .clear
        hill2.zPosition = -3
        scene.addChild(hill2)

        // Pixeled clouds
        for _ in 0..<5 {
            spawnPixelCloud()
        }
    }

    func spawnPixelCloud() {
        guard let scene = scene else { return }

        let cloudContainer = SKNode()
        let blockSize: CGFloat = 20
        let cols = Int.random(in: 4...7)
        let rows = Int.random(in: 2...4)

        for r in 0..<rows {
            for c in 0..<cols {
                if Bool.random() || (r > 0 && r < rows - 1 && c > 0 && c < cols - 1) {
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
            x: CGFloat.random(in: 0...scene.frame.width),
            y: CGFloat.random(in: scene.frame.midY...scene.frame.maxY)
        )
        cloudContainer.zPosition = -6
        scene.addChild(cloudContainer)

        let move = SKAction.moveBy(x: scene.frame.width + 200, y: 0, duration: Double.random(in: 30...60))
        let reset = SKAction.moveBy(x: -(scene.frame.width + 400), y: 0, duration: 0)
        cloudContainer.run(SKAction.repeatForever(SKAction.sequence([move, reset])))
    }
}
