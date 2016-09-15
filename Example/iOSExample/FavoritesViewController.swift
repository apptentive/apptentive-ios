//
//  FavoritesViewController.swift
//  ApptentiveExample
//
//  Created by Frank Schmitt on 8/6/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

import UIKit
import Apptentive

class FavoritesViewController: PicturesViewController {
    @IBOutlet var noFavoritesLabel: UILabel!
	override func viewDidLoad() {
		super.viewDidLoad()

		minimumWidth = 120
		
		self.collectionView!.backgroundView = self.noFavoritesLabel
	}
	
	override func configure() {
		self.source = manager.favoriteDataSource
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		updateEmpty(animated)
	}
	
	fileprivate func updateEmpty(_ animated: Bool) {
		let alpha: CGFloat = self.source.numberOfPictures() == 0 ? 1.0 : 0.0
		let duration = animated ? 0.1 : 0.0
		
		UIView.animate(withDuration: duration) { () -> Void in
			self.noFavoritesLabel.alpha = alpha
		}
	}

	@IBAction override func toggleLike(_ sender: UIButton) {
		if let cell = sender.superview?.superview as? UICollectionViewCell {
			if let indexPath = self.collectionView?.indexPath(for: cell) {
				// Will always mean "unlike" in favorites-only view
				sender.isSelected = false

				Apptentive.shared.engage(event: "photo_unliked", withCustomData: ["photo_name": self.source.imageNameAtIndex(indexPath.item)], from: self)

				self.source?.setLiked((indexPath as NSIndexPath).item, liked: false)

				self.collectionView!.deleteItems(at: [indexPath])
				self.updateEmpty(true)				
			}
		}
	}
}
