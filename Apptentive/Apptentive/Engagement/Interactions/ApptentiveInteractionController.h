//
//  ApptentiveInteractionController.h
//  Apptentive
//
//  Created by Frank Schmitt on 7/18/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ApptentiveInteraction;


@interface ApptentiveInteractionController : NSObject

+ (void)registerInteractionControllerClass:(Class) class forType:(NSString *)type;
+ (instancetype)interactionControllerWithInteraction:(ApptentiveInteraction *)interaction;

- (instancetype)initWithInteraction:(ApptentiveInteraction *)interaction;

@property (readonly, nonatomic) ApptentiveInteraction *interaction;
@property (strong, nonatomic) UIViewController *presentingViewController;
@property (strong, nullable, nonatomic) UIViewController *presentedViewController;
@property (readonly, nonatomic) NSString *programmaticDismissEventLabel;

- (void)presentInteractionFromViewController:(nullable UIViewController *)viewController NS_REQUIRES_SUPER;
- (void)dismissInteractionNotification:(NSNotification *)notification NS_REQUIRES_SUPER;

@end

NS_ASSUME_NONNULL_END
