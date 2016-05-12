//
//  ConnectionViewController.swift
//  iOS Demo
//
//  Created by Frank Schmitt on 4/28/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

import UIKit
import MobileCoreServices

class ConnectionViewController: UITableViewController {
	@IBOutlet var APIKeyLabel: UILabel!
	@IBOutlet var conversationTokenLabel: UILabel!
	@IBOutlet var baseURLLabel: UILabel!
	@IBOutlet var appVersionLabel: UILabel!
	@IBOutlet var appBuildLabel: UILabel!
	@IBOutlet var SDKVersionLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

		if let appVersion = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String {
			appVersionLabel.text = appVersion
		}

		if let appBuild = NSBundle.mainBundle().infoDictionary?["CFBundleVersion"] as? String {
			appBuildLabel.text = appBuild
		}

		SDKVersionLabel.text = kApptentiveVersionString

		refresh()

		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(refresh), name: ApptentiveConversationCreatedNotification, object: nil)
	}

	override func tableView(tableView: UITableView, shouldShowMenuForRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		return true
	}

	override func tableView(tableView: UITableView, canPerformAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
		return action == #selector(NSObject.copy(_:))
	}

	override func tableView(tableView: UITableView, performAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
		if action == #selector(NSObject.copy(_:)) {
			if let cell = tableView.cellForRowAtIndexPath(indexPath), let text = cell.detailTextLabel?.text {
				UIPasteboard.generalPasteboard().setValue(text, forPasteboardType: kUTTypeUTF8PlainText as String)
			}
		}
	}

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

	@objc private func refresh() {
		APIKeyLabel.text = Apptentive.sharedConnection().APIKey
		conversationTokenLabel.text = Apptentive.sharedConnection().conversationToken
		baseURLLabel.text = Apptentive.sharedConnection().baseURL?.absoluteString
	}
}
