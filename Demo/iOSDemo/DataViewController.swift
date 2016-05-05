//
//  DataViewController.swift
//  iOSDemo
//
//  Created by Frank Schmitt on 4/27/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

import UIKit

class DataViewController: UITableViewController {
	@IBOutlet var modeControl: UISegmentedControl!
	let dataSources = [PersonDataSource(), DeviceDataSource()]

	override func setEditing(editing: Bool, animated: Bool) {
		dataSources.forEach { $0.editing = editing }

		let numberOfRows = self.tableView.numberOfRowsInSection(1)
		var indexPaths = [NSIndexPath]()
		if editing {
			for row in numberOfRows..<(numberOfRows + 3) {
				indexPaths.append(NSIndexPath(forRow: row, inSection: 1))
			}
			self.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Top)
		} else {
			for row in (numberOfRows - 3)..<numberOfRows {
				indexPaths.append(NSIndexPath(forRow: row, inSection: 1))
			}
			self.tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Top)
		}

		super.setEditing(editing, animated: animated)
	}

    override func viewDidLoad() {
        super.viewDidLoad()

		self.navigationItem.titleView = modeControl

		self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)

		updateMode(modeControl)
	}

	override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
		if indexPath.section == 1 {
			if indexPath.row >= tableView.numberOfRowsInSection(1) - 3 {
				return .Insert
			} else {
				return .Delete
			}
		}

		return .None
	}

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if let dataSource = tableView.dataSource as? DataSource where dataSource == dataSources[0] && indexPath.section == 0 && self.editing {
			if let navigationController = self.storyboard?.instantiateViewControllerWithIdentifier("NameEmailNavigation") as? UINavigationController, let stringViewController = navigationController.viewControllers.first as? StringViewController {
				stringViewController.title = indexPath.row == 0 ? "Edit Name" : "Edit Email"
				stringViewController.string = indexPath.row == 0 ? Apptentive.sharedConnection().personName : Apptentive.sharedConnection().personEmailAddress
				self.presentViewController(navigationController, animated: true, completion: nil)
			}
		}
	}

	@IBAction func updateMode(sender: UISegmentedControl) {
		let dataSource = dataSources[sender.selectedSegmentIndex]

		dataSource.refresh()
		self.tableView.dataSource = dataSource;
		self.tableView.reloadData()
	}

	@IBAction func returnToDataList(sender: UIStoryboardSegue) {
		if let value = (sender.sourceViewController as? StringViewController)?.string {
			if let selectedIndex = self.tableView.indexPathForSelectedRow?.row {
				if selectedIndex == 0 {
					Apptentive.sharedConnection().personName = value
				} else {
					Apptentive.sharedConnection().personEmailAddress = value
				}
			}

			tableView.reloadSections(NSIndexSet(index:0), withRowAnimation: .Automatic)
		}
	}

	func addCustomData(index: Int) {
		print("Adding type with index \(index)")
	}
}

class DataSource: NSObject, UITableViewDataSource {
	var editing = false

	override init() {
		super.init()
		self.refresh()
	}

	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 2
	}

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 0
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		return tableView.dequeueReusableCellWithIdentifier("Datum", forIndexPath: indexPath)
	}

	func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if section == 0 {
			return "Standard Data"
		} else {
			return "Custom Data"
		}
	}

	func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		return indexPath.section == 1
	}

	func refresh() {
	}

	// TODO: convert to enum?
	func labelForAdding(index: Int) -> String {
		switch index {
		case 0:
			return "Add String"
		case 1:
			return "Add Number"
		default:
			return "Add Boolean"
		}
	}

	func reuseIdentifierForAdding(index: Int) -> String {
		switch index {
		case 0:
			return "String"
		case 1:
			return "Number"
		default:
			return "Boolean"
		}
	}
}

class PersonDataSource: DataSource {
	var customKeys = [String]()
	var customData = [String : NSObject]()

