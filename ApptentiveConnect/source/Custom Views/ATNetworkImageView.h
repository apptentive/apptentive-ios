//
//  ATNetworkImageView.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 4/17/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ATNetworkImageViewDelegate;


@interface ATNetworkImageView : UIImageView <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
@property (nonatomic, copy) NSURL *imageURL;
@property (nonatomic, assign) BOOL useCache;
@property (weak, nonatomic) id<ATNetworkImageViewDelegate> delegate;
@end

@protocol ATNetworkImageViewDelegate <NSObject>

- (void)networkImageViewDidLoad:(ATNetworkImageView *)imageView;
- (void)networkImageView:(ATNetworkImageView *)imageView didFailWithError:(NSError *)error;

@end
