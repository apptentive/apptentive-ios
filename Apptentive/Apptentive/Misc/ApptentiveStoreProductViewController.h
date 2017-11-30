//
//  ApptentiveStoreProductViewController.h
//  Apptentive
//
//  Created by Alex Lementuev on 8/31/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveStoreProductViewController : SKStoreProductViewController

- (void)presentAnimated:(BOOL)animated completion:(void (^__nullable)(void))completion;

@end

NS_ASSUME_NONNULL_END
