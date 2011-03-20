//
//  ATConnect.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/12/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import "ATConnect.h"
#import "ATBackend.h"
#import "ATFeedback.h"
#import "ATFeedbackController.h"
#import "ATUtilities.h"

@interface ATConnect ()
@property (nonatomic, retain) NSString *apiKey;
@end

static ATConnect *sharedConnection = nil;

@implementation ATConnect
@synthesize apiKey;

+ (ATConnect *)sharedConnectionWithAPIKey:(NSString *)anAPIKey {
    @synchronized(self) {
        if (sharedConnection == nil) {
            sharedConnection = [[ATConnect alloc] init];
            sharedConnection.apiKey = anAPIKey;
        }
    }
    return sharedConnection;
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
        [[ATBackend sharedBackend] updateAPIKey:self.apiKey];
    }
}

- (void)presentFeedbackControllerFromViewController:(UIViewController *)viewController {
    UIImage *screenshot = [ATUtilities imageByTakingScreenshot];
    ATFeedbackController *vc = [[ATFeedbackController alloc] init];
    vc.feedback = [[[ATFeedback alloc] init] autorelease];
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
}

+ (NSBundle *)resourceBundle {
    NSBundle *bundle = [[NSBundle alloc] initWithPath:@"ApptentiveResources.bundle"];
    return [bundle autorelease];
}
@end
