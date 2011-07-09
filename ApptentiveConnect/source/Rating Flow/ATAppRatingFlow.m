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
        self.daysBeforePrompt = kATAppRatingDefaultDaysBeforePrompt;
        self.usesBeforePrompt = kATAppRatingDefaultUsesBeforePrompt;
        self.significantEventsBeforePrompt = kATAppRatingDefaultSignificantEventsBeforePrompt;
        self.daysBeforeRePrompting = kATAppRatingDefaultDaysBeforeRePrompting;
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
    BOOL result = NO;
    
    do { // once
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        // Check to see if the user has rejected rating this version.
        NSNumber *rejected = [defaults objectForKey:ATAppRatingFlowDeclinedToRateThisVersionKey];
        if (rejected != nil && [rejected boolValue]) {
            break;
        }
        
        // Check to see if the user dislikes this version of the app.
        NSNumber *dislikes = [defaults objectForKey:ATAppRatingFlowUserDislikesThisVersionKey];
        if (dislikes != nil && [dislikes boolValue]) {
            break;
        }
        
        // If we don't have the last version set, update it and don't show
        // the dialog.
        NSString *lastBundleVersion = [defaults objectForKey:ATAppRatingFlowLastUsedVersionKey];
        if (lastBundleVersion == nil) {
            [self updateVersionInfo];
            break;
        }
        
        // If the user has been prompted already, make sure we're after the
        // number of days for them to be re-prompted.
        NSNumber *lastPrompt = [defaults objectForKey:ATAppRatingFlowLastPromptDateKey];
        if (lastPrompt != nil && self.daysBeforeRePrompting != 0) {
            double lastPromptDouble = [lastPrompt doubleValue];
            double nextPromptDouble = lastPromptDouble + 60*60*24*self.daysBeforeRePrompting;
            if ([[NSDate now] timeIntervalSince1970] < nextPromptDouble) {
                break;
            }
        }
        
        // Make sure the user has been using the app long enough to be bothered.
        NSNumber *firstUse = [defaults objectForKey:ATAppRatingFlowLastUsedVersionFirstUseDateKey];
        if (firstUse != nil && self.daysBeforePrompt != 0) {
            double firstUseDouble = [firstUse doubleValue];
            double nextPromptDouble = firstUseDouble + 60*60*24*self.daysBeforePrompt;
            if ([[NSDate now] timeIntervalSince1970] < nextPromptDouble) {
                break;
            }
        }
        
        // If the number of significant events is big enough, show a prompt.
        NSNumber *significantEvents = [defaults objectForKey:ATAppRatingFlowSignificantEventsCountKey];
        if (significantEvents != nil && self.significantEventsBeforePrompt != 0) {
            NSUInteger count = [significantEvents unsignedIntegerValue];
            if (count > self.significantEventsBeforePrompt) {
                result = YES;
                break;
            }
        }
        
        // If the number of app uses is big enough, show a prompt.
        NSNumber *appUses = [defaults objectForKey:ATAppRatingFlowUseCountKey];
        if (appUses != nil && self.usesBeforePrompt != 0) {
            NSUInteger count = [appUses unsignedIntegerValue];
            if (count > self.usesBeforePrompt) {
                result = YES;
                break;
            }
        }
        
        // Only if both the uses and significant events triggers are set to
        // 0 (disabled), should we show a dialog based on prompt dates here.
        if (self.usesBeforePrompt == 0 && self.significantEventsBeforePrompt == 0) {
            result = YES;
            break;
        }
    } while (NO);
    
    return result;
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
        NSNumber *nowObject = [NSNumber numberWithDouble:[now timeIntervalSince1970]];
        
        [defaults setObject:nowObject forKey:ATAppRatingFlowLastUsedVersionFirstUseDateKey];
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
    //!!
}

- (void)setRatingDialogWasShown {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *now = [NSDate date];
    NSNumber *nowObject = [NSNumber numberWithDouble:[now timeIntervalSince1970]];
    [defaults setObject:nowObject forKey:ATAppRatingFlowLastPromptDateKey];
}
@end
