//
//  VillageContainer.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 2/3/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit
import VillageCore

public class VillageContainer: SideMenuController {
    
    public static func make() -> VillageContainer {
        return VillageContainer()
//        let storyboard = UIStoryboard(name: "VillageContainer", bundle: Constants.bundle)
//        return storyboard.instantiateInitialViewController() as! VillageContainer
    }
    
    private var window: UIWindow? = UIWindow()
    
    @IBOutlet private weak var backgroundImageView: UIImageView! {
        didSet {
            backgroundImageView.setImage(named: "app-background")
        }
    }
    
    private lazy var homeVC: UIViewController = {
        let storyboard = UIStoryboard(name: "HomeViewController", bundle: Constants.bundle)
        let homeVC = storyboard.instantiateInitialViewController() as! HomeViewController
        return UINavigationController(rootViewController: homeVC)
    }()

    convenience init() {
        let mainMenuVC: UIViewController = {
            let storyboard = UIStoryboard(name: "MainMenuViewController", bundle: Constants.bundle)
            let mainMenuVC = storyboard.instantiateInitialViewController()!
            return mainMenuVC
        }()
        
        let storyboard = UIStoryboard(name: "VillageContainer", bundle: Constants.bundle)
        let whileLoadingVC = storyboard.instantiateViewController(withIdentifier: "VillageContainerLoadingContentViewController")

        self.init(menuViewController: mainMenuVC, contentViewController: UINavigationController(rootViewController: whileLoadingVC))
    }
    
    // MARK: - UIViewController Overrides

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        openMenuProportionalWidth = 0.85
        openMenuContentScaledFactor = 1.0
        
        NotificationCenter.default.addObserver(forName: Notification.Name.User.CurrentUserDidChange, object: nil, queue: .main) { [weak self] (_) in
            if User.current.isGuest {
                self?.runAppStartupFlow()
            }
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func showHome() {
        if self.contentViewController != self.homeVC {
            self.setContentViewController(homeVC, fadeAnimation: true)
        }
        self.hideMenu()
    }

}

// MARK: UIApplicationDelegate

extension VillageContainer: UIApplicationDelegate {
 
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        window!.rootViewController = self
        window!.makeKeyAndVisible()
        
        do {
            try registerVillageFonts()
        } catch {
            print(error.localizedDescription)
        }
        
        print(ClientConfiguration.current)
        
        applyTheme()
        
        runAppStartupFlow()
        
        return true
    }
    
}

private extension VillageContainer {
    
    @IBAction func unwindToVillageContainer(segue: UIStoryboardSegue) {
        switch segue.source {
        case is LoginPasswordViewController:
            self.dismiss(animated: true, completion: nil)
            
        default:
            assertionFailure("Unable to handle unwind from \(String(describing: segue.source))")
            break
        }
    }
    
}

// MARK: - Private Methods

private extension VillageContainer {
    
    enum FontRegistrationError: Error {
        case emptyApplicationFonts
        case failedToLocateFontResource(String)
        case failedToReadFontData(String)
        case failedRegisteringFont(name: String, error: CFError)
        
        var localizedDescription: String {
            switch self {
            case .emptyApplicationFonts:
                return "⚠️ There are no framework fonts to load."
            case .failedToLocateFontResource(let fontName):
                return "🛑 Unable to locate \(fontName)'s file path URL!"
            case .failedToReadFontData(let fontName):
                return "🛑 Unable to read or process \(fontName)'s file!"
            case .failedRegisteringFont(let fontName, let error):
                return "🛑 Failed to register framework font \(fontName) because \(error.localizedDescription)!"
            }
        }
    }
    
    /// Attempts to register VillageCore's application fonts so that it is
    /// available to the host application.
    ///
    /// - Throws: FontRegistrationError
    func registerVillageFonts() throws {
        let frameworkBundle = Constants.bundle
        guard let appFonts = frameworkBundle.object(forInfoDictionaryKey: "UIAppFonts") as? [String] else {
            // There are no fonts to register
            throw FontRegistrationError.emptyApplicationFonts
        }
        
        try appFonts.forEach { (fontName) in
            guard let fontPath = frameworkBundle.path(forResource: fontName, ofType: nil) else {
                throw FontRegistrationError.failedToLocateFontResource(fontName)
            }
            
            guard
                let inData = NSData(contentsOfFile:fontPath),
                let provider = CGDataProvider(data: inData),
                let font = CGFont(provider)
            else {
                throw FontRegistrationError.failedToReadFontData(fontName)
            }
            
            var error: Unmanaged<CFError>?
            CTFontManagerRegisterGraphicsFont(font, &error)
            if let error = error {
                throw FontRegistrationError.failedRegisteringFont(name: fontName, error: error.takeUnretainedValue())
            }
        }
    }
    
    /// Applies the theme via appearance proxy.
    func applyTheme() {
        UINavigationBar.appearance().barTintColor = UIColor.vlgRed
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().titleTextAttributes = [
            .font: UIFont(name: "ProximaNova-Semibold", size: 15.0)!,
            .foregroundColor: UIColor.white
        ]
    }
    
    @objc func runAppStartupFlow() {
        
        if User.current.isGuest {
            showHome()
            let loginIdentityVC: LoginIdentityViewController = {
                let storyboard = UIStoryboard(name: "LoginIdentityViewController", bundle: Constants.bundle)
                let loginIdentityVC = storyboard.instantiateInitialViewController() as! LoginIdentityViewController
                return loginIdentityVC
            }()
            DispatchQueue.main.async {
                self.present(UINavigationController(rootViewController: loginIdentityVC), animated: false, completion: nil)
            }
        } else {
            firstly {
                User.current.loginWithDetails()
            }.then { [weak self] _ in
                self?.showHome()
            }.catch { [weak self] error in
                if case ServiceError.connectionFailed(_) = error {
                    // if the error is a connection failure, alert the user and offer to retry
                    let alert = UIAlertController(title: "Connection Offline", message: "The internet connection appears to be offline. Please connect and try again.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: { [weak self] (_) in
                        self?.runAppStartupFlow()
                    }))
                    self?.present(alert, animated: true, completion: nil)
                } else {
                    // otherwise, this is an un-handled error, and we will just show the guest landing screen
                    User.current = User.guest
                    self?.runAppStartupFlow()
                }
            }
        }
        
    }
    
}
