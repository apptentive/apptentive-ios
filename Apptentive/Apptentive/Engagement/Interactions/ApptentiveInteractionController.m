//
//  ApptentiveInteractionController.m
//  Apptentive
//
//  Created by Frank Schmitt on 7/18/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveInteractionController.h"
#import "ApptentiveInteraction.h"
#import "Apptentive_Private.h"
#import "ApptentiveBackend+Engagement.h"

NS_ASSUME_NONNULL_BEGIN


static NSDictionary *interactionControllerClassRegistry;
static NSString *const ApptentiveInteractionEventLabelCancel = @"cancel";


@implementation ApptentiveInteractionController

+ (void)registerInteractionControllerClass:(Class) class forType:(NSString *)type {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
	  interactionControllerClassRegistry = @{};
	});

	@synchronized([ApptentiveInteractionController class]) {
		NSMutableDictionary *registry = [interactionControllerClassRegistry mutableCopy];
		registry[type] = class;
		interactionControllerClassRegistry = [NSDictionary dictionaryWithDictionary:registry];
	}
}

	+ (Class)interactionControllerClassWithType : (NSString *)type {
	Class result;
	@synchronized([ApptentiveInteractionController class]) {
		result = interactionControllerClassRegistry[type];
	}
	return result;
}

+ (instancetype)interactionControllerWithInteraction:(ApptentiveInteraction *)interaction {
	Class controllerClass = [self interactionControllerClassWithType:interaction.type] ?: [self class];

	return [[controllerClass alloc] initWithInteraction:interaction];
}

- (instancetype)initWithInteraction:(ApptentiveInteraction *)interaction {
	self = [super init];

	if (self) {
		_interaction = interaction;

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissInteractionNotification:) name:ApptentiveInteractionsShouldDismissNotification object:nil];
	}

	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)presentInteractionFromViewController:(nullable UIViewController *)viewController {
	ApptentiveAssertMainQueue
	self.presentingViewController = viewController;
}

- (void)dismissInteractionNotification:(NSNotification *)notification {
	BOOL animated = [notification.userInfo[ApptentiveInteractionsShouldDismissAnimatedKey] boolValue];

	[self.presentedViewController dismissViewControllerAnimated:animated completion:nil];

	// Ordinarily we would engage in the completion block of the -dismiss method, but that screws up event ordering during logout.
	[Apptentive.shared.backend engage:self.programmaticDismissEventLabel fromInteraction:self.interaction fromViewController:nil userInfo:@{ @"cause": @"notification" }];

	self.presentedViewController = nil;
}

- (NSString *)programmaticDismissEventLabel {
	return ApptentiveInteractionEventLabelCancel;
}

@end

NS_ASSUME_NONNULL_END
