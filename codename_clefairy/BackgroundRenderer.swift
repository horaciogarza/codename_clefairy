import SpriteKit

class BackgroundRenderer {
    weak var scene: SKScene?

    // Size of a "pixel" block for the 8-bit silhouettes.
    private let pixel: CGFloat = 22

    init(scene: SKScene) {
        self.scene = scene
    }

    // MARK: - Game environment

    func updateEnvironment(isFrenzyMode: Bool) {
        guard let scene = scene else { return }
        let theme = ThemeManager.shared.currentTheme

        scene.children.filter { $0.name == "bg_element" }.forEach { $0.removeFromParent() }

        scene.backgroundColor = isFrenzyMode ? theme.frenzyBgColor : theme.skyColor

        // Celestial body (pixel sun) or starfield on dark skies.
        let sky = isFrenzyMode ? theme.frenzyBgColor : theme.skyColor
        if isDark(sky) {
            addStars(count: isFrenzyMode ? 40 : 28)
        } else {
            addCelestialBody(color: isFrenzyMode ? theme.frenzyHillColor : theme.accentColor)
        }

        // Distant parallax mountains.
        addMountains(color: (isFrenzyMode ? theme.frenzyHillColor : theme.hillColorDark).withAlphaComponent(0.55))

        // Back + front stepped hills for depth.
        addSteppedHill(
            baseHeight: scene.frame.height * 0.22,
            amplitude: scene.frame.height * 0.10,
            color: isFrenzyMode ? blend(theme.frenzyHillColor, .black, 0.25) : theme.hillColorDark,
            zPosition: -4
        )
        addSteppedHill(
            baseHeight: scene.frame.height * 0.14,
            amplitude: scene.frame.height * 0.07,
            color: isFrenzyMode ? theme.frenzyHillColor : theme.hillColor,
            zPosition: -3
        )

        let cloudCount = isFrenzyMode ? 8 : 4
        for _ in 0..<cloudCount {
            spawnCloud(isFrenzyMode: isFrenzyMode)
        }

        ensureScanlines()
    }

    func setupDayBackground() {
        guard let scene = scene else { return }
        let theme = ThemeManager.shared.currentTheme

        addCelestialBody(color: theme.accentColor)
        addMountains(color: theme.hillColorDark.withAlphaComponent(0.55))
        addSteppedHill(baseHeight: scene.frame.height * 0.25, amplitude: scene.frame.height * 0.10,
                       color: theme.hillColorDark, zPosition: -4)
        addSteppedHill(baseHeight: scene.frame.height * 0.16, amplitude: scene.frame.height * 0.07,
                       color: theme.hillColor, zPosition: -3)

        for _ in 0..<4 {
            spawnCloud(isFrenzyMode: false)
        }
        ensureScanlines()
    }

    // MARK: - Boss environment

    /// Replaces the whole-screen landscape with a boss-specific palette and an
    /// ominous vignette. All elements use the "bg_element" name so the next normal
    /// level's `updateEnvironment` clears them and restores the regular theme.
    func applyBossEnvironment(_ boss: BossDef) {
        guard let scene = scene else { return }

        scene.children.filter { $0.name == "bg_element" }.forEach { $0.removeFromParent() }
        scene.backgroundColor = boss.skyColor

        if isDark(boss.skyColor) {
            addStars(count: 38)
        } else {
            addCelestialBody(color: boss.accentColor)
        }

        addMountains(color: boss.hillColorDark.withAlphaComponent(0.6))
        addSteppedHill(
            baseHeight: scene.frame.height * 0.22,
            amplitude: scene.frame.height * 0.10,
            color: blend(boss.hillColorDark, .black, 0.25),
            zPosition: -4
        )
        addSteppedHill(
            baseHeight: scene.frame.height * 0.14,
            amplitude: scene.frame.height * 0.07,
            color: boss.hillColor,
            zPosition: -3
        )

        for _ in 0..<6 {
            spawnCloud(isFrenzyMode: true)
        }

        addVignette(accent: boss.accentColor)
        ensureScanlines()
    }

