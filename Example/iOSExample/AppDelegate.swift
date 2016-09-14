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

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		Apptentive.shared.apiKey = "edbf34735084c94fe345baaa93a408c655132984bde1a8fe75ddd15b79b771a3"

		precondition(Apptentive.shared.apiKey != "<Your Apptentive API Key>", "Please set your Apptentive API key above")

		if let tabBarController = self.window?.rootViewController as? UITabBarController {
			tabBarController.delegate = self
		}

		return true
	}

	// MARK: Tab bar controller delegate
	func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
		if tabBarController.viewControllers?.index(of: viewController) ?? 0 == 0 {
			Apptentive.shared.engage(event: "photos_tab_selected", from: tabBarController)
		} else {
			Apptentive.shared.engage(event: "favorites_tab_selected", from: tabBarController)
		}
	}
}

