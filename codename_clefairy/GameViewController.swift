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
        
        // Request ATT permission
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { [weak self] status in
                // This completion handler is called on a background thread.
                // We need to switch to the main thread to present the scene.
                DispatchQueue.main.async {
                    self?.presentLaunchScene()
                }
            }
        } else {
            presentLaunchScene()
        }
    }
    
    private func presentLaunchScene() {
        if !sceneInitialized {
            if let view = self.view as! SKView? {
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
