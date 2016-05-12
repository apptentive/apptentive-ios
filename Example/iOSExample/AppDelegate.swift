//
//  AppDelegate.swift
//  ApptentiveExample
//
//  Created by Frank Schmitt on 8/6/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

import UIKit
import Apptentive

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UITabBarControllerDelegate {

	var window: UIWindow?

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		Apptentive.sharedConnection().APIKey = "<Your Apptentive API Key>"

		precondition(Apptentive.sharedConnection().APIKey != "<Your Apptentive API Key>", "Please set your Apptentive API key above")

		if let tabBarController = self.window?.rootViewController as? UITabBarController {
			tabBarController.delegate = self
		}
		
		return true
	}

	// MARK: Tab bar controller delegate
	func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
		if tabBarController.viewControllers?.indexOf(viewController) ?? 0 == 0 {
			Apptentive.sharedConnection().engage("photos_tab_selected", fromViewController: tabBarController)
		} else {
			Apptentive.sharedConnection().engage("favorites_tab_selected", fromViewController: tabBarController)
		}
	}
}

