//
//  AppDelegate.swift
//  Trainer
//
//  Created by Deb on 4/10/20.
//  Copyright © 2016 The Inquisitive Introvert. All rights reserved.
//

import UIKit
import GoogleMobileAds
import Firebase

@UIApplicationMain
class AppDelegate: BaseAppDelegate {

    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        if super.application(application, didFinishLaunchingWithOptions: launchOptions) {
            GADMobileAds.sharedInstance().start(completionHandler: nil)
            FirebaseApp.configure()
            return true
        }
        return false
    }

}

