
import UIKit
import GoogleMobileAds
import PersonalizedAdConsent
import StoreKit
import AdSupport

class AdController: UIViewController, GADBannerViewDelegate, SKStoreProductViewControllerDelegate {

    @IBOutlet weak var bannerView: GADBannerView!
    
    fileprivate func requestPermission() {
        // Geography appears as in EEA for debug devices.
        //PACConsentInformation.sharedInstance.debugGeography = PACDebugGeography.EEA;
        // Add test devices for EEA
        //PACConsentInformation.sharedInstance.debugIdentifiers = ["CD7989B1-A729-4F74-97B7-EE3D5A910407"]
        
        //Update consent status
        PACConsentInformation.sharedInstance.requestConsentInfoUpdate(
            forPublisherIdentifiers: ["pub-3658144280100378"])
        {(_ error: Error?) -> Void in
            if error != nil {
                // Consent info update failed.
            } else {
                // Consent info update succeeded. The shared PACConsentInformation
                // instance has been updated.
                self.showConsentForm()
            }
        }

    }
    
    func showConsentForm() {
        guard let privacyUrl = URL(string: "https://deb761.github.io/documentation/privacy_policy.html"),
            let form = PACConsentForm(applicationPrivacyPolicyURL: privacyUrl) else {
                print("incorrect privacy URL.")
                return
        }
        
        form.shouldOfferPersonalizedAds = true
        form.shouldOfferNonPersonalizedAds = true
        form.shouldOfferAdFree = true
        
        form.load {(_ error: Error?) -> Void in
            print("Load complete.")
            if let error = error {
                // Handle error.
                print("Error loading form: \(error.localizedDescription)")
            } else {
                // Load successful.
                form.present(from: self) { (error, userPrefersAdFree) in
                    if let error = error {
                        // Handle error.
                        print("Error presenting form: \(error.localizedDescription)")
                    } else if userPrefersAdFree {
                        // User prefers to use a paid version of the app.
                        // redirect to app store and close app
                        print("User prefers ad free version")
                        self.gotoAppStore()
                    } else {
                        // Check the user's consent choice.
                        let status =
                            PACConsentInformation.sharedInstance.consentStatus
                        let request = DFPRequest()
                        let extras = GADExtras()
                        extras.additionalParameters = ["npa": (status == .personalized) ? "0" : "1"]
                        request.register(extras)
                    }
                }
                
            }
        }
    }//<a href="https://itunes.apple.com/us/app/yarn-requirements/id1141978276?mt=8">Yarn Requirements - Deborah Engelmeyer</a>
    
    func gotoAppStore() {
        let vc: SKStoreProductViewController = SKStoreProductViewController()
        let params = [
            SKStoreProductParameterITunesItemIdentifier:1141978276,
            ] as [String : Any]
        vc.delegate = self
        vc.loadProduct(withParameters: params, completionBlock: nil)
        self.present(vc, animated: true) { () -> Void in }
    }
    
    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Advertising ID: \(ASIdentifierManager.shared().advertisingIdentifier.uuidString)")
        // Load test ads for debug
        if _isDebugAssertConfiguration() {
            bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        } else {
            bannerView.adUnitID = "ca-app-pub-3658144280100378/4152974916"
        }
        bannerView.rootViewController = self
        bannerView.delegate = self
        bannerView.load(GADRequest())
        
        requestPermission()
    }
    
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        // Add banner to view and add constraints as above.
        addBannerViewToView(bannerView)
    }

    func addBannerViewToView(_ bannerView: UIView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        /*if #available(iOS 11.0, *) {
            positionBannerAtBottomOfSafeArea(bannerView)
        }
        else {
            positionBannerAtBottomOfView(bannerView)
        }*/
    }
    
    @available (iOS 11, *)
    func positionBannerAtBottomOfSafeArea(_ bannerView: UIView) {
        // Position the banner. Stick it to the bottom of the Safe Area.
        // Centered horizontally.
        let guide: UILayoutGuide = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate(
            [bannerView.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
             bannerView.bottomAnchor.constraint(equalTo: guide.bottomAnchor)]
        )

    }
    
    func positionBannerAtBottomOfView(_ bannerView: UIView) {
        // Center the banner horizontally.
        view.addConstraint(NSLayoutConstraint(item: bannerView,
                                              attribute: .centerX,
                                              relatedBy: .equal,
                                              toItem: view,
                                              attribute: .centerX,
                                              multiplier: 1,
                                              constant: 0))
        // Lock the banner to the top of the bottom layout guide.
        view.addConstraint(NSLayoutConstraint(item: bannerView,
                                              attribute: .bottom,
                                              relatedBy: .equal,
                                              toItem: view.safeAreaLayoutGuide,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 0))
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
}