    private func addVignette(accent: SKColor) {
        guard let scene = scene else { return }
        let size = scene.frame.size
        guard size.width > 0, size.height > 0 else { return }

        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let c = ctx.cgContext
            let tint = blend(.black, accent, 0.15)
            let colors = [
                tint.withAlphaComponent(0.0).cgColor,
                tint.withAlphaComponent(0.0).cgColor,
                tint.withAlphaComponent(0.65).cgColor
            ] as CFArray
            let locations: [CGFloat] = [0.0, 0.55, 1.0]
            let space = CGColorSpaceCreateDeviceRGB()
            guard let grad = CGGradient(colorsSpace: space, colors: colors, locations: locations) else { return }
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = max(size.width, size.height) * 0.75
            c.drawRadialGradient(grad, startCenter: center, startRadius: 0,
                                 endCenter: center, endRadius: radius, options: [])
        }
        let tex = SKTexture(image: img)
        let overlay = SKSpriteNode(texture: tex)
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.zPosition = -2
        overlay.name = "bg_element"
        scene.addChild(overlay)
    }

    // MARK: - Menu / static screens

    func setupMenuBackground() {
        guard let scene = scene else { return }
        let theme = ThemeManager.shared.currentTheme

        scene.backgroundColor = theme.skyColor

        if isDark(theme.skyColor) {
            addStars(count: 30)
        } else {
            addCelestialBody(color: theme.accentColor)
        }
        addMountains(color: theme.hillColorDark.withAlphaComponent(0.5))
        addSteppedHill(baseHeight: scene.frame.height * 0.30, amplitude: scene.frame.height * 0.10,
                       color: theme.hillColorDark, zPosition: -4)
        addSteppedHill(baseHeight: scene.frame.height * 0.18, amplitude: scene.frame.height * 0.08,
                       color: theme.hillColor, zPosition: -3)

        for _ in 0..<5 {
            spawnPixelCloud()
        }
        ensureScanlines()
    }

    // MARK: - Clouds

    /// Drifting blocky cloud (used by gameplay + launch screen).
    func spawnCloud(isFrenzyMode: Bool) {
        guard let scene = scene else { return }

        let cloud = makePixelCloud()
        cloud.name = "bg_element"
        cloud.alpha = CGFloat.random(in: 0.75...0.95)
        cloud.position = CGPoint(
            x: CGFloat.random(in: -100...scene.frame.width),
            y: CGFloat.random(in: scene.frame.midY...scene.frame.maxY - 100)
        )
        cloud.zPosition = -6
        scene.addChild(cloud)

        let baseDuration = Double.random(in: 40...80)
        let duration = isFrenzyMode ? baseDuration / 4 : baseDuration
        let move = SKAction.moveBy(x: scene.frame.width + 300, y: 0, duration: duration)
        let reset = SKAction.moveBy(x: -(scene.frame.width + 500), y: 0, duration: 0)
        cloud.run(SKAction.repeatForever(SKAction.sequence([move, reset])))
    }

    func spawnPixelCloud() {
        guard let scene = scene else { return }

        let cloud = makePixelCloud()
        cloud.alpha = 0.85
        cloud.position = CGPoint(
            x: CGFloat.random(in: 0...scene.frame.width),
            y: CGFloat.random(in: scene.frame.midY...scene.frame.maxY)
        )
        cloud.zPosition = -6
        scene.addChild(cloud)

        let move = SKAction.moveBy(x: scene.frame.width + 200, y: 0, duration: Double.random(in: 30...60))
        let reset = SKAction.moveBy(x: -(scene.frame.width + 400), y: 0, duration: 0)
        cloud.run(SKAction.repeatForever(SKAction.sequence([move, reset])))
    }

    /// Builds a chunky, symmetrical pixel cloud with a shaded underside.
    private func makePixelCloud(blockSize: CGFloat = 18) -> SKNode {
        let container = SKNode()
        let cols = Int.random(in: 5...8)
        let rows = Int.random(in: 2...3)

        for r in 0..<rows {
            for c in 0..<cols {
                // Knock out random corner blocks so the silhouette reads as a rounded puff.
                let isCorner = (r == rows - 1) && (c == 0 || c == cols - 1)
                if isCorner && Bool.random() { continue }

                let block = SKShapeNode(rectOf: CGSize(width: blockSize, height: blockSize))
                // Bottom row gets a soft gray shade for depth.
                block.fillColor = (r == 0)
                    ? SKColor(white: 0.82, alpha: 1.0)
                    : .white
                block.strokeColor = .clear
                block.position = CGPoint(x: CGFloat(c) * blockSize, y: CGFloat(r) * blockSize)
                container.addChild(block)
            }
        }
        return container
    }

    // MARK: - Stepped pixel hills

    /// Adds a staircase-silhouette hill made of grid-snapped blocks.
    private func addSteppedHill(baseHeight: CGFloat, amplitude: CGFloat, color: SKColor, zPosition: CGFloat) {
        guard let scene = scene else { return }
        let width = scene.frame.width
        let phase = CGFloat.random(in: 0...(.pi * 2))
        let wavelength = width / CGFloat.random(in: 1.2...2.2)

        let path = UIBezierPath()
        path.move(to: .zero)

        var x: CGFloat = 0
        while x < width {
            let next = min(x + pixel, width)
            let mid = x + (next - x) / 2
            let raw = baseHeight + sin(mid / wavelength * .pi * 2 + phase) * amplitude
            let stepped = (raw / pixel).rounded() * pixel
            path.addLine(to: CGPoint(x: x, y: stepped))
            path.addLine(to: CGPoint(x: next, y: stepped))
            x = next
        }

        path.addLine(to: CGPoint(x: width, y: 0))
        path.close()

        let hill = SKShapeNode(path: path.cgPath)
        hill.fillColor = color
        hill.strokeColor = .clear
        hill.zPosition = zPosition
        hill.name = "bg_element"
        scene.addChild(hill)
    }

    /// Far-off triangular mountain range, quantized to pixel steps.
    private func addMountains(color: SKColor) {
        guard let scene = scene else { return }
        let width = scene.frame.width
        let base = scene.frame.height * 0.20
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: base))

        var x: CGFloat = 0
        let peakSpacing = pixel * 7
        while x < width {
            let peakX = x + peakSpacing / 2
            let peakY = base + CGFloat.random(in: pixel * 3...pixel * 6)
            steppedSlope(path: path, from: CGPoint(x: x, y: base), to: CGPoint(x: peakX, y: peakY))
            steppedSlope(path: path, from: CGPoint(x: peakX, y: peakY), to: CGPoint(x: x + peakSpacing, y: base))
            x += peakSpacing
        }
        path.addLine(to: CGPoint(x: width, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.close()

        let mountains = SKShapeNode(path: path.cgPath)
        mountains.fillColor = color
        mountains.strokeColor = .clear
        mountains.zPosition = -5
        mountains.name = "bg_element"
        scene.addChild(mountains)
    }

    private func steppedSlope(path: UIBezierPath, from: CGPoint, to: CGPoint) {
        let steps = max(1, Int(abs(to.x - from.x) / pixel))
        for i in 1...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let x = from.x + (to.x - from.x) * t
            let y = ((from.y + (to.y - from.y) * t) / pixel).rounded() * pixel
            path.addLine(to: CGPoint(x: path.currentPoint.x, y: y))
            path.addLine(to: CGPoint(x: x, y: y))
        }
    }

    // MARK: - Sun & stars

    private func addCelestialBody(color: SKColor) {
        guard let scene = scene else { return }
        let sun = makePixelDisc(radius: pixel * 2.5, color: color, block: pixel * 0.9)
        sun.position = CGPoint(x: scene.frame.width * 0.78, y: scene.frame.height * 0.80)
        sun.zPosition = -7
        sun.name = "bg_element"
        sun.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.06, duration: 1.4),
            SKAction.scale(to: 1.00, duration: 1.4)
        ])))
        scene.addChild(sun)
    }

    private func makePixelDisc(radius: CGFloat, color: SKColor, block: CGFloat) -> SKNode {
        let node = SKNode()
        var y = -radius
        while y <= radius {
            var x = -radius
            while x <= radius {
                let cx = x + block / 2
                let cy = y + block / 2
                if cx * cx + cy * cy <= radius * radius {
                    let b = SKShapeNode(rectOf: CGSize(width: block, height: block))
                    b.fillColor = color
                    b.strokeColor = .clear
                    b.position = CGPoint(x: cx, y: cy)
                    node.addChild(b)
                }
                x += block
            }
            y += block
        }
        return node
    }

    private func addStars(count: Int) {
        guard let scene = scene else { return }
        for _ in 0..<count {
            let size = [2.0, 3.0, 4.0].randomElement()!
            let star = SKShapeNode(rectOf: CGSize(width: size, height: size))
            star.fillColor = .white
            star.strokeColor = .clear
            star.position = CGPoint(
                x: CGFloat.random(in: 0...scene.frame.width),
                y: CGFloat.random(in: scene.frame.height * 0.45...scene.frame.maxY)
            )
            star.zPosition = -7
            star.name = "bg_element"
            star.alpha = CGFloat.random(in: 0.4...1.0)
            let twinkle = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.25, duration: Double.random(in: 0.6...1.6)),
                SKAction.fadeAlpha(to: 1.0, duration: Double.random(in: 0.6...1.6))
            ])
            star.run(SKAction.repeatForever(twinkle))
            scene.addChild(star)
        }
    }

    // MARK: - CRT scanlines (persistent overlay)

    private func ensureScanlines() {
        guard let scene = scene else { return }
        if scene.childNode(withName: "scanlines") != nil { return }

        let size = scene.frame.size
        guard size.width > 0, size.height > 0 else { return }

        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            UIColor.black.withAlphaComponent(0.10).setFill()
            var y: CGFloat = 0
            while y < size.height {
                ctx.fill(CGRect(x: 0, y: y, width: size.width, height: 1.0))
                y += 3
            }
        }
        let tex = SKTexture(image: img)
        tex.filteringMode = .nearest

        let overlay = SKSpriteNode(texture: tex)
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.zPosition = -1
        overlay.alpha = 0.5
        overlay.name = "scanlines"
        scene.addChild(overlay)
    }

    // MARK: - Color helpers

    private func isDark(_ color: SKColor) -> Bool {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (0.299 * r + 0.587 * g + 0.114 * b) < 0.4
    }

    private func blend(_ a: SKColor, _ b: SKColor, _ t: CGFloat) -> SKColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        a.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        b.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return SKColor(
            red: r1 + (r2 - r1) * t,
            green: g1 + (g2 - g1) * t,
            blue: b1 + (b2 - b1) * t,
            alpha: a1 + (a2 - a1) * t
        )
    }
}
