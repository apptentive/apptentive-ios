//
//  StringViewController.swift
//  ApptentiveDev
//
//  Created by Frank Schmitt on 12/17/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

import UIKit

class StringViewController: UIViewController {
	var string: String? {
		didSet {
			if let string = string where isViewLoaded() {
				self.stringTextField.text = string
			}
 		}
	}

	@IBOutlet var stringTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

		if let string = string {
			self.stringTextField.text = string
		}
    }

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)

		self.stringTextField.becomeFirstResponder()
	}

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "Save" {
			self.string = self.stringTextField.text
		}
    }
}
