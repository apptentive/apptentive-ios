//
//  ApptentiveInteractionController.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 7/18/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveInteractionController.h"
#import "ApptentiveInteraction.h"
#import "Apptentive_Private.h"

static NSDictionary *interactionControllerClassRegistry;


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

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissInteraction:) name:ApptentiveInteractionsShouldDismissNotification object:nil];
	}

	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)presentInteractionFromViewController:(UIViewController *)viewController {
	self.presentingViewController = viewController;
}

- (void)dismissInteraction:(NSNotification *)notification {
	BOOL animated = [notification.object boolValue];

	[self.presentingViewController dismissViewControllerAnimated:animated completion:nil];
}

@end
