//
//  EventsViewController.swift
//  iOSDemo
//
//  Created by Frank Schmitt on 4/27/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

import UIKit

private let EventsKey = "events"

class EventsViewController: UITableViewController {
	private var events = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItem = self.editButtonItem()

		updateEventList()

		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(EventsViewController.updateEventList), name: NSUserDefaultsDidChangeNotification, object: nil)
    }

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Event", forIndexPath: indexPath)

		cell.textLabel?.text = events[indexPath.row]

        return cell
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
			events.removeAtIndex(indexPath.row)
			saveEventList()
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }

	// MARK: Table view delegate

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if self.editing {
			if let navigationController = self.storyboard?.instantiateViewControllerWithIdentifier("StringNavigation") as? UINavigationController, let eventViewController = navigationController.viewControllers.first as? StringViewController {
				eventViewController.string = self.events[indexPath.row]
				eventViewController.title = "Edit Event"
				self.presentViewController(navigationController, animated: true, completion: nil)
			}
		} else {
			Apptentive.sharedConnection().engage(events[indexPath.row], fromViewController: self)
			tableView.deselectRowAtIndexPath(indexPath, animated: true)
		}
	}

	// MARK: - Segues

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if let navigationController = segue.destinationViewController as? UINavigationController, let eventViewController = navigationController.viewControllers.first {
			eventViewController.title = "New Event"
		}
	}

	@IBAction func returnToEventList(sender: UIStoryboardSegue) {
		if let name = (sender.sourceViewController as? StringViewController)?.string	{
			if let selectedIndex = self.tableView.indexPathForSelectedRow?.row {
				events[selectedIndex] = name
			} else {
				events.append(name)
			}

			events.sortInPlace()
			saveEventList()
			tableView.reloadSections(NSIndexSet(index:0), withRowAnimation: .Automatic)
		}
	}

	// MARK: - Private

	@objc private func updateEventList() {
		if let events = NSUserDefaults.standardUserDefaults().arrayForKey(EventsKey) as? [String] {
			self.events = events
		}
	}

	private func saveEventList() {
		NSUserDefaults.standardUserDefaults().setObject(events, forKey: EventsKey)
	}
	
}
