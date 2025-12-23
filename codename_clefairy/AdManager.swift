import GoogleMobileAds
import UIKit

@MainActor
class AdManager: NSObject, BannerViewDelegate, FullScreenContentDelegate {
    static let shared = AdManager()
    
    var onAdWillPresent: (() -> Void)?
    var onAdDidDismiss: (() -> Void)?
    
    private var interstitial: InterstitialAd?
    
    // AdMob Test IDs - Use for development and testing only.
    // Replace with production IDs for Release builds.
    private let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    private let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    
    private var bannerView: BannerView?
    
    func setupBanner(in viewController: UIViewController) {
        let viewWidth = viewController.view.frame.inset(by: viewController.view.safeAreaInsets).width
        
        let adaptiveSize = currentOrientationAnchoredAdaptiveBanner(width: viewWidth)
        
        bannerView = BannerView(adSize: adaptiveSize)
        bannerView?.adUnitID = bannerAdUnitID
        bannerView?.rootViewController = viewController
        bannerView?.delegate = self
        
        viewController.view.addSubview(bannerView!)
        bannerView?.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bannerView!.bottomAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.bottomAnchor),
            bannerView!.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor)
        ])
        
        bannerView?.load(Request())
    }
    
    func showBanner() {
        bannerView?.isHidden = false
    }
    
    func hideBanner() {
        bannerView?.isHidden = true
    }
    
    func loadInterstitial() {
        let request = Request()
        InterstitialAd.load(with: interstitialAdUnitID, request: request) { [weak self] ad, error in
            if let error = error {
                print("Failed to load interstitial ad with error: \(error.localizedDescription)")
                return
            }
            self?.interstitial = ad
            self?.interstitial?.fullScreenContentDelegate = self
        }
    }
    
    func showInterstitial(from viewController: UIViewController) {
        if let interstitial = interstitial {
            interstitial.present(from: viewController)
        } else {
            print("Ad wasn't ready")
            loadInterstitial()
        }
    }
    
    // MARK: - FullScreenContentDelegate
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        onAdWillPresent?()
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        onAdDidDismiss?()
        loadInterstitial() // Preload next
    }
}
