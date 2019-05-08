//
//  VillageContainer.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 2/3/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit
import UserNotifications
import VillageCore

public class VillageContainer: SideMenuController {
    
    public static func make() -> VillageContainer {
        return VillageContainer()
//        let storyboard = UIStoryboard(name: "VillageContainer", bundle: Constants.bundle)
//        return storyboard.instantiateInitialViewController() as! VillageContainer
    }
    
    public var window: UIWindow? = UIWindow()
    
    @IBOutlet private weak var backgroundImageView: UIImageView! {
        didSet {
            backgroundImageView.setImage(named: "app-background")
        }
    }
    
    private lazy var homeVC: UIViewController = {
        let storyboard = UIStoryboard(name: "Home", bundle: Constants.bundle)
        let homeVC = storyboard.instantiateInitialViewController() as! HomeController
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
        
        UNUserNotificationCenter.current().delegate = self
        registerForPushNotifications(shouldRequestAuthorization: false)
        
        return true
    }
    
    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let previousValue: String? = User.current.pushToken
        
        let hexString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("📲 \(hexString)")
        
        if !User.current.isGuest && (previousValue != hexString) {
            User.current.pushToken = hexString
            firstly {
                User.current.login()
            }.catch { error in
                // Undo saving of new pushToken
                User.current.pushToken = previousValue
                print("📲🛑 Failed to register new device token: \(error)")
            }
        }
    }
    
    public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("📲🛑 \(error)")
    }
    
}

private extension VillageContainer {
    
    @IBAction func unwindToVillageContainer(segue: UIStoryboardSegue) {
        switch segue.source {
        case is LoginPasswordViewController:
            self.dismiss(animated: true, completion: { [weak self] in
                self?.registerForPushNotifications(shouldRequestAuthorization: true)
            })
            
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
        
        UISearchBar.appearance().tintColor = .white
        UISearchBar.appearance().barTintColor = .white
        UISearchBar.appearance().searchBarStyle = .minimal
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).attributedPlaceholder = NSAttributedString(string: "Search", attributes: [
            .foregroundColor: UIColor.vlgLightGray
            ])
        
        
        
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
                self?.registerForPushNotifications(shouldRequestAuthorization: true)
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
    
    
    
    func registerForPushNotifications(shouldRequestAuthorization: Bool) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings(completionHandler: {
            notificationSettings in
            switch notificationSettings.authorizationStatus {
            case .notDetermined where shouldRequestAuthorization:
                center.requestAuthorization(options: [.badge, .alert, .sound], completionHandler: {
                    (granted, error) in
                    
                    if error == nil {
                        DispatchQueue.main.async {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                    }
                })
                
            case .authorized:
                // We've already primed the user, but we need to register for remote notifications anyway
                // This is how we'll always make sure we have the latest deviceToken
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                
            default:
                break
            }
        })
    }
    
}

extension VillageContainer: UNUserNotificationCenterDelegate {
    
    // Launch or open app from push
    // User may not have been authenticated or finished app startup flow yet
    //
    //  <UNNotificationResponse: 0x283f34e60; actionIdentifier: com.apple.UNNotificationDefaultActionIdentifier, notification: <UNNotification: 0x283f350c0; date: 2019-05-08 19:53:13 +0000, request: <UNNotificationRequest: 0x283131da0; identifier: 6A24FA14-A411-4512-9A5F-AD20BC7BFE3F, content: <UNNotificationContent: 0x280a05c80; title: (null), subtitle: (null), body: Test, summaryArgument: , summaryArgumentCount: 0, categoryIdentifier: , launchImageName: , threadIdentifier: , attachments: (
    //    ), badge: 1, sound: <UNNotificationSound: 0x281b208a0>,, trigger: <UNPushNotificationTrigger: 0x283d16040; contentAvailable: NO, mutableContent: NO>>>>
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            // User tapped on notification
            print("📲👆 User tapped on notification: \(response)")
            
        case UNNotificationDismissActionIdentifier:
            // User dismissed notification
            break
            
        default:
            assertionFailure()
            break
        }
        
        completionHandler()
    }

    // While app is running
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("📲⚡️ Incoming notification: \(notification)")
        completionHandler([.alert, .badge, .sound])
//        completionHandler([])
    }
}
