//
//  AppDelegate.swift
//  DonatosVillage
//
//  Created by Rob Feldmann on 2/3/19.
//  Copyright © 2019 Donatos. All rights reserved.
//

import UIKit
import VillageCore
import VillageCoreUI
import AppCenter
import AppCenterAnalytics
import AppCenterCrashes

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	
	public let launchArguments = LaunchArguments()

    var window: UIWindow?
    var villageContainer = VillageContainer.make()

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return villageContainer.application(application, willFinishLaunchingWithOptions: launchOptions)
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let isUnitTesting = ProcessInfo.processInfo.environment["TESTING"] != nil
        if isUnitTesting {
            // Returning here to not launch application for unit tests
            return true
        }
        
		if !launchArguments.isUITesting {
			MSAppCenter.start("fdf9955b-10a9-4468-bce7-6952461c143c", withServices:[
				MSAnalytics.self,
				MSCrashes.self
			])
		}

        return villageContainer.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        villageContainer.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        villageContainer.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }

}

