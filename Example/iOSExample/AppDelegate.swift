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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		if let configuration = ApptentiveConfiguration(apptentiveKey: "<#Your Apptentive Key#>", apptentiveSignature: "<#Your Apptentive Signature#>") {

			precondition(configuration.apptentiveKey != "<#Your Apptentive Key#>" && configuration.apptentiveSignature != "<#Your Apptentive Signature#>", "Please set your Apptentive key and signature above")

			Apptentive.register(with: configuration)
		}

		if let tabBarController = self.window?.rootViewController as? UITabBarController {
			tabBarController.delegate = self
		}

		return true
	}

	// MARK: Tab bar controller delegate
	func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
		if tabBarController.viewControllers?.firstIndex(of: viewController) ?? 0 == 0 {
			Apptentive.shared.engage(event: "photos_tab_selected", from: tabBarController)
		} else {
			Apptentive.shared.engage(event: "favorites_tab_selected", from: tabBarController)
		}
	}
}

