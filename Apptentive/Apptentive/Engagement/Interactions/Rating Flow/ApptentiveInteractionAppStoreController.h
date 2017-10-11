//
//  ApptentiveInteractionAppStoreController.h
//  Apptentive
//
//  Created by Peter Kamb on 3/26/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveInteractionController.h"
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ApptentiveInteraction;


@interface ApptentiveInteractionAppStoreController : ApptentiveInteractionController <SKStoreProductViewControllerDelegate>
@end

NS_ASSUME_NONNULL_END
