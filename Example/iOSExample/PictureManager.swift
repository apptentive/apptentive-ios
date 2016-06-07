//
//  PictureSource.swift
//  ApptentiveExample
//
//  Created by Frank Schmitt on 8/6/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

import UIKit
import QuickLook

class PictureManager {
	static let sharedManager = PictureManager()
	
	var pictures = [Picture]()
	
	var favoriteDataSource: PictureDataSource
	var pictureDataSource: PictureDataSource
	
	init() {
		if let picturesFolderPath = NSBundle.mainBundle().pathForResource("Pictures", ofType: nil) {
			let enumerator = NSFileManager.defaultManager().enumeratorAtPath(picturesFolderPath)
			
			while let element = enumerator?.nextObject() as? String {
				let pictureURL = NSURL.fileURLWithPath(NSString(string: picturesFolderPath).stringByAppendingPathComponent(element as String))
				let randomLikeCount = Int(arc4random_uniform(1000))
				pictures.append(Picture(URL: pictureURL, likeCount: randomLikeCount))
			}
		}
		
		self.pictureDataSource = PictureDataSource(pictures: self.pictures)
		self.favoriteDataSource = PictureDataSource(pictures: [])
		
		self.pictureDataSource.manager = self
		self.favoriteDataSource.manager = self
	}
	
	func reset() {
		self.favoriteDataSource.pictures = []
		self.assignRandomLikes()
		self.pictureDataSource.pictures = self.pictures.shuffled()
	}
	
	private func assignRandomLikes() {
		self.pictures.forEach { (picture) in
			picture.likeCount =  Int(arc4random_uniform(1000))
		}
	}
	
	private func indexOfFavorite(picture: Picture) -> Int? {
		return self.favoriteDataSource.pictures.indexOf(picture)
	}
	
	func isFavorite(picture: Picture) -> Bool {
		return self.indexOfFavorite(picture) != nil
	}
	
	func addFavorite(picture: Picture) {
		if !self.isFavorite(picture) {
			picture.likeCount += 1
			
			self.favoriteDataSource.pictures.append(picture)
		}
	}
	
	func removeFavorite(picture: Picture) {
		if let index = self.indexOfFavorite(picture) {
			picture.likeCount -= 1
			
			self.favoriteDataSource.pictures.removeAtIndex(index)
		}
	}
}

class PictureDataSource {
	var pictures: [Picture]
	weak var manager: PictureManager?
	
	init(pictures: [Picture]) {
		self.pictures = pictures
	}
	
	func numberOfPictures() -> Int {
		return self.pictures.count
	}
	
	func likeCountAtIndex(index: Int) -> Int {
		return self.pictures[index].likeCount
	}
	
	func imageAtIndex(index: Int) -> UIImage? {
		return self.pictures[index].image
	}
	
	func imageSizeAtIndex(index: Int) -> CGSize {
		return self.imageAtIndex(index)?.size ?? CGSizeZero
	}
	
	func imageNameAtIndex(index: Int) -> String {
		return self.pictures[index].URL.URLByDeletingPathExtension!.lastPathComponent!
	}
	
	func isLikedAtIndex(index: Int) -> Bool {
		return self.manager!.isFavorite(pictures[index])
	}
	
	func setLiked(index: Int, liked: Bool) {
		if liked && !self.isLikedAtIndex(index) {
			self.manager!.addFavorite(self.pictures[index])
		} else if !liked {
			self.manager!.removeFavorite(self.pictures[index])
		}
	}
}

extension PictureDataSource: QLPreviewControllerDataSource {
	@objc func numberOfPreviewItemsInPreviewController(controller: QLPreviewController) -> Int {
		return self.numberOfPictures()
	}
	
	@objc func previewController(controller: QLPreviewController, previewItemAtIndex index: Int) -> QLPreviewItem {
		return self.pictures[index]
	}
}

extension Array {
	func shuffled() -> [Element] {
		if count < 2 {
			return self
		}
		
		var list = self
		for i in 0..<(list.count - 1) {
			let j = Int(arc4random_uniform(UInt32(list.count - i))) + i
			if i != j {
				swap(&list[i], &list[j])
			}
		}
		return list
	}
}
