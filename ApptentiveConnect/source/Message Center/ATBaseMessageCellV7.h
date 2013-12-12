//
//  ATBaseMessageCellV7.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/27/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *const ATMessageCollectionDidScroll;
extern NSString *const ATMessageCollectionTopOffsetKey;

@interface ATBaseMessageCellV7 : UICollectionViewCell
@property (nonatomic, retain) IBOutlet UILabel *dateLabel;

/*! Do not call directly. You may override this to perform layout on scrolling. */
- (void)collection:(UICollectionView *)collectionView didScroll:(CGFloat)topOffset;
@end
