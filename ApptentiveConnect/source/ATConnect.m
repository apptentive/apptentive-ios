//
//  ATConnect.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/12/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ATConnect.h"
#import "ATBackend.h"
#import "ATContactStorage.h"
#import "ATFeedback.h"
#import "ATUtilities.h"
#if TARGET_OS_IPHONE
#import "ATFeedbackController.h"
#import "ATMessageCenterViewController.h"
#elif TARGET_OS_MAC
#import "ATFeedbackWindowController.h"
#endif

NSString *const ATMessageCenterUnreadCountChangedNotification = @"ATMessageCenterUnreadCountChangedNotification";

@implementation ATConnect
#if TARGET_OS_IPHONE
{
	ATFeedbackController *currentFeedbackController;
}
#endif
@synthesize apiKey, showTagline, showEmailField, initialUserName, initialUserEmailAddress, customPlaceholderText;

+ (ATConnect *)sharedConnection {
	static ATConnect *sharedConnection = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedConnection = [[ATConnect alloc] init];
	});
	return sharedConnection;
}

- (id)init {
	if ((self = [super init])) {
		self.showEmailField = YES;
		self.showTagline = YES;
		customData = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)dealloc {
#if TARGET_OS_IPHONE
	if (currentFeedbackController) {
		[currentFeedbackController release];
		currentFeedbackController = nil;
	}
#elif IF_TARGET_OS_MAC
	if (feedbackWindowController) {
		[feedbackWindowController release];
		feedbackWindowController = nil;
	}
#endif
	[customData release], customData = nil;
	[customPlaceholderText release], customPlaceholderText = nil;
	[apiKey release], apiKey = nil;
	[initialUserName release], initialUserName = nil;
	[initialUserEmailAddress release], initialUserEmailAddress = nil;
	[super dealloc];
}

- (void)setApiKey:(NSString *)anAPIKey {
	if (apiKey != anAPIKey) {
		[apiKey release];
		apiKey = nil;
		apiKey = [anAPIKey retain];
		[[ATBackend sharedBackend] setApiKey:self.apiKey];
	}
}

- (NSDictionary *)customData {
	return customData;
}

- (void)addCustomData:(NSObject *)object withKey:(NSString *)key {
	if ([object isKindOfClass:[NSDate class]]) {
		[customData setObject:[ATUtilities stringRepresentationOfDate:(NSDate *)object] forKey:key];
	} else {
		[customData setObject:object forKey:key];
	}
}

- (void)removeCustomDataWithKey:(NSString *)key {
	[customData removeObjectForKey:key];
}

#if TARGET_OS_IPHONE
- (void)presentFeedbackControllerFromViewController:(UIViewController *)viewController {
	@synchronized(self) {
		if (currentFeedbackController) {
			ATLogInfo(@"Apptentive feedback controller already shown.");
			return;
		}

		if (![[ATBackend sharedBackend] currentFeedback]) {
			ATFeedback *feedback = [[ATFeedback alloc] init];
			if (customData && [customData count]) {
				[feedback addExtraDataFromDictionary:customData];
			}
			if (self.initialUserName && [self.initialUserName length] > 0) {
				feedback.name = self.initialUserName;
			}
			if (self.initialUserEmailAddress && [self.initialUserEmailAddress length] > 0) {
				feedback.email = self.initialUserEmailAddress;
			}
			ATContactStorage *contact = [ATContactStorage sharedContactStorage];
			if (contact.name && [contact.name length] > 0) {
				feedback.name = contact.name;
			}
			if (contact.phone) {
				feedback.phone = contact.phone;
			}
			if (contact.email && [contact.email length] > 0) {
				feedback.email = contact.email;
			}
			[[ATBackend sharedBackend] setCurrentFeedback:feedback];
			[feedback release];
			feedback = nil;
		}
		if ([[ATBackend sharedBackend] currentFeedback]) {
			ATFeedback *currentFeedback = [[ATBackend sharedBackend] currentFeedback];
			if (![currentFeedback hasScreenshot]) {
				[currentFeedback setScreenshot:nil];
			}
		}

		ATFeedbackController *vc = [[ATFeedbackController alloc] init];
		[vc setShowEmailAddressField:self.showEmailField];
		if (self.customPlaceholderText) {
			[vc setCustomPlaceholderText:self.customPlaceholderText];
		}
		[vc setFeedback:[[ATBackend sharedBackend] currentFeedback]];

		[vc presentFromViewController:viewController animated:YES];
		currentFeedbackController = vc;
	}
}


- (void)dismissFeedbackControllerAnimated:(BOOL)animated completion:(void (^)(void))completion {
	[currentFeedbackController dismissAnimated:animated completion:completion];
}


- (void)feedbackControllerDidDismiss {
	@synchronized(self) {
		[currentFeedbackController release], currentFeedbackController = nil;
	}
}

- (void)presentMessageCenterFromViewController:(UIViewController *)viewController {
	[[ATBackend sharedBackend] presentMessageCenterFromViewController:viewController];
}

- (void)presentIntroDialogFromViewController:(UIViewController *)viewController {
	[[ATBackend sharedBackend] presentIntroDialogFromViewController:viewController];
}

- (void)dismissMessageCenterAnimated:(BOOL)animated completion:(void (^)(void))completion {
	[[ATBackend sharedBackend] dismissMessageCenterAnimated:animated completion:completion];
}

- (NSUInteger)unreadMessageCount {
	return [[ATBackend sharedBackend] unreadMessageCount];
}

#elif TARGET_OS_MAC
- (IBAction)showFeedbackWindow:(id)sender {
	if (![[ATBackend sharedBackend] currentFeedback]) {
		ATFeedback *feedback = [[ATFeedback alloc] init];
		if (additionalFeedbackData && [additionalFeedbackData count]) {
			[feedback addExtraDataFromDictionary:additionalFeedbackData];
		}
		if (self.initialName && [self.initialName length] > 0) {
			feedback.name = self.initialName;
		}
		if (self.initialEmailAddress && [self.initialEmailAddress length] > 0) {
			feedback.email = self.initialEmailAddress;
		}
		[[ATBackend sharedBackend] setCurrentFeedback:feedback];
		[feedback release];
		feedback = nil;
	}
	
	if (!feedbackWindowController) {
		feedbackWindowController = [[ATFeedbackWindowController alloc] initWithFeedback:[[ATBackend sharedBackend] currentFeedback]];
	}
	[feedbackWindowController showWindow:self];
}
#endif

+ (NSBundle *)resourceBundle {
#if TARGET_OS_IPHONE
	NSString *path = [[NSBundle mainBundle] bundlePath];
	NSString *bundlePath = [path stringByAppendingPathComponent:@"ApptentiveResources.bundle"];
	NSFileManager *fm = [NSFileManager defaultManager];
	if ([fm fileExistsAtPath:bundlePath]) {
		NSBundle *bundle = [[NSBundle alloc] initWithPath:bundlePath];
		return [bundle autorelease];
	} else {
		// Try trigger.io path.
		bundlePath = [path stringByAppendingPathComponent:@"plugin.bundle"];
		bundlePath = [bundlePath stringByAppendingPathComponent:@"ApptentiveResources.bundle"];
		if ([fm fileExistsAtPath:bundlePath]) {
			NSBundle *bundle = [[NSBundle alloc] initWithPath:bundlePath];
			return [bundle autorelease];
		} else {
			return nil;
		}
	}
#elif TARGET_OS_MAC
	NSBundle *bundle = [NSBundle bundleForClass:[ATConnect class]];
	return bundle;
#endif
}
@end

NSString *ATLocalizedString(NSString *key, NSString *comment) {
	static NSBundle *bundle = nil;
	if (!bundle) {
		bundle = [[ATConnect resourceBundle] retain];
	}
	NSString *result = [bundle localizedStringForKey:key value:key table:nil];
	return result;
}
