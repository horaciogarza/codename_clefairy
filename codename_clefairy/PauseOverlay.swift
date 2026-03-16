import SpriteKit

protocol PauseOverlayDelegate: AnyObject {
    func pauseOverlayDidResume()
    func pauseOverlayDidRestart()
    func pauseOverlayDidGoToMenu()
}

class PauseOverlay: SKNode {
    weak var delegate: PauseOverlayDelegate?

    private let overlaySize: CGSize

    init(size: CGSize) {
        self.overlaySize = size
        super.init()
        self.name = "pause_overlay"
        self.zPosition = 900
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    private func setup() {
        // Dim background
        let bg = SKShapeNode(rectOf: overlaySize)
        bg.fillColor = .black.withAlphaComponent(0.7)
        bg.strokeColor = .clear
        bg.position = CGPoint(x: overlaySize.width / 2, y: overlaySize.height / 2)
        addChild(bg)

        // Panel
        let panel = UIFactory.createCartoonBoard(
            size: CGSize(width: overlaySize.width * 0.7, height: 320),
            color: SKColor(red: 0.15, green: 0.15, blue: 0.25, alpha: 1.0)
        )
        panel.position = CGPoint(x: overlaySize.width / 2, y: overlaySize.height / 2)
        addChild(panel)

        // Title
        let title = SKLabelNode(fontNamed: "Gameplay")
        title.text = "PAUSED"
        title.fontSize = 40
        title.fontColor = .white
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: 0, y: 100)
        panel.addChild(title)

        // Resume
        let resumeBtn = UIFactory.createButtonWithIcon(
            text: "RESUME",
            systemName: "play.fill",
            color: .systemGreen,
            size: CGSize(width: 220, height: 55),
            iconSize: 18
        )
        resumeBtn.position = CGPoint(x: 0, y: 20)
        resumeBtn.name = "pause_resume"
        panel.addChild(resumeBtn)

        // Restart
        let restartBtn = UIFactory.createButtonWithIcon(
            text: "RESTART",
            systemName: "arrow.counterclockwise",
            color: .systemOrange,
            size: CGSize(width: 220, height: 55),
            iconSize: 18
        )
        restartBtn.position = CGPoint(x: 0, y: -50)
        restartBtn.name = "pause_restart"
        panel.addChild(restartBtn)

        // Menu
        let menuBtn = UIFactory.createButtonWithIcon(
            text: "MENU",
            systemName: "house.fill",
            color: .systemBlue,
            size: CGSize(width: 220, height: 55),
            iconSize: 18
        )
        menuBtn.position = CGPoint(x: 0, y: -120)
        menuBtn.name = "pause_menu"
        panel.addChild(menuBtn)
    }

    func handleTouch(at location: CGPoint) -> Bool {
        let nodes = self.nodes(at: location)
        for node in nodes {
            let target = node.name == "btn_body" ? node.parent : node
            let name = target?.name ?? node.name

            switch name {
            case "pause_resume":
                delegate?.pauseOverlayDidResume()
                return true
            case "pause_restart":
                delegate?.pauseOverlayDidRestart()
                return true
            case "pause_menu":
                delegate?.pauseOverlayDidGoToMenu()
                return true
            default:
                continue
            }
        }
        return true // Consume all touches when overlay is showing
    }

    // MARK: - Pause Button (static factory for top-right button)

    static func createPauseButton(frame: CGRect, safeTop: CGFloat) -> SKNode {
        let container = SKNode()
        container.name = "pause_button"
        container.zPosition = 60

        let bg = SKShapeNode(circleOfRadius: 22)
        bg.fillColor = .white.withAlphaComponent(0.3)
        bg.strokeColor = .white
        bg.lineWidth = 2
        bg.name = "btn_body"
        container.addChild(bg)

        if let icon = UIFactory.symbolSprite("pause.fill", pointSize: 18, color: .white, size: CGSize(width: 18, height: 18)) {
            icon.zPosition = 1
            icon.name = "pause_button"
            container.addChild(icon)
        }

        container.position = CGPoint(x: frame.maxX - 50, y: frame.maxY - safeTop - 40)

        return container
    }
}
