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
    }
    
    public var window: UIWindow? = UIWindow()
    
    @IBOutlet private weak var backgroundImageView: UIImageView! {
        didSet {
            backgroundImageView.setImage(named: "app-background")
        }
    }

    #warning("JACK - Remove old homeVC once DONV-345 is complete")
    private lazy var homeVC: UIViewController = {
        let storyboard = UIStoryboard(name: "Home", bundle: Constants.bundle)
        let homeVC = storyboard.instantiateInitialViewController() as! HomeController
        return UINavigationController(rootViewController: homeVC)
    }()

    private lazy var newHomeVC: UIViewController = {
        let storyboard = UIStoryboard(name: "NewHomeStream", bundle: Constants.bundle)
        let homeVC = storyboard.instantiateInitialViewController() as! NewHomeStreamViewController
        return UINavigationController(rootViewController: homeVC)
    }()
    
    // Notification & Route Handling
    
    private enum Route {
        case directMessage(streamId: String)
        case notices
        case myReceivedKudos
        case group(streamId: String)
    }
    
    private var pendingRoute: Route?
    
    private var isReadyToPerformPendingRoute: Bool {
        guard let contentViewController = self.contentViewController else {
            return false
        }
        return  !User.current.isGuest
            && contentViewController.restorationIdentifier != VillageContainer.loadingContentViewControllerIdentifier
    }
    
    private var openDirectMessageStream: VillageCore.Stream?
    
    private static let loadingContentViewControllerIdentifier = "VillageContainerLoadingContentViewController"
    
    // Init

    convenience init() {
        let mainMenuVC: UIViewController = {
            let storyboard = UIStoryboard(name: "MainMenuViewController", bundle: Constants.bundle)
            let mainMenuVC = storyboard.instantiateInitialViewController()!
            return mainMenuVC
        }()
        
        let storyboard = UIStoryboard(name: "VillageContainer", bundle: Constants.bundle)
        let whileLoadingVC = storyboard.instantiateViewController(withIdentifier: VillageContainer.loadingContentViewControllerIdentifier)

        self.init(menuViewController: mainMenuVC, contentViewController: whileLoadingVC)
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
        
        NotificationCenter.default.addObserver(forName: Notification.Name.Stream.IsViewingDirectMessageConversation, object: nil, queue: .main) {
            [weak self] notification in
            
            self?.openDirectMessageStream = notification.userInfo?[Notification.Name.Stream.directMessageConversationKey] as? VillageCore.Stream
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    #warning("JACK - Remove isNew param once DONV-345 is complete")
    func showHome(isNew: Bool) {
        func setHomeVC(animated: Bool) {
            if self.contentViewController != self.homeVC {
                self.setContentViewController(homeVC, fadeAnimation: animated)
            }
            self.hideMenu()
        }

        func setNewHomeVC(animated: Bool) {
            if self.contentViewController != self.newHomeVC {
                self.setContentViewController(newHomeVC, fadeAnimation: animated)
            }
            self.hideMenu()
        }
        
        func performPendingRoute(_ route: Route) {
            self.performRoute(route)
            self.pendingRoute = nil
        }
        
        if let route = self.pendingRoute {
            if isReadyToPerformPendingRoute {
                performPendingRoute(route)
            } else {
                if !isNew {
                    setHomeVC(animated: false)
                } else {
                    setNewHomeVC(animated: false)
                }
                DispatchQueue.main.async {
                    if self.isReadyToPerformPendingRoute {
                        performPendingRoute(route)
                    } else {
                        assertionFailure("Unable to perform the route for some unknown reason!")
                        self.pendingRoute = nil
                    }
                }
            }
        } else {
            if !isNew {
                setHomeVC(animated: true)
            } else {
                setNewHomeVC(animated: true)
            }
        }
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
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        
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
                guard let `self` = self else { return }
                
                self.registerForPushNotifications(shouldRequestAuthorization: true)
                if self.isReadyToPerformPendingRoute, let route = self.pendingRoute {
                    self.performRoute(route)
                    self.pendingRoute = nil
                }
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
        UINavigationBar.appearance().prefersLargeTitles = true
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font: UIFont(name: "ProximaNova-Extrabld", size: 30.0)!,
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
            showHome(isNew: false)
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
                self?.showHome(isNew: false)
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

// MARK: - Routing

private extension VillageContainer {
    
    private func route(for notification: UNNotification) -> Route? {
        let payload = notification.request.content.userInfo
        
        guard let notificationType = payload["type"] as? String else {
            return nil
        }
        
        switch notificationType.lowercased() {
        case "deeplink":
            let linkComponents = payload["link"]
                .flatMap({ $0 as? String })
                .flatMap({ URLComponents(string: $0) })
            
            switch linkComponents?.host {
            case "dm"?:
                guard let streamId = linkComponents?.queryItems?.filter({ $0.name == "streamId" }).first?.value else {
                    break
                }
                return Route.directMessage(streamId: streamId)
                
            case "notice"?:
                return Route.notices
                
            case "kudos"?:
                return Route.myReceivedKudos
                
            default:
                break
            }
            
        case "invite":
            let linkComponents = payload["link"]
                .flatMap({ $0 as? String })
                .flatMap({ URLComponents(string: $0) })
            guard let streamId = linkComponents?.queryItems?.filter({ $0.name == "streamId" }).first?.value else {
                break
            }
            return Route.group(streamId: streamId)
            
        case "unread":
            // We have chosen to ignore unread notifications but they do exist
            // in the backend so I am leaving this case in here for documentation
            // purposes. -rlf
            break
            
        default:
            break
        }
        
        return nil
    }
    
    private func performRoute(_ route: Route) {
        guard isReadyToPerformPendingRoute else {
            assertionFailure()
            return
        }
        
        switch route {
        case let .directMessage(streamId):
            goToDirectMessage(id: streamId)
            
        case let .group(streamId):
            goToGroup(id: streamId)
            
        case .notices:
            goToNotices()
            
        case .myReceivedKudos:
            goToMyReceivedKudos()
        }
    }
    
    func goToDirectMessage(id: String) {
        firstly {
            return VillageCore.Stream.getBy(id)
        }.then { [weak self] stream in
            let dataSource = DirectMessageStreamDataSource(stream: stream)
            let vc = StreamViewController(dataSource: dataSource)
            self?.setContentViewController(UINavigationController(rootViewController: vc), fadeAnimation: true)
            self?.hideMenu()
        }.catch { _ in
            // Silently ignore errors here as we will just not honor the user's tap on the notification
        }
    }
    
    func goToGroup(id: String) {
        firstly {
            return VillageCore.Stream.getBy(id)
        }.then { [weak self] stream in
            let dataSource = GroupStreamDataSource(stream: stream)
            let vc = StreamViewController(dataSource: dataSource)
            self?.setContentViewController(UINavigationController(rootViewController: vc), fadeAnimation: true)
            self?.hideMenu()
        }.catch { _ in
            // Silently ignore errors here as we will just not honor the user's tap on the notification
        }
    }
    
    func goToNotices() {
        let vc = UIStoryboard(name: "Notices", bundle: Constants.bundle).instantiateInitialViewController() as! NoticeListViewController
        self.setContentViewController(UINavigationController(rootViewController: vc), fadeAnimation: true)
        self.hideMenu()
    }
    
    func goToMyReceivedKudos() {
        let vc = UIStoryboard(name: "Kudos", bundle: Constants.bundle).instantiateViewController(withIdentifier: "MyKudosViewController") as! MyKudosViewController
        self.setContentViewController(UINavigationController(rootViewController: vc), fadeAnimation: true)
        self.hideMenu()
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
            print("📲👆 User tapped on notification: \(response)")
            
            guard let route = route(for: response.notification) else {
                print("📲⚠️ Unable to parse a route for incoming notification: \(response.notification)")
                break
            }
            
            if isReadyToPerformPendingRoute {
                performRoute(route)
            } else {
                pendingRoute = route
            }
            
        case UNNotificationDismissActionIdentifier:
            // User dismissed notification
            break
            
        default:
            break
        }
        
        completionHandler()
    }

    // While app is running
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("📲⚡️ Incoming notification: \(notification)")
        
        switch route(for: notification) {
        case let Route.directMessage(streamId)? where streamId == openDirectMessageStream?.id:
            // Suppress displaying notifications for a direct message the user is currently viewing
            return completionHandler([])
            
        default:
            // Allow all other notifications to be displayed in-app
            // We do not currently support application icon badgeing
            return completionHandler([.alert, .sound])
        }
    }
}
