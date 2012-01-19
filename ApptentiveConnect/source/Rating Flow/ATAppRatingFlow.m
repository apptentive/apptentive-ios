//
//  ATAppRatingFlow.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 7/8/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import "ATAppRatingFlow.h"
#import "ATConnect.h"
#import "ATReachability.h"
#import "ATAppRatingMetrics.h"

NSString *const ATAppRatingFlowLastUsedVersionKey = @"ATAppRatingFlowLastUsedVersionKey";
NSString *const ATAppRatingFlowLastUsedVersionFirstUseDateKey = @"ATAppRatingFlowLastUsedVersionFirstUseDateKey";
NSString *const ATAppRatingFlowDeclinedToRateThisVersionKey = @"ATAppRatingFlowDeclinedToRateThisVersionKey";
NSString *const ATAppRatingFlowUserDislikesThisVersionKey = @"ATAppRatingFlowUserDislikesThisVersionKey";
NSString *const ATAppRatingFlowLastPromptDateKey = @"ATAppRatingFlowLastPromptDateKey";
NSString *const ATAppRatingFlowRatedAppKey = @"ATAppRatingFlowRatedAppKey";

NSString *const ATAppRatingFlowUseCountKey = @"ATAppRatingFlowUseCountKey";
NSString *const ATAppRatingFlowSignificantEventsCountKey = @"ATAppRatingFlowSignificantEventsCountKey";


static ATAppRatingFlow *sharedRatingFlow = nil;

#if TARGET_OS_IPHONE
@interface ATAppRatingFlow ()
@property (nonatomic, retain) UIViewController *viewController;
@end
#endif


@interface ATAppRatingFlow (Private)
- (void)postNotification:(NSString *)name;
- (void)postNotification:(NSString *)name forButton:(int)button;
- (NSString *)appName;
- (NSURL *)URLForRatingApp;
- (void)openURLForRatingApp;
- (BOOL)shouldShowDialog;
/*! Returns YES if a dialog was shown. */
- (BOOL)showDialogIfNecessary;
- (void)updateVersionInfo;
- (void)userDidUseApp;
- (void)userDidSignificantEvent;
- (void)setRatingDialogWasShown;
- (void)setUserDislikesThisVersion;
- (void)setDeclinedToRateThisVersion;
- (void)setRatedApp;
- (void)logDefaults;

#if TARGET_OS_IPHONE
- (void)appWillEnterBackground:(NSNotification *)notification;
#endif
@end


@implementation ATAppRatingFlow
@synthesize daysBeforePrompt, usesBeforePrompt, significantEventsBeforePrompt, daysBeforeRePrompting;
#if TARGET_OS_IPHONE
@synthesize viewController;
#endif

- (id)initWithAppID:(NSString *)anITunesAppID {
    if ((self = [super init])) {
        iTunesAppID = [anITunesAppID retain];
        self.daysBeforePrompt = kATAppRatingDefaultDaysBeforePrompt;
        self.usesBeforePrompt = kATAppRatingDefaultUsesBeforePrompt;
        self.significantEventsBeforePrompt = kATAppRatingDefaultSignificantEventsBeforePrompt;
        self.daysBeforeRePrompting = kATAppRatingDefaultDaysBeforeRePrompting;
#if TARGET_OS_IPHONE
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterBackground:) name:UIApplicationWillResignActiveNotification object:nil];
#endif
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

#if TARGET_OS_IPHONE
- (void)appDidLaunch:(BOOL)canPromptForRating viewController:(UIViewController *)vc 
#elif TARGET_OS_MAC
- (void)appDidLaunch:(BOOL)canPromptForRating
#endif
{
#if TARGET_OS_IPHONE
    self.viewController = vc;
#endif
    
#ifdef TARGET_IPHONE_SIMULATOR
    [self logDefaults];
#endif
    [self userDidUseApp];
    BOOL showedDialog = NO;
    if (canPromptForRating) {
        showedDialog = [self showDialogIfNecessary];
    }
    
#if TARGET_OS_IPHONE
    if (!showedDialog) {
        self.viewController = nil;
    }
#endif
}

#if TARGET_OS_IPHONE
- (void)appDidEnterForeground:(BOOL)canPromptForRating viewController:(UIViewController *)vc {
    self.viewController = vc;
    [self userDidUseApp];
    
    BOOL showedDialog = NO;
    if (canPromptForRating) {
        showedDialog = [self showDialogIfNecessary];
    }
    
    if (!showedDialog) {
        self.viewController = nil;
    }
}
#endif

