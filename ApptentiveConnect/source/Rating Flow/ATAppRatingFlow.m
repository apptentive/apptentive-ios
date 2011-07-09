//
//  ATAppRatingFlow.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 7/8/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import "ATAppRatingFlow.h"
#import "ATConnect.h"

NSString *const ATAppRatingFlowLastUsedVersionKey = @"ATAppRatingFlowLastUsedVersionKey";
NSString *const ATAppRatingFlowLastUsedVersionFirstUseDateKey = @"ATAppRatingFlowLastUsedVersionFirstUseDateKey";
NSString *const ATAppRatingFlowDeclinedToRateThisVersionKey = @"ATAppRatingFlowDeclinedToRateThisVersionKey";
NSString *const ATAppRatingFlowUserDislikesThisVersionKey = @"ATAppRatingFlowUserDislikesThisVersionKey";
NSString *const ATAppRatingFlowLastPromptDateKey = @"ATAppRatingFlowLastPromptDateKey";

NSString *const ATAppRatingFlowUseCountKey = @"ATAppRatingFlowUseCountKey";
NSString *const ATAppRatingFlowSignificantEventsCountKey = @"ATAppRatingFlowSignificantEventsCountKey";


static ATAppRatingFlow *sharedRatingFlow = nil;

@interface ATAppRatingFlow (Private)
- (NSString *)appName;
- (NSURL *)URLForRatingApp;
- (void)openURLForRatingApp;
- (BOOL)shouldShowDialog;
- (void)showDialogIfNecessary;
- (void)updateVersionInfo;
- (void)userDidUseApp;
- (void)userDidSignificantEvent;
- (void)setRatingDialogWasShown;
- (void)setUserDislikesThisVersion;
- (void)setDeclinedToRateThisVersion;
- (void)logDefaults;
@end


@implementation ATAppRatingFlow
@synthesize viewController, daysBeforePrompt, usesBeforePrompt, significantEventsBeforePrompt, daysBeforeRePrompting;


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
#ifdef TARGET_IPHONE_SIMULATOR
    [self logDefaults];
#endif
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

- (IBAction)showEnjoymentDialog:(id)sender {
#if TARGET_OS_IPHONE
    if (!enjoymentDialog) {
        NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Are you enjoying using %@?", @"Title for enjoyment alert view. Parameter is app name."), [self appName]];
        
        enjoymentDialog = [[UIAlertView alloc] initWithTitle:title message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"No", @"no"), NSLocalizedString(@"Yes", @"yes"), nil];
        [enjoymentDialog show];
    }
#elif TARGET_OS_MAC
#endif
    [self setRatingDialogWasShown];
}

- (IBAction)showRatingDialog:(id)sender {
#if TARGET_OS_IPHONE
    if (!ratingDialog) {
        NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Rate %@?", @"Rate app title. Parameter is app name."), [self appName]];
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"If you enjoy %@, we'd really appreciate you taking the time to rate the app.", @"Rate app message. Parameter is app name."), [self appName]];
        
        NSString *rateAppTitle = [NSString stringWithFormat:NSLocalizedString(@"Rate %@", @"Rate app button title"), [self appName]];
        
        ratingDialog = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:NSLocalizedString(@"No thanks", @"cancel title for app rating dialog") otherButtonTitles:rateAppTitle, NSLocalizedString(@"Remind me later", @"Remind me later button title"), nil];
        [ratingDialog show];
    }
#elif TARGET_OS_MAC
#endif
    [self setRatingDialogWasShown];
}

#if TARGET_OS_IPHONE
#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == enjoymentDialog) {
        if (buttonIndex == 0) { // no
            [self setUserDislikesThisVersion];
            if (!self.viewController) {
                NSLog(@"No view controller to present feedback interface!!");
            } else {
                [[ATConnect sharedConnection] presentFeedbackControllerFromViewController:self.viewController];
            }
        } else if (buttonIndex == 1) { // yes
            [self showRatingDialog:self];
        }
        [enjoymentDialog release], enjoymentDialog = nil;
    } else if (alertView == ratingDialog) {
        if (buttonIndex == 1) { // rate
            [self openURLForRatingApp];
        } else if (buttonIndex == 2) { // remind later
            [self setRatingDialogWasShown];
        } else if (buttonIndex == 0) { // no thanks
            [self setDeclinedToRateThisVersion];
        }
        [ratingDialog release], ratingDialog = nil;
    }
}
#elif TARGET_OS_MAC
#endif
@end


@implementation ATAppRatingFlow (Private)
- (NSString *)appName {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
}

- (NSURL *)URLForRatingApp {
#if TARGET_OS_IPHONE
    NSString *URLString = [NSString stringWithFormat:@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@", iTunesAppID];
#elif TARGET_OS_MAC
    NSString *URLString = [NSString stringWithFormat:@"macappstore://itunes.apple.com/app/id%@?mt=12", iTunesAppID];
#endif
    return [NSURL URLWithString:URLString];
}

- (void)openURLForRatingApp {
    NSURL *url = [self URLForRatingApp];
#if TARGET_OS_IPHONE
    if (![[UIApplication sharedApplication] canOpenURL:url]) {
        NSLog(@"No application can open the URL: %@", url);
    }
    [[UIApplication sharedApplication] openURL:url];
#elif TARGET_OS_MAC
    [[NSWorkspace defaultWorkspace] openURL:url];
#endif
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
        NSDate *lastPrompt = [defaults objectForKey:ATAppRatingFlowLastPromptDateKey];
        if (lastPrompt != nil && self.daysBeforeRePrompting != 0) {
            double nextPromptDouble = [lastPrompt timeIntervalSince1970] + 60*60*24*self.daysBeforeRePrompting;
            if ([[NSDate date] timeIntervalSince1970] < nextPromptDouble) {
                break;
            }
        }
        
        // Make sure the user has been using the app long enough to be bothered.
        NSDate *firstUse = [defaults objectForKey:ATAppRatingFlowLastUsedVersionFirstUseDateKey];
        if (firstUse != nil && self.daysBeforePrompt != 0) {
            double nextPromptDouble = [firstUse timeIntervalSince1970] + (double)(60*60*24*self.daysBeforePrompt);
            if ([[NSDate date] timeIntervalSince1970] < nextPromptDouble) {
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
        
        [defaults setObject:[NSDate date] forKey:ATAppRatingFlowLastUsedVersionFirstUseDateKey];
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
    count++;
    
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

- (void)setRatingDialogWasShown {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSDate date] forKey:ATAppRatingFlowLastPromptDateKey];
}

- (void)setUserDislikesThisVersion {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:YES] forKey:ATAppRatingFlowUserDislikesThisVersionKey];
}

- (void)setDeclinedToRateThisVersion {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:YES] forKey:ATAppRatingFlowDeclinedToRateThisVersionKey];
}

- (void)logDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *keys = [NSArray arrayWithObjects:ATAppRatingFlowLastUsedVersionKey, ATAppRatingFlowLastUsedVersionFirstUseDateKey, ATAppRatingFlowDeclinedToRateThisVersionKey, ATAppRatingFlowUserDislikesThisVersionKey, ATAppRatingFlowLastPromptDateKey, ATAppRatingFlowUseCountKey, ATAppRatingFlowSignificantEventsCountKey, nil];
    NSLog(@"-- BEGIN ATAppRatingFlow DEFAULTS --");
    for (NSString *key in keys) {
        NSLog(@"%@ == %@", key, [defaults objectForKey:key]);
    }
    NSLog(@"-- END ATAppRatingFlow DEFAULTS --");
}
@end
