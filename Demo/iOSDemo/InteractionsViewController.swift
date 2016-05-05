//
//  InteractionsViewController.swift
//  iOSDemo
//
//  Created by Frank Schmitt on 4/27/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

import UIKit

class InteractionsViewController: UITableViewController {
	@IBOutlet var exportButtonItem: UIBarButtonItem!
	var interactionCount = 0
	var interactionNames = [String]()
	var interactionTypes = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()

		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateInteractionList), name: ApptentiveInteractionsDidUpdateNotification, object: nil)
    }

	deinit	 {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

	@IBAction func export(sender: AnyObject) {
		if let JSON = Apptentive.sharedConnection().manifestJSON {
			let activityViewController = UIActivityViewController(activityItems: [JSON], applicationActivities: nil)
			self.presentViewController(activityViewController, animated: true, completion: nil)
		} else {
			let title = "Manifest JSON Not Available"
			let message = "This could be because interactions haven't downloaded yet on this launch, or because the app is not running in the Debug build configuration."

			if #available(iOS 8.0, *) {
				let alertController = UIAlertController(title: title , message: message, preferredStyle: .Alert)
				alertController.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))

				self.presentViewController(alertController, animated: true, completion: nil)
			} else {
				UIAlertView(title: title, message: message, delegate: nil, cancelButtonTitle: "OK").show()
			}
		}
	}

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Apptentive.sharedConnection().engagementInteractions().count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Interaction", forIndexPath: indexPath)

        cell.textLabel?.text = Apptentive.sharedConnection().engagementInteractionNameAtIndex(indexPath.row)
		cell.detailTextLabel?.text = Apptentive.sharedConnection().engagementInteractionTypeAtIndex(indexPath.row)

        return cell
    }

	// MARK: Table view delegate

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		Apptentive.sharedConnection().presentInteractionAtIndex(indexPath.row, fromViewController: self)
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
	}

	// MARK: - Private

	@objc private func updateInteractionList() {
		self.exportButtonItem.enabled = true
		tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
	}
}
