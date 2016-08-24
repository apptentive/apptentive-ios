//
//  PictureCell.swift
//  ApptentiveExample
//
//  Created by Frank Schmitt on 8/6/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

import UIKit

class PictureCell: UICollectionViewCell {
	@IBOutlet var imageView: UIImageView!
	@IBOutlet var likesLabel: UILabel!
	@IBOutlet var likeButton: UIButton!
	
	override func awakeFromNib() {
		self.layer.shadowColor = UIColor.lightGray.cgColor
	}
}
