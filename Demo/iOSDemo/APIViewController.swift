//
//  APIViewController.swift
//  iOS Demo
//
//  Created by Frank Schmitt on 4/27/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

import UIKit

class APIViewController: UITableViewController {
	@IBOutlet var saveButtonItem: UIBarButtonItem!
	@IBOutlet var APIKeyField: UITextField!

	@IBAction func openDashboard() {
		UIApplication.sharedApplication().openURL(NSURL(string: "https://be.apptentive.com/apps/current/settings/api")!)
	}

	@IBAction func APIKeyChanged(sender: UITextField) {
		var result = false

		if let text = sender.text where text.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) == 64 && text.rangeOfCharacterFromSet(NSCharacterSet(charactersInString: "abcdef0123456789").invertedSet) == nil {
					result = true
		}

		self.saveButtonItem.enabled = result
	}

	@IBAction func save() {
		if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
			appDelegate.connectWithAPIKey(APIKeyField.text!)
		}
		dismissViewControllerAnimated(true, completion: nil)
	}
}
