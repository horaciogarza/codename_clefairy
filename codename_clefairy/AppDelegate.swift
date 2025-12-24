//
//  AppDelegate.swift
//  codename_clefairy
//
//  Created by Horacio Garza on 18/12/25.
//

import UIKit
import GoogleMobileAds
import AppTrackingTransparency

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Initialize Google Mobile Ads SDK - Use renamed Swift members
        MobileAds.shared.start(completionHandler: nil)
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        ATTrackingManager.requestTrackingAuthorization { status in
            // Now you can load ads, regardless of the status
            Task { @MainActor in
                AdManager.shared.loadInterstitial()
            }
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

}