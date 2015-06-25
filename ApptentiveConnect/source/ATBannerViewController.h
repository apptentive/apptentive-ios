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
@property (strong, nonatomic) NSURL *imageURL;
@property (strong, nonatomic) NSString *titleText;
@property (strong, nonatomic) NSString *messageText;
@property (strong, nonatomic) UIColor *backgroundColor;
@property (strong, nonatomic) UIColor *textColor;

+ (instancetype)bannerWithImageURL:(NSURL *)imageURL title:(NSString *)title message:(NSString *)message;
- (void)show;

@end

@protocol ATBannerViewControllerDelegate <NSObject>

- (void)userDidTapBanner:(ATBannerViewController *)banner;

@end
