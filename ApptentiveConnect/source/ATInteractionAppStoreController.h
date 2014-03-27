//
//  ATInteractionAppStoreController.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 3/26/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class ATInteraction;

@interface ATInteractionAppStoreController : NSObject

@property (nonatomic, retain, readonly) ATInteraction *interaction;
@property (nonatomic, retain) UIViewController *viewController;

@end