#if TARGET_OS_IPHONE
- (void)userDidPerformSignificantEvent:(BOOL)canPromptForRating viewController:(UIViewController *)vc
#elif TARGET_OS_MAC
- (void)userDidPerformSignificantEvent:(BOOL)canPromptForRating
#endif
{
#if TARGET_OS_IPHONE
    self.viewController = vc;
#endif
    [self userDidSignificantEvent];
    
    BOOL showedDialog = NO;
    if (canPromptForRating) {
        showedDialog = [self showDialogIfNecessary];
    }
    
#if TARGET_OS_IPHONE
    if (!showedDialog) {
        self.viewController = nil;
    }
#endif
}

#if TARGET_OS_IPHONE
- (void)showEnjoymentDialog:(UIViewController *)vc
#elif TARGET_OS_MAC
- (IBAction)showEnjoymentDialog:(id)sender
#endif
{
    NSString *title = [NSString stringWithFormat:ATLocalizedString(@"Do you love %@?", @"Title for enjoyment alert view. Parameter is app name."), [self appName]];
#if TARGET_OS_IPHONE
    self.viewController = vc;
    if (!enjoymentDialog) {
        enjoymentDialog = [[UIAlertView alloc] initWithTitle:title message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:ATLocalizedString(@"No", @"no"), ATLocalizedString(@"Yes", @"yes"), nil];
        [enjoymentDialog show];
    }
#elif TARGET_OS_MAC
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert addButtonWithTitle:ATLocalizedString(@"Yes", @"yes")];
    [alert addButtonWithTitle:ATLocalizedString(@"No", @"no")];
    [alert setMessageText:title];
    [alert setInformativeText:ATLocalizedString(@"You've been using this app for a while. Are you enjoying using it?", @"Enjoyment dialog text")];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert setIcon:[NSImage imageNamed:NSImageNameApplicationIcon]];
    NSUInteger result = [alert runModal];
    if (result == NSAlertFirstButtonReturn) { // yes
#if TARGET_OS_IPHONE
        [self showRatingDialog:self.viewController];
#elif TARGET_OS_MAC
        [self showRatingDialog:self];
#endif
    } else if (result == NSAlertSecondButtonReturn) { // no
        [self setUserDislikesThisVersion];
        [[ATConnect sharedConnection] showFeedbackWindow:self];
    }
#endif
	[self postNotification:ATAppRatingDidPromptForEnjoymentNotification];
    [self setRatingDialogWasShown];
}

#if TARGET_OS_IPHONE
- (void)showRatingDialog:(UIViewController *)vc
#elif TARGET_OS_MAC
- (IBAction)showRatingDialog:(id)sender 
#endif
{
    NSString *title = ATLocalizedString(@"Thank You", @"Rate app title.");
    NSString *message = [NSString stringWithFormat:ATLocalizedString(@"We're so happy to hear that you love %@! It'd be really helpful if you rated us in the App Store. Thanks so much for spending some time with us.", @"Rate app message. Parameter is app name."), [self appName]];
    NSString *rateAppTitle = [NSString stringWithFormat:ATLocalizedString(@"Rate %@", @"Rate app button title"), [self appName]];
    NSString *noThanksTitle = ATLocalizedString(@"No Thanks", @"cancel title for app rating dialog");
    NSString *remindMeTitle = ATLocalizedString(@"Remind Me Later", @"Remind me later button title");
#if TARGET_OS_IPHONE
    self.viewController = vc;
    if (!ratingDialog) {
        ratingDialog = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:noThanksTitle otherButtonTitles:rateAppTitle, remindMeTitle, nil];
        [ratingDialog show];
    }
#elif TARGET_OS_MAC
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert addButtonWithTitle:noThanksTitle];
    [alert addButtonWithTitle:remindMeTitle];
    [alert addButtonWithTitle:rateAppTitle];
    [alert setMessageText:title];
    [alert setInformativeText:message];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert setIcon:[NSImage imageNamed:NSImageNameApplicationIcon]];
    NSUInteger result = [alert runModal];
    if (result == NSAlertFirstButtonReturn) { // cancel
        [self setDeclinedToRateThisVersion];
    } else if (result == NSAlertSecondButtonReturn) { // remind me
        [self setRatingDialogWasShown];
    } else if (result == NSAlertThirdButtonReturn) { // rate app
        [self openURLForRatingApp];
    }
#endif
	[self postNotification:ATAppRatingDidPromptForRatingNotification];
    [self setRatingDialogWasShown];
}

