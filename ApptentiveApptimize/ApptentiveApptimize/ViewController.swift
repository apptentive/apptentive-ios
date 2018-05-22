//
//  ViewController.swift
//  ApptentiveApptimize
//
//  Created by Alex Lementuev on 5/8/18.
//  Copyright © 2018 Apptentive. All rights reserved.
//

import UIKit
import Apptentive
import Apptimize

class ViewController: UIViewController {
	
	@IBOutlet weak var infoLabel: UILabel!

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
		updateInfo()
		
		NotificationCenter.default
			.addObserver(self,
						 selector: #selector(experimentParticipation(notification:)),
						 name: NSNotification.Name.ApptimizeTestRun,
						 object: nil)
		
		NotificationCenter.default
			.addObserver(self,
						 selector: #selector(experimentParticipation(notification:)),
						 name: NSNotification.Name.ApptimizeTestsProcessed,
						 object: nil)
	}
	
	@objc func experimentParticipation(notification: NSNotification) {
		updateInfo()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	@IBAction func apptimizeAlternativeButton(_ sender: Any) {
		Apptentive.shared.engage(event: "apptimize_1", from: self)
	}
	
	private func updateInfo() {
		DispatchQueue.main.async {
			if let experiments = Apptimize.testInfo() {
				if let testExperiment = experiments["test_experiment"] {
					self.infoLabel.text = "\(testExperiment.testName())-\(testExperiment.enrolledVariantName())"
				}
			}
		}
	}
	
}

