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
		if let picturesFolderPath = Bundle.main.path(forResource: "Pictures", ofType: nil) {
			let enumerator = FileManager.default.enumerator(atPath: picturesFolderPath)
			
			while let element = enumerator?.nextObject() as? String {
				let pictureURL = URL(fileURLWithPath: NSString(string: picturesFolderPath).appendingPathComponent(element as String))
				let randomLikeCount = Int(arc4random_uniform(1000))
				pictures.append(Picture(URL: pictureURL as URL, likeCount: randomLikeCount))
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
	
	fileprivate func assignRandomLikes() {
		self.pictures.forEach { (picture) in
			picture.likeCount =  Int(arc4random_uniform(1000))
		}
	}
	
	fileprivate func indexOfFavorite(_ picture: Picture) -> Int? {
		return self.favoriteDataSource.pictures.index(of: picture)
	}
	
	func isFavorite(_ picture: Picture) -> Bool {
		return self.indexOfFavorite(picture) != nil
	}
	
	func addFavorite(_ picture: Picture) {
		if !self.isFavorite(picture) {
			picture.likeCount += 1
			
			self.favoriteDataSource.pictures.append(picture)
		}
	}
	
	func removeFavorite(_ picture: Picture) {
		if let index = self.indexOfFavorite(picture) {
			picture.likeCount -= 1
			
			self.favoriteDataSource.pictures.remove(at: index)
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
	
	func likeCountAtIndex(_ index: Int) -> Int {
		return self.pictures[index].likeCount
	}
	
	func imageAtIndex(_ index: Int) -> UIImage? {
		return self.pictures[index].image
	}
	
	func imageSizeAtIndex(_ index: Int) -> CGSize {
		return self.imageAtIndex(index)?.size ?? CGSize.zero
	}
	
	func imageNameAtIndex(_ index: Int) -> String {
		return pictures[index].URL.deletingPathExtension().lastPathComponent
	}
	
	func isLikedAtIndex(_ index: Int) -> Bool {
		return self.manager!.isFavorite(pictures[index])
	}
	
	func setLiked(_ index: Int, liked: Bool) {
		if liked && !self.isLikedAtIndex(index) {
			self.manager!.addFavorite(self.pictures[index])
		} else if !liked {
			self.manager!.removeFavorite(self.pictures[index])
		}
	}
}

extension PictureDataSource: QLPreviewControllerDataSource {
	@objc func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
		return self.numberOfPictures()
	}
	
	@objc func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
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
