//
//  ATConnect.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/12/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ATConnect.h"
#import "ATConnect_Private.h"
#import "ATBackend.h"
#import "ATContactStorage.h"
#import "ATFeedback.h"
#import "ATUtilities.h"
#if TARGET_OS_IPHONE
#import "ATMessageCenterViewController.h"
#elif TARGET_OS_MAC
#import "ATFeedbackWindowController.h"
#endif

NSString *const ATMessageCenterUnreadCountChangedNotification = @"ATMessageCenterUnreadCountChangedNotification";
NSString *const ATInitialUserNameKey = @"ATInitialUserNameKey";
NSString *const ATInitialUserEmailAddressKey = @"ATInitialUserEmailAddressKey";

@implementation ATConnect
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
		customPersonData = [[NSMutableDictionary alloc] init];
		customDeviceData = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)dealloc {
#if TARGET_OS_IPHONE
#elif IF_TARGET_OS_MAC
	if (feedbackWindowController) {
		[feedbackWindowController release];
		feedbackWindowController = nil;
	}
#endif
	[customPersonData release], customPersonData = nil;
	[customDeviceData release], customDeviceData = nil;
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

- (void)setInitialUserName:(NSString *)anInitialUserName {
	if (initialUserName != anInitialUserName) {
		[initialUserName release];
		initialUserName = nil;
		initialUserName = [anInitialUserName retain];
		
		// Set person object's name. Only overwrites previous *initial* names.
		NSString *previousInitialUserName = [[NSUserDefaults standardUserDefaults] objectForKey:ATInitialUserNameKey];
		if ([ATPersonInfo personExists]) {
			ATPersonInfo *person = [ATPersonInfo currentPerson];
			if (!person.name || [person.name isEqualToString:previousInitialUserName]) {
				person.name = initialUserName;
				person.needsUpdate = YES;
				[person saveAsCurrentPerson];
			}
		}
		[[NSUserDefaults standardUserDefaults] setObject:initialUserName forKey:ATInitialUserNameKey];
	}
}

- (void)setInitialUserEmailAddress:(NSString *)anInitialUserEmailAddress {
	if (![ATUtilities emailAddressIsValid:anInitialUserEmailAddress]) {
		ATLogInfo(@"Attempting to set an invalid initial user email address: %@", anInitialUserEmailAddress);
		return;
	}
		
	if (initialUserEmailAddress != anInitialUserEmailAddress) {		
		[initialUserEmailAddress release];
		initialUserEmailAddress = nil;
		initialUserEmailAddress = [anInitialUserEmailAddress retain];
		
		// Set person object's email. Only overwrites previous *initial* emails.
		NSString *previousInitialUserEmailAddress = [[NSUserDefaults standardUserDefaults] objectForKey:ATInitialUserEmailAddressKey];
		if ([ATPersonInfo personExists]) {
			ATPersonInfo *person = [ATPersonInfo currentPerson];
			if (!person.emailAddress || [person.emailAddress isEqualToString:previousInitialUserEmailAddress]) {
				person.emailAddress = initialUserEmailAddress;
				person.needsUpdate = YES;
				[person saveAsCurrentPerson];
			}			
		}
		[[NSUserDefaults standardUserDefaults] setObject:initialUserEmailAddress forKey:ATInitialUserEmailAddressKey];
	}
}

- (NSDictionary *)customPersonData {
	return customPersonData;
}

- (NSDictionary *)customDeviceData {
	return customDeviceData;
}

- (void)addCustomPersonData:(NSObject *)object withKey:(NSString *)key {
	[self addCustomData:object withKey:key toCustomDataDictionary:customPersonData];
}

- (void)addCustomDeviceData:(NSObject *)object withKey:(NSString *)key {
	[self addCustomData:object withKey:key toCustomDataDictionary:customDeviceData];
}

- (void)addCustomData:(NSObject *)object withKey:(NSString *)key toCustomDataDictionary:(NSMutableDictionary *)customData {
	// Special cases
	if ([object isKindOfClass:[NSDate class]]) {
		object = [ATUtilities stringRepresentationOfDate:(NSDate *)object];
	}
	
	BOOL allowedData = ([object isKindOfClass:[NSString class]] ||
						[object isKindOfClass:[NSNumber class]] ||
						[object isKindOfClass:[NSNull class]]);
	
	NSAssert(allowedData, @"Custom data must be of type NSString, NSNumber, or NSNull. Attempted to add custom data of type %@", NSStringFromClass([object class]));
	
	if (allowedData) {
		[customData setObject:object forKey:key];
	}
}

- (void)removeCustomPersonDataWithKey:(NSString *)key {
	[customPersonData removeObjectForKey:key];
}

- (void)removeCustomDeviceDataWithKey:(NSString *)key {
	[customDeviceData removeObjectForKey:key];
}

- (void)addCustomData:(NSObject<NSCoding> *)object withKey:(NSString *)key {
	[self addCustomDeviceData:object withKey:key];
}

- (void)removeCustomDataWithKey:(NSString *)key {
	[self removeCustomDeviceDataWithKey:key];
}

#if TARGET_OS_IPHONE
- (void)presentMessageCenterFromViewController:(UIViewController *)viewController {
	[[ATBackend sharedBackend] presentMessageCenterFromViewController:viewController];
}

- (void)presentFeedbackDialogFromViewController:(UIViewController *)viewController {
	NSString *title = ATLocalizedString(@"Give Feedback", @"First feedback screen title.");
	NSString *body = [NSString stringWithFormat:ATLocalizedString(@"Please let us know how to make %@ better for you!", @"Feedback screen body. Parameter is the app name."), [[ATBackend sharedBackend] appName]];
	NSString *placeholder = ATLocalizedString(@"How can we help? (required)", @"First feedback placeholder text.");
	[[ATBackend sharedBackend] presentIntroDialogFromViewController:viewController withTitle:title prompt:body placeholderText:placeholder];
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
	NSString *path = [[NSBundle bundleForClass:[ATBackend class]] bundlePath];
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
