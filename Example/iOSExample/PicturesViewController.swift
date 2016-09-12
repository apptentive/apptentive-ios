//
//  PicturesViewController.swift
//  ApptentiveExample
//
//  Created by Frank Schmitt on 8/6/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

import UIKit
import QuickLook
import Apptentive

class PicturesViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
	let reuseIdentifier = "Picture"
	var manager: PictureManager! {
		didSet {
			self.configure()
		}
	}
	
	var source: PictureDataSource!
	var minimumWidth: CGFloat = 300

    override func viewDidLoad() {
        super.viewDidLoad()

		manager = PictureManager.sharedManager
	}

	func configure() {
		self.source = manager.pictureDataSource
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.collectionView?.reloadData()
	}
	
	override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
		self.collectionViewLayout.invalidateLayout()
	}

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
	}

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.source.numberOfPictures() 
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PictureCell
		
		cell.imageView.image = self.source.imageAtIndex((indexPath as NSIndexPath).item)
		cell.likesLabel.text = "\(self.source.likeCountAtIndex((indexPath as NSIndexPath).item)) Likes"
		cell.likeButton.tag = (indexPath as NSIndexPath).item
		cell.likeButton.isSelected = self.source.isLikedAtIndex((indexPath as NSIndexPath).item) 
		
        return cell
    }
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		if (indexPath as NSIndexPath).item > self.source.numberOfPictures() {
			return CGSize.zero;
		}
		
		if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
			let insetWidth = flowLayout.sectionInset.left + flowLayout.sectionInset.right
			
			let effectiveWidth = collectionView.bounds.width - insetWidth
			let spacing = flowLayout.minimumInteritemSpacing
			
			let columns = floor((effectiveWidth + spacing) / (self.minimumWidth + spacing))
			
			let width = ((effectiveWidth + spacing) / columns) - spacing
			let imageSize = self.source.imageSizeAtIndex((indexPath as NSIndexPath).item)
			let factor = imageSize.width / imageSize.height
			let height = width / factor
			
			return CGSize(width: width, height: height + 44)
		}
		
		return CGSize.zero
	}
	
	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let previewController = QLPreviewController()
		previewController.dataSource = self.source
		previewController.hidesBottomBarWhenPushed = true
		previewController.currentPreviewItemIndex = (indexPath as NSIndexPath).item
		
		self.navigationController?.pushViewController(previewController, animated: true)
		
		Apptentive.shared.engage(event: "photo_viewed", withCustomData: ["photo_name": self.source.imageNameAtIndex(indexPath.item)], from: previewController)
	}
	
	@IBAction func toggleLike(_ sender: UIButton) {
		sender.isSelected = !sender.isSelected
		let index = sender.tag
		
		self.source?.setLiked(index, liked: sender.isSelected)
		
		self.collectionView!.reloadItems(at: [IndexPath(item: index, section: 0)])
		
		if (sender.isSelected) {
			Apptentive.shared.engage(event: "photo_liked", withCustomData: ["photo_name": self.source.imageNameAtIndex(index)], from: self)
		} else {
			Apptentive.shared.engage(event: "photo_unliked", withCustomData: ["photo_name": self.source.imageNameAtIndex(index)], from: self)
		}
	}
}

