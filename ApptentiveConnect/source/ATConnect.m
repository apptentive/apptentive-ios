//
//  ATConnect.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/12/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import "ATConnect.h"
#import "ATBackend.h"
#import "ATContactStorage.h"
#import "ATFeedback.h"
#import "ATFeedbackController.h"
#import "ATHUDView.h"
#import "ATUtilities.h"

static ATConnect *sharedConnection = nil;

@implementation ATConnect
@synthesize apiKey, showKeyboardAccessory;

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
    }
    return self;
}

- (void)dealloc {
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

- (void)presentFeedbackControllerFromViewController:(UIViewController *)viewController {
    UIImage *screenshot = [ATUtilities imageByTakingScreenshot];
    ATFeedbackController *vc = [[ATFeedbackController alloc] init];
    vc.feedback = [[[ATFeedback alloc] init] autorelease];
    ATContactStorage *contact = [ATContactStorage sharedContactStorage];
    if (contact.name) {
        vc.feedback.name = contact.name;
    }
    if (contact.phone) {
        vc.feedback.phone = contact.phone;
    }
    if (contact.email) {
        vc.feedback.email = contact.email;
    }
    vc.feedback.screenshot = screenshot;
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [viewController presentModalViewController:nc animated:YES];
    } else {
        nc.modalPresentationStyle = UIModalPresentationFormSheet;
        [viewController presentModalViewController:nc animated:YES];
    }
    [nc release];
    [vc release];
    ATHUDView *hud = [[ATHUDView alloc] initWithWindow:viewController.view.window];
    hud.label.text = @"Thanks!";
    [hud show];
    [hud release];
}

+ (NSBundle *)resourceBundle {
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSString *bundlePath = [path stringByAppendingPathComponent:@"ApptentiveResources.bundle"];
    NSBundle *bundle = [[NSBundle alloc] initWithPath:bundlePath];
    return [bundle autorelease];
}
@end
