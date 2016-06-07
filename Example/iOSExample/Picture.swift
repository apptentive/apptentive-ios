//
//  Picture.swift
//  ApptentiveExample
//
//  Created by Frank Schmitt on 8/6/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

import UIKit
import QuickLook
import ImageIO

class Picture: NSObject {
	let URL: NSURL
	let image: UIImage?
	var likeCount: Int
	
	init(URL: NSURL, likeCount: Int) {
		self.URL = URL
		self.likeCount = likeCount
		
		if let imageSource = CGImageSourceCreateWithURL(self.URL, nil) {
			let options = [
				kCGImageSourceThumbnailMaxPixelSize: 600,
				kCGImageSourceCreateThumbnailFromImageIfAbsent: true
			] as [NSObject: AnyObject]
			
			self.image = UIImage(CGImage: CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options)!)
		} else {
			self.image = nil
		}
	}
}

extension Picture: QLPreviewItem {
	var previewItemName: String? {
		get {
			return "\(self.likeCount) Likes"
		}
	}
	var previewItemURL: NSURL {
		get {
			return self.URL
		}
	}
}
