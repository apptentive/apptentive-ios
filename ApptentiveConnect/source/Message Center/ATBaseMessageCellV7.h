//
//  ATBaseMessageCellV7.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/27/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ATMessageCellV7CachingDelegate;

@interface ATBaseMessageCellV7 : UICollectionViewCell
@property (nonatomic, retain) IBOutlet UILabel *dateLabel;
- (void)setCachingDelegate:(NSObject<ATMessageCellV7CachingDelegate> *)cachingDelegate andIndexPath:(NSIndexPath *)indexPath;
@end


@protocol ATMessageCellV7CachingDelegate <NSObject>
- (void)messageCell:(ATBaseMessageCellV7 *)cell preparingForReuseAtPath:(NSIndexPath *)path;
@end
