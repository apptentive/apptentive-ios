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
#elif TARGET_OS_MAC
#import "ATFeedbackWindowController.h"
#endif


static ATConnect *sharedConnection = nil;


@implementation ATConnect
@synthesize apiKey, showKeyboardAccessory, shouldTakeScreenshot;

+ (ATConnect *)sharedConnection {
    @synchronized(self) {
        if (sharedConnection == nil) {
            sharedConnection = [[ATConnect alloc] init];
        }
    }
    return sharedConnection;
}

- (id)init {
    if ((self = [super init])) {
        self.showKeyboardAccessory = YES;
		self.shouldTakeScreenshot = YES;
    }
    return self;
}

- (void)dealloc {
#if TARGET_OS_MAC
    if (feedbackWindowController) {
        [feedbackWindowController release];
        feedbackWindowController = nil;
    }
#endif
    self.apiKey = nil;
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

#if TARGET_OS_IPHONE
- (void)presentFeedbackControllerFromViewController:(UIViewController *)viewController {
	UIImage *screenshot = nil;
    
    if (![[ATBackend sharedBackend] currentFeedback]) {
        ATFeedback *feedback = [[ATFeedback alloc] init];
    	if (self.shouldTakeScreenshot) {
            screenshot = [ATUtilities imageByTakingScreenshot];
            // Get the rotation of the view hierarchy and rotate the screenshot as
            // necessary.
            CGFloat rotation = [ATUtilities rotationOfViewHierarchyInRadians:viewController.view];
            screenshot = [ATUtilities imageByRotatingImage:screenshot byRadians:rotation];
        }
        ATContactStorage *contact = [ATContactStorage sharedContactStorage];
        if (contact.name) {
            feedback.name = contact.name;
        }
        if (contact.phone) {
            feedback.phone = contact.phone;
        }
        if (contact.email) {
            feedback.email = contact.email;
        }
        feedback.screenshot = screenshot;
        feedback.screenshotSwitchEnabled = (screenshot != nil);
        [[ATBackend sharedBackend] setCurrentFeedback:feedback];
        [feedback release];
        feedback = nil;
    }
    ATFeedbackController *vc = [[ATFeedbackController alloc] init];
    vc.feedback = [[ATBackend sharedBackend] currentFeedback];

    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [viewController presentModalViewController:nc animated:YES];
    } else {
        nc.modalPresentationStyle = UIModalPresentationFormSheet;
        [viewController presentModalViewController:nc animated:YES];
    }
    [nc release];
    [vc release];
}
#elif TARGET_OS_MAC
- (void)showFeedbackWindow:(id)sender withFeedbackType:(ATFeedbackType)feedbackType {
    if (!feedbackWindowController) {
        feedbackWindowController = [[ATFeedbackWindowController alloc] init];
    }
    //!! Set feedback window type.
    [feedbackWindowController showWindow:self];
}

- (IBAction)showFeedbackWindow:(id)sender {
    [self showFeedbackWindow:sender withFeedbackType:ATFeedbackTypeFeedback];
}

- (IBAction)showFeedbackWindowForFeedback:(id)sender {
    [self showFeedbackWindow:sender withFeedbackType:ATFeedbackTypeFeedback];
}

- (IBAction)showFeedbackWindowForQuestion:(id)sender {
    [self showFeedbackWindow:sender withFeedbackType:ATFeedbackTypeQuestion];
}

- (IBAction)showFeedbackWindowForBugReport:(id)sender {
    [self showFeedbackWindow:sender withFeedbackType:ATFeedbackTypeBug];
}
#endif

+ (NSBundle *)resourceBundle {
#if TARGET_OS_IPHONE
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSString *bundlePath = [path stringByAppendingPathComponent:@"ApptentiveResources.bundle"];
    NSBundle *bundle = [[NSBundle alloc] initWithPath:bundlePath];
    return [bundle autorelease];
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
