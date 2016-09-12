//
//  MoreViewController.swift
//  ApptentiveExample
//
//  Created by Frank Schmitt on 9/14/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

import UIKit
import Apptentive

class MoreViewController: UITableViewController {
	@IBOutlet var messageCenterCell: UITableViewCell!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.messageCenterCell.accessoryView = Apptentive.shared.unreadMessageCountAccessoryView(apptentiveHeart: true)
	}
		
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		Apptentive.shared.presentMessageCenter(from: self)
	}
}