	override func refresh() {
		if let customData = (Apptentive.sharedConnection().customPersonData as NSDictionary) as? [String : NSObject] {
			self.customData = customData
			self.customKeys = customData.keys.sort { $0 < $1 }
		}
	}

	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if section == 0 {
			return 2
		} else {
			return self.customKeys.count + (self.editing ? 3 : 0)
		}
	}

	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell: UITableViewCell

		if indexPath.section == 0 || indexPath.row < self.customKeys.count {
			cell = tableView.dequeueReusableCellWithIdentifier("Datum", forIndexPath: indexPath)
			let key: String
			let value: String?

			if indexPath.section == 0 {
				if indexPath.row == 0 {
					key = "Name"
					value = Apptentive.sharedConnection().personName
				} else  {
					key = "Email"
					value = Apptentive.sharedConnection().personEmailAddress
				}
			} else {
				key = self.customKeys[indexPath.row]
				value = self.customData[key]?.description
			}

			cell.textLabel?.text = key
			cell.detailTextLabel?.text = value
		} else {
			cell = tableView.dequeueReusableCellWithIdentifier(self.reuseIdentifierForAdding(indexPath.row - self.customKeys.count), forIndexPath: indexPath)
		}

		return cell
	}

	func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
		if indexPath.section == 0 {
			return
		} else if editingStyle == .Delete {
			Apptentive.sharedConnection().removeCustomPersonDataWithKey(self.customKeys[indexPath.row])
			self.refresh()
			tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
		} else if editingStyle == .Insert {
			if let cell = tableView.cellForRowAtIndexPath(indexPath) as? CustomDataCell, let key = cell.keyField.text {
				switch self.reuseIdentifierForAdding(indexPath.row - self.customKeys.count) {
				case "String":
					if let textField = cell.valueControl as? UITextField, string = textField.text {
						Apptentive.sharedConnection().addCustomPersonDataString(string, withKey: key)
						textField.text = nil
					}
				case "Number":
					if let textField = cell.valueControl as? UITextField, numberString = textField.text, number = NSNumberFormatter().numberFromString(numberString) {
						Apptentive.sharedConnection().addCustomPersonDataNumber(number, withKey: key)
						textField.text = nil
					}
				case "Boolean":
					if let switchControl = cell.valueControl as? UISwitch {
						Apptentive.sharedConnection().addCustomPersonDataBool(switchControl.on, withKey: key)
						switchControl.on = true
					}
				default:
					break;
				}
				tableView.deselectRowAtIndexPath(indexPath, animated: true)
				self.refresh()
				tableView.reloadSections(NSIndexSet(index:1), withRowAnimation: .Automatic)
				cell.keyField.text = nil
			}
		}
	}
}

class DeviceDataSource: DataSource {
	var deviceKeys = [String]()
	var deviceData = [String : AnyObject]()

	var customDeviceKeys = [String]()
	var customDeviceData = [String : NSObject]()

	override func refresh() {
		self.deviceData = Apptentive.sharedConnection().deviceInfo
		self.deviceKeys = self.deviceData.keys.sort { $0 < $1 }

		if let customDataKeyIndex = self.deviceKeys.indexOf("custom_data") {
			self.deviceKeys.removeAtIndex(customDataKeyIndex)
		}

		if let customDeviceData = (Apptentive.sharedConnection().customDeviceData as NSDictionary) as? [String : NSObject] {
			self.customDeviceData = customDeviceData
			self.customDeviceKeys = customDeviceData.keys.sort { $0 < $1 }
		}
	}

	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if section == 0 {
			return self.deviceKeys.count
		} else {
			return self.customDeviceKeys.count + (self.editing ? 3 : 0)
		}
	}

	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell: UITableViewCell

		if indexPath.section == 0 || indexPath.row < self.customDeviceKeys.count {
			cell = tableView.dequeueReusableCellWithIdentifier("Datum", forIndexPath: indexPath)
			let key: String
			let value: String?

			if indexPath.section == 0 {
				key = self.deviceKeys[indexPath.row]
				value = self.deviceData[key]?.description
			} else {
				key = self.customDeviceKeys[indexPath.row]
				value = self.customDeviceData[key]?.description
			}

			cell.textLabel?.text = key
			cell.detailTextLabel?.text = value
			cell.selectionStyle = indexPath.section == 0 ? .None : .Default
		} else {
			cell = tableView.dequeueReusableCellWithIdentifier(self.reuseIdentifierForAdding(indexPath.row - self.customDeviceKeys.count), forIndexPath: indexPath)
		}

		return cell
	}

	func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
		if indexPath.section == 0 {
			return
		} else if editingStyle == .Delete {
			Apptentive.sharedConnection().removeCustomDeviceDataWithKey(self.customDeviceKeys[indexPath.row])
			self.refresh()
			tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
		} else if editingStyle == .Insert {
			if let cell = tableView.cellForRowAtIndexPath(indexPath) as? CustomDataCell, let key = cell.keyField.text {
				switch self.reuseIdentifierForAdding(indexPath.row - self.customDeviceKeys.count) {
				case "String":
					if let textField = cell.valueControl as? UITextField, string = textField.text {
						Apptentive.sharedConnection().addCustomDeviceDataString(string, withKey: key)
						textField.text = nil
					}
				case "Number":
					if let textField = cell.valueControl as? UITextField, numberString = textField.text, number = NSNumberFormatter().numberFromString(numberString) {
						Apptentive.sharedConnection().addCustomDeviceDataNumber(number, withKey: key)
						textField.text = nil
					}
				case "Boolean":
					if let switchControl = cell.valueControl as? UISwitch {
						Apptentive.sharedConnection().addCustomDeviceDataBool(switchControl.on, withKey: key)
						switchControl.on = true
					}
				default:
					break;
				}
				tableView.deselectRowAtIndexPath(indexPath, animated: true)
				self.refresh()
				tableView.reloadSections(NSIndexSet(index:1), withRowAnimation: .Automatic)
				cell.keyField.text = nil
			}
		}
	}
}
