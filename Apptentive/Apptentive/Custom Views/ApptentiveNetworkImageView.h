//
//  ApptentiveNetworkImageView.h
//  Apptentive
//
//  Created by Andrew Wooster on 4/17/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ApptentiveNetworkImageViewDelegate;


@interface ApptentiveNetworkImageView : UIImageView <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
@property (copy, nonatomic) NSURL *imageURL;
@property (weak, nonatomic) id<ApptentiveNetworkImageViewDelegate> delegate;
@end

@protocol ApptentiveNetworkImageViewDelegate <NSObject>

- (void)networkImageViewDidLoad:(ApptentiveNetworkImageView *)imageView;
- (void)networkImageView:(ApptentiveNetworkImageView *)imageView didFailWithError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
