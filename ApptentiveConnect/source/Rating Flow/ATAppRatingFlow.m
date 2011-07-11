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

#if TARGET_OS_IPHONE
@interface ATAppRatingFlow ()
@property (nonatomic, retain) UIViewController *viewController;
@end
#endif


@interface ATAppRatingFlow (Private)
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
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Are you enjoying using %@?", @"Title for enjoyment alert view. Parameter is app name."), [self appName]];
#if TARGET_OS_IPHONE
    self.viewController = vc;
    if (!enjoymentDialog) {
        enjoymentDialog = [[UIAlertView alloc] initWithTitle:title message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"No", @"no"), NSLocalizedString(@"Yes", @"yes"), nil];
        [enjoymentDialog show];
    }
#elif TARGET_OS_MAC
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert addButtonWithTitle:NSLocalizedString(@"Yes", @"yes")];
    [alert addButtonWithTitle:NSLocalizedString(@"No", @"no")];
    [alert setMessageText:title];
    [alert setInformativeText:NSLocalizedString(@"You've been using this app for a while. Are you enjoying using it?", @"Enjoyment dialog text")];
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
    [self setRatingDialogWasShown];
}

#if TARGET_OS_IPHONE
- (void)showRatingDialog:(UIViewController *)vc
#elif TARGET_OS_MAC
- (IBAction)showRatingDialog:(id)sender 
#endif
{
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Rate %@?", @"Rate app title. Parameter is app name."), [self appName]];
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"If you enjoy %@, we'd really appreciate you taking the time to rate the app.", @"Rate app message. Parameter is app name."), [self appName]];
    NSString *rateAppTitle = [NSString stringWithFormat:NSLocalizedString(@"Rate %@", @"Rate app button title"), [self appName]];
    NSString *noThanksTitle = NSLocalizedString(@"No thanks", @"cancel title for app rating dialog");
    NSString *remindMeTitle = NSLocalizedString(@"Remind me later", @"Remind me later button title");
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
    [self setRatingDialogWasShown];
}

#if TARGET_OS_IPHONE
#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == enjoymentDialog) {
        [enjoymentDialog release], enjoymentDialog = nil;
        if (buttonIndex == 0) { // no
            [self setUserDislikesThisVersion];
            if (!self.viewController) {
                NSLog(@"No view controller to present feedback interface!!");
            } else {
                ATConnect *connection = [ATConnect sharedConnection];
                connection.customPlaceholderText = NSLocalizedString(@"Unhappy with this app? We'd love to hear why so we can make it better.", @"Custom placeholder feedback text when user is unhappy with the application.");
                [connection presentFeedbackControllerFromViewController:self.viewController];
                connection.customPlaceholderText = nil;
                self.viewController = nil;
            }
        } else if (buttonIndex == 1) { // yes
            [self showRatingDialog:self.viewController];
        }
    } else if (alertView == ratingDialog) {
        [ratingDialog release], ratingDialog = nil;
        if (buttonIndex == 1) { // rate
            [self openURLForRatingApp];
        } else if (buttonIndex == 2) { // remind later
            [self setRatingDialogWasShown];
        } else if (buttonIndex == 0) { // no thanks
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
    [[NSWorkspace sharedWorkspace] openURL:url];
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

- (void)logDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *keys = [NSArray arrayWithObjects:ATAppRatingFlowLastUsedVersionKey, ATAppRatingFlowLastUsedVersionFirstUseDateKey, ATAppRatingFlowDeclinedToRateThisVersionKey, ATAppRatingFlowUserDislikesThisVersionKey, ATAppRatingFlowLastPromptDateKey, ATAppRatingFlowUseCountKey, ATAppRatingFlowSignificantEventsCountKey, nil];
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
