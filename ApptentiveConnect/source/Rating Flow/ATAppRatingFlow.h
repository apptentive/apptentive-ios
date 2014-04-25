//
//  ATAppRatingFlow.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 7/8/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>
#elif TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
#endif

/*! A workflow for a user either giving feedback on or rating the current
 application. */
@interface ATAppRatingFlow : NSObject { }

@end
