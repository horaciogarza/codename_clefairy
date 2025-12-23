//
//  GameViewController.swift
//  codename_clefairy
//
//  Created by Horacio Garza on 18/12/25.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    private var sceneInitialized = false

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !sceneInitialized {
            if let view = self.view as! SKView? {
                // Create the launch scene with correct bounds
                let scene = LaunchScene(size: view.bounds.size)
                scene.scaleMode = .aspectFill
                view.presentScene(scene)
                
                view.ignoresSiblingOrder = true
                view.showsFPS = false
                view.showsNodeCount = false
                
                // Setup AdMob Banner
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