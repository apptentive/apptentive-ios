//
//  ATAppRatingFlow.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 7/8/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import "ATAppRatingFlow.h"


NSString *const ATAppRatingFlowLastUsedVersionKey = @"ATAppRatingFlowLastUsedVersionKey";
NSString *const ATAppRatingFlowLastUsedVersionFirstUseDateKey = @"ATAppRatingFlowLastUsedVersionFirstUseDateKey";
NSString *const ATAppRatingFlowDeclinedToRateThisVersionKey = @"ATAppRatingFlowDeclinedToRateThisVersionKey";
NSString *const ATAppRatingFlowUserDislikesThisVersionKey = @"ATAppRatingFlowUserDislikesThisVersionKey";
NSString *const ATAppRatingFlowLastPromptDateKey = @"ATAppRatingFlowLastPromptDateKey";

NSString *const ATAppRatingFlowUseCountKey = @"ATAppRatingFlowUseCountKey";
NSString *const ATAppRatingFlowSignificantEventsCountKey = @"ATAppRatingFlowSignificantEventsCountKey";


static ATAppRatingFlow *sharedRatingFlow = nil;

@interface ATAppRatingFlow (Private)
- (NSURL *)URLForRatingApp;
- (BOOL)shouldShowDialog;
- (void)showDialogIfNecessary;
- (void)updateVersionInfo;
- (void)userDidUseApp;
- (void)userDidSignificantEvent;
- (void)hideRatingDialog;
- (void)setRatingDialogWasShown;
@end


@implementation ATAppRatingFlow
@synthesize daysBeforePrompt, usesBeforePrompt, significantEventsBeforePrompt, daysBeforeRePrompting;


- (id)initWithAppID:(NSString *)anITunesAppID {
    if ((self = [super init])) {
        iTunesAppID = [anITunesAppID retain];
    }
    return self;
}

+ (ATAppRatingFlow *)sharedRatingFlowWithAppID:(NSString *)iTunesAppID {
    @synchronized(self) {
        if (sharedRatingFlow == nil) {
            sharedRatingFlow = [[ATAppRatingFlow alloc] initWithAppID:iTunesAppID];
        }
        return sharedRatingFlow;
    }
}

- (void)appDidLaunch:(BOOL)canPromptForRating {
    [self userDidUseApp];
    if (canPromptForRating) {
        [self showDialogIfNecessary];
    }
}

#if TARGET_OS_IPHONE
- (void)appDidEnterForeground:(BOOL)canPromptForRating {
    [self userDidUseApp];
    if (canPromptForRating) {
        [self showDialogIfNecessary];
    }
}
#endif

- (void)userDidPerformSignificantEvent:(BOOL)canPromptForRating {
    [self userDidSignificantEvent];
    if (canPromptForRating) {
        [self showDialogIfNecessary];
    }
}

- (IBAction)showRatingDialog:(id)sender {
    //!!
    [self setRatingDialogWasShown];
}
@end


@implementation ATAppRatingFlow (Private)
- (NSURL *)URLForRatingApp {
#if TARGET_OS_IPHONE
    NSString *URLString = [NSString stringWithFormat:@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@", iTunesAppID];
#elif TARGET_OS_MAC
    NSString *URLString = [NSString stringWithFormat:@"macappstore://itunes.apple.com/app/id%@?mt=12", iTunesAppID];
#endif
    return [[[NSURL alloc] initWithString:URLString] autorelease];
}

- (BOOL)shouldShowDialog {
    return NO;//!!
}

- (void)showDialogIfNecessary {
    if ([self shouldShowDialog]) {
        [self showRatingDialog:self];
    }
}

- (void)updateVersionInfo {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *currentBundleVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
    NSString *lastBundleVersion = [defaults objectForKey:ATAppRatingFlowLastUsedVersionKey];
    
    if (lastBundleVersion == nil || ![lastBundleVersion isEqualToString:currentBundleVersion]) {
        [defaults setObject:currentBundleVersion forKey:ATAppRatingFlowLastUsedVersionKey];
        NSDate *now = [NSDate date];
        [defaults setDouble:[now timeIntervalSince1970] forKey:ATAppRatingFlowLastUsedVersionFirstUseDateKey];
        [defaults setObject:[NSNumber numberWithBool:NO] forKey:ATAppRatingFlowDeclinedToRateThisVersionKey];
        [defaults setObject:[NSNumber numberWithBool:NO] forKey:ATAppRatingFlowUserDislikesThisVersionKey];
        
        [defaults synchronize];
    }
    
}

- (void)userDidUseApp {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSNumber *useCount = [defaults objectForKey:ATAppRatingFlowUseCountKey];
    NSUInteger count = 0;
    if (useCount != nil) {
        count = [useCount unsignedIntegerValue];
    }
    
    [defaults setObject:[NSNumber numberWithUnsignedInteger:count] forKey:ATAppRatingFlowUseCountKey];
    [defaults synchronize];
}

- (void)userDidSignificantEvent {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSNumber *eventCount = [defaults objectForKey:ATAppRatingFlowSignificantEventsCountKey];
    NSUInteger count = 0;
    if (eventCount != nil) {
        count = [eventCount unsignedIntegerValue];
    }
    
    [defaults setObject:[NSNumber numberWithUnsignedInteger:count] forKey:ATAppRatingFlowSignificantEventsCountKey];
    [defaults synchronize];
    
}

- (void)hideRatingDialog {
    
}

- (void)setRatingDialogWasShown {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *now = [NSDate date];
    [defaults setDouble:[now timeIntervalSince1970] forKey:ATAppRatingFlowLastPromptDateKey];
}
@end
