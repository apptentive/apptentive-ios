//
//  ATAttachmentCell.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 10/23/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ATAttachmentCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *extensionLabel;

+ (CGSize)sizeForScreen:(UIScreen *)screen withMargin:(CGSize)margin;
+ (CGFloat)heightForScreen:(UIScreen *)screen withMargin:(CGSize)margin;

@end
