 //
//  AppDelegate.swift
//  HalfTunes
//
//  Created by Ken Toh on 13/7/15.
//  Copyright (c) 2015 Ken Toh. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  let tintColor =  UIColor(red: 242/255, green: 71/255, blue: 63/255, alpha: 1)
  var backgroundSessionCompletionHandler: (() -> Void)?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    customizeAppearance()
    return true
  }

  func applicationWillResignActive(_ application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }

  func applicationWillEnterForeground(_ application: UIApplication) {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }
  
  // wakes up the app to deal with the completed background task. you need to handle two things in this event
  // 1. the app needs to reconnect to the appropriate background session with the identifier provided by the delegate method. But since you create and use one background session every time you instantiate SearchViewController, you're already reconnected at this point
  // 2. you'll need to capture the completion handler provided by the delegate method. Invoking the completion handler causes the OS to snapshot your updated UI for display in the app switcher, as well as tells the OS that your app's done working with all background activities for the current session.
  func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
    // save the provided completionHandler as a variable in your app delegate for later use
    backgroundSessionCompletionHandler = completionHandler
  }

  // MARK - App Theme Customization
  
  fileprivate func customizeAppearance() {
    window?.tintColor = tintColor
    UISearchBar.appearance().barTintColor = tintColor
    UINavigationBar.appearance().barTintColor = tintColor
    UINavigationBar.appearance().tintColor = UIColor.white
    UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName:UIColor.white]
  }
}

