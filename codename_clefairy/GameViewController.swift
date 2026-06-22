//
//  GameViewController.swift
//  codename_clefairy
//
//  Created by Horacio Garza on 18/12/25.
//

import UIKit
import SpriteKit
import GameplayKit
import AppTrackingTransparency

class GameViewController: UIViewController {

    private var sceneInitialized = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Present the game immediately — don't gate the launch screen behind ATT.
        presentLaunchScene()

        // Request ATT after a short delay so it appears as an overlay above the game.
        if #available(iOS 14, *) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                ATTrackingManager.requestTrackingAuthorization { _ in }
            }
        }
    }
    
    private func presentLaunchScene() {
        if !sceneInitialized {
            if let view = self.view as? SKView {
                let scene = LaunchScene(size: view.bounds.size)
                scene.scaleMode = .aspectFill
                view.presentScene(scene)
                
                view.ignoresSiblingOrder = true
                view.showsFPS = false
                view.showsNodeCount = false
                
                Task { @MainActor in
                    AdManager.shared.setupBanner(in: self)
                }
            }
            sceneInitialized = true
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    @objc private func appDidEnterBackground() {
        guard let skView = self.view as? SKView,
              let gameScene = skView.scene as? GameScene else { return }
        gameScene.pauseGame()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
