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

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		self.collectionView?.reloadData()
	}
	
	override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
		self.collectionViewLayout.invalidateLayout()
	}

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
	}

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.source.numberOfPictures() ?? 0
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! PictureCell
		
		cell.imageView.image = self.source.imageAtIndex(indexPath.item)
		cell.likesLabel.text = "\(self.source.likeCountAtIndex(indexPath.item)) Likes"
		cell.likeButton.tag = indexPath.item
		cell.likeButton.selected = self.source.isLikedAtIndex(indexPath.item) ?? false
		
        return cell
    }
	
	func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
		if indexPath.item > self.source.numberOfPictures() {
			return CGSizeZero;
		}
		
		if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
			let insetWidth = flowLayout.sectionInset.left + flowLayout.sectionInset.right
			
			let effectiveWidth = collectionView.bounds.width - insetWidth
			let spacing = flowLayout.minimumInteritemSpacing
			
			let columns = floor((effectiveWidth + spacing) / (self.minimumWidth + spacing))
			
			let width = ((effectiveWidth + spacing) / columns) - spacing
			let imageSize = self.source.imageSizeAtIndex(indexPath.item)
			let factor = imageSize.width / imageSize.height
			let height = width / factor
			
			return CGSize(width: width, height: height + 44)
		}
		
		return CGSizeZero
	}
	
	override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
		let previewController = QLPreviewController()
		previewController.dataSource = self.source
		previewController.hidesBottomBarWhenPushed = true
		previewController.currentPreviewItemIndex = indexPath.item
		
		self.navigationController?.pushViewController(previewController, animated: true)
		
		Apptentive.sharedConnection().engage("photo_viewed", withCustomData: ["photo_name": self.source.imageNameAtIndex(indexPath.item)], fromViewController: previewController)
	}
	
	@IBAction func toggleLike(sender: UIButton) {
		sender.selected = !sender.selected
		let index = sender.tag
		
		self.source?.setLiked(index, liked: sender.selected)
		
		self.collectionView!.reloadItemsAtIndexPaths([NSIndexPath(forItem: index, inSection: 0)])
		
		if (sender.selected) {
			Apptentive.sharedConnection().engage("photo_liked", withCustomData: ["photo_name": self.source.imageNameAtIndex(index)], fromViewController: self)
		} else {
			Apptentive.sharedConnection().engage("photo_unliked", withCustomData: ["photo_name": self.source.imageNameAtIndex(index)], fromViewController: self)
		}
	}
}

