//
//  BannerViewController.h
//  TestBanner
//
//  Created by Frank Schmitt on 6/17/15.
//  Copyright (c) 2015 Apptentive. All rights reserved.
//

#import "ATNetworkImageView.h"

@protocol ATBannerViewControllerDelegate;

@interface ATBannerViewController : UIViewController <ATNetworkImageViewDelegate>

@property (weak, nonatomic) id<ATBannerViewControllerDelegate> delegate;
@property (assign, nonatomic) BOOL hasIcon;

+ (void)showWithImageURL:(NSURL *)imageURL title:(NSString *)title message:(NSString *)message backgroundColor:(UIColor *)backgroundColor delegate:(id<ATBannerViewControllerDelegate>)delegate;

@end

@protocol ATBannerViewControllerDelegate <NSObject>

- (void)userDidTapBanner:(ATBannerViewController *)banner;

@end
