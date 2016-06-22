//
//  AppDelegate.swift
//  iOS Demo
//
//  Created by Frank Schmitt on 4/26/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

import UIKit

private let APIKeyKey = "APIKey"
private let AppIDKey = "appID"
private let baseURLKey = "baseURL"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow?

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		self.registerDefaults()

		UITabBar.appearance().tintColor = UIColor.apptentiveRed()

		if let APIKey = NSUserDefaults.standardUserDefaults().stringForKey(APIKeyKey) {
			self.connectWithAPIKey(APIKey)
		}

		return true
	}

	func applicationDidBecomeActive(application: UIApplication) {
		if NSUserDefaults.standardUserDefaults().stringForKey(APIKeyKey) == nil {
			if let rootViewController = self.window?.rootViewController  {
				rootViewController.performSegueWithIdentifier("ShowAPI", sender: self)
			}
		}
	}

	func connectWithAPIKey(APIKey: String) {
		let apptentiveBaseURL: NSURL
		if let baseURLString = NSUserDefaults.standardUserDefaults().stringForKey(baseURLKey), baseURL = NSURL(string: baseURLString) {
			apptentiveBaseURL = baseURL
		} else {
			apptentiveBaseURL = NSURL(string: "https://api.apptentive.com")!
		}

		Apptentive.sharedConnection().setAPIKey(APIKey, baseURL: apptentiveBaseURL)
		NSUserDefaults.standardUserDefaults().setObject(APIKey, forKey: APIKeyKey)
	}

	private func registerDefaults() {
		if let defaultDefaultsURL = NSBundle.mainBundle().URLForResource("Defaults", withExtension: "plist"), defaultDefaults = NSDictionary(contentsOfURL:defaultDefaultsURL) as? [String : AnyObject] {
			NSUserDefaults.standardUserDefaults().registerDefaults(defaultDefaults)
		}
	}
}

extension UIColor {
	class func apptentiveRed() -> UIColor {
		return UIColor(red: 237/255, green: 65/255, blue: 76/255, alpha: 1)
	}
}


