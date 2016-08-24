//
//  Picture.swift
//  ApptentiveExample
//
//  Created by Frank Schmitt on 8/6/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

import UIKit
import QuickLook

class Picture: NSObject {
	let URL: Foundation.URL
	var image: UIImage? = nil
	var likeCount: Int
	
	init(URL: Foundation.URL, likeCount: Int) {
		self.URL = URL
		self.likeCount = likeCount
		self.image = UIImage(contentsOfFile: URL.path)
	}
}

extension Picture: QLPreviewItem {
	var previewItemTitle: String? {
		get {
			return "\(self.likeCount) Likes"
		}
	}
	var previewItemURL: Foundation.URL? {
		get {
			return self.URL
		}
	}
}
