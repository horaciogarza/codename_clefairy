//
//  AppDelegate.swift
//  codename_clefairy
//
//  Created by Horacio Garza on 18/12/25.
//

import UIKit
import GoogleMobileAds

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Initialize Google Mobile Ads SDK - Use renamed Swift members
        MobileAds.shared.start(completionHandler: nil)
        
        // Preload first ad
        Task { @MainActor in
            AdManager.shared.loadInterstitial()
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }


}