#if TARGET_OS_IPHONE
#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == enjoymentDialog) {
        [enjoymentDialog release], enjoymentDialog = nil;
        if (buttonIndex == 0) { // no
			[self postNotification:ATAppRatingDidClickEnjoymentButtonNotification forButton:ATAppRatingEnjoymentButtonTypeNo];
            [self setUserDislikesThisVersion];
            if (!self.viewController) {
                NSLog(@"No view controller to present feedback interface!!");
            } else {
                ATConnect *connection = [ATConnect sharedConnection];
                connection.customPlaceholderText = ATLocalizedString(@"What can we do to ensure that you love our app? We appreciate your constructive feedback.", @"Custom placeholder feedback text when user is unhappy with the application.");
                ATFeedbackControllerType oldType = connection.feedbackControllerType;
                connection.feedbackControllerType = ATFeedbackControllerSimple;
                [connection presentFeedbackControllerFromViewController:self.viewController];
                connection.customPlaceholderText = nil;
                self.viewController = nil;
                connection.feedbackControllerType = oldType;
            }
        } else if (buttonIndex == 1) { // yes
			[self postNotification:ATAppRatingDidClickEnjoymentButtonNotification forButton:ATAppRatingEnjoymentButtonTypeYes];
            [self showRatingDialog:self.viewController];
        }
    } else if (alertView == ratingDialog) {
        [ratingDialog release], ratingDialog = nil;
        if (buttonIndex == 1) { // rate
			[self postNotification:ATAppRatingDidClickRatingButtonNotification forButton:ATAppRatingButtonTypeRateApp];
            [self openURLForRatingApp];
        } else if (buttonIndex == 2) { // remind later
			[self postNotification:ATAppRatingDidClickRatingButtonNotification forButton:ATAppRatingButtonTypeRemind];
            [self setRatingDialogWasShown];
        } else if (buttonIndex == 0) { // no thanks
			[self postNotification:ATAppRatingDidClickRatingButtonNotification forButton:ATAppRatingButtonTypeNo];
            [self setDeclinedToRateThisVersion];
        }
        self.viewController = nil;
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    NSLog(@"ATAppRatingFlow dismissing alert view %@, %d", alertView, buttonIndex);
    if (alertView == enjoymentDialog) {
        [enjoymentDialog release], enjoymentDialog = nil;
        self.viewController = nil;
    } else if (alertView == ratingDialog) {
        [ratingDialog release], ratingDialog = nil;
        self.viewController = nil;
    }
}
#endif
@end


@implementation ATAppRatingFlow (Private)
- (void)postNotification:(NSString *)name {
	[[NSNotificationCenter defaultCenter] postNotificationName:name object:self];
}

- (void)postNotification:(NSString *)name forButton:(int)button {
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:button] forKey:ATAppRatingButtonTypeKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:name object:self userInfo:userInfo];
}

- (NSString *)appName {
    NSString *displayName = nil;
    displayName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    if (!displayName) {
        displayName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
    }
    return displayName;
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
    [self setRatedApp];
#if TARGET_OS_IPHONE
    if (![[UIApplication sharedApplication] canOpenURL:url]) {
        NSLog(@"No application can open the URL: %@", url);
    }
    [[UIApplication sharedApplication] openURL:url];
#elif TARGET_OS_MAC
    [[NSWorkspace sharedWorkspace] openURL:url];
#endif
}

- (BOOL)shouldShowDialog {
    BOOL result = NO;
    
    do { // once
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
		// No network connection, don't show dialog.
		if ([[ATReachability sharedReachability] currentNetworkStatus] == ATNetworkNotReachable) {
			break;
		}
		
        // Check to see if the user has rated the app.
        NSNumber *rated = [defaults objectForKey:ATAppRatingFlowRatedAppKey];
        if (rated != nil && [rated boolValue]) {
            break;
        }
        
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

- (BOOL)showDialogIfNecessary {
    if ([self shouldShowDialog]) {
#if TARGET_OS_IPHONE
        [self showEnjoymentDialog:self.viewController];
#elif TARGET_OS_MAC
        [self showEnjoymentDialog:self];
#endif
        return YES;
    }
    return NO;
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

- (void)setRatedApp {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:YES] forKey:ATAppRatingFlowRatedAppKey];
}

- (void)logDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *keys = [NSArray arrayWithObjects:ATAppRatingFlowLastUsedVersionKey, ATAppRatingFlowLastUsedVersionFirstUseDateKey, ATAppRatingFlowDeclinedToRateThisVersionKey, ATAppRatingFlowUserDislikesThisVersionKey, ATAppRatingFlowLastPromptDateKey, ATAppRatingFlowUseCountKey, ATAppRatingFlowSignificantEventsCountKey, ATAppRatingFlowRatedAppKey, nil];
    NSLog(@"-- BEGIN ATAppRatingFlow DEFAULTS --");
    for (NSString *key in keys) {
        NSLog(@"%@ == %@", key, [defaults objectForKey:key]);
    }
    NSLog(@"-- END ATAppRatingFlow DEFAULTS --");
}

#if TARGET_OS_IPHONE
- (void)appWillEnterBackground:(NSNotification *)notification {
    // We want to hide any dialogs here.
    if (enjoymentDialog) {
        [enjoymentDialog dismissWithClickedButtonIndex:3 animated:NO];
    }
    if (ratingDialog) {
        [ratingDialog dismissWithClickedButtonIndex:3 animated:NO];
    }
}
#endif
@end
