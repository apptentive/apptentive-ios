//
//  BannerViewController.h
//  TestBanner
//
//  Created by Frank Schmitt on 6/17/15.
//  Copyright (c) 2015 Apptentive. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ATBannerViewControllerDelegate;

@interface ATBannerViewController : UIViewController

@property (weak, nonatomic) id<ATBannerViewControllerDelegate> delegate;
@property (assign, nonatomic) BOOL hasIcon;

+ (void)showWithImage:(UIImage *)image title:(NSString *)title message:(NSString *)message delegate:(id<ATBannerViewControllerDelegate>)delegate;

@end

@protocol ATBannerViewControllerDelegate <NSObject>

- (void)userDidTapBanner:(ATBannerViewController *)banner;

@end
