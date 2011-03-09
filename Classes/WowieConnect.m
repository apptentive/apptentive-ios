//
//  WowieConnect.m
//  WowieConnect
//
//  Created by Michael Saffitz on 12/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "WowieConnect.h"
#import "FeedbackViewController.h"
#import "FeedbackButtonViewController.h"
#import "GatherDeviceInfoViewController.h"
#import "DataPoint.h"
#import "Utilities.h"
#import "Feedback.h"

// TODO Finish making this into a singleton so that it's a little easier to work with

#pragma mark Singleton
static WowieConnect *sharedInstance = nil;

#pragma mark Constants
static NSString* WOWIE_CONNECT_ENDPOINT = @"http://wowieconnect.heroku.com/" ; 

#pragma mark Private Declarations
@interface WowieConnect()

@property (nonatomic, retain) NSString *appKey_;
@property (nonatomic, retain) NSString *appSecret_;
@property (nonatomic, retain) Device *device_;
@property (nonatomic, retain) NSDate *launchTime_;
@property (nonatomic, retain) NSMutableDictionary *wowieConnectDict;

- (void)showFeedback:(UIViewController *)feedbackViewController 
       forController:(UIViewController *)viewController;

- (NSString*)getArchivePath:(NSError**)error;

@end


@implementation WowieConnect

@synthesize appKey_;
@synthesize appSecret_;
@synthesize device_;
@synthesize launchTime_;
@synthesize wowieConnectDict;
@synthesize hasError;

#pragma mark Initialization
+ (WowieConnect*)sharedInstance
{
    @synchronized(self)
    {
        if (sharedInstance == nil)
            sharedInstance = [[WowieConnect alloc] init];
    }
    return sharedInstance;
}

+ (WowieConnect*)sharedInstanceWithAppKey:(NSString *)appKey andSecret:(NSString *)appSecret
{
    [[WowieConnect sharedInstance] setAppKey:appKey andSecret:appSecret];
    return [WowieConnect sharedInstance];
}

- (id)init
{
    [super init];  // TODO is this necessary?
    [ObjectiveResourceConfig setSite:WOWIE_CONNECT_ENDPOINT];
    
    NSError *error;
    wowieConnectDict = [NSKeyedUnarchiver unarchiveObjectWithFile:[self getArchivePath:&error]];
    
    if (error != nil) 
    {
        hasError = YES;
        return self;
    }

    self.device_ = [Device createOrRetrieveDevice];
 
    // Increment the invocation counter
    [self recordMetricWithKey:@"wcinternal.invocations"
                 andDateValue:[[NSDate alloc] init]
              andDecimalValue:[NSDecimalNumber decimalNumberWithString:@"1.0"]
               andStringValue:nil
                   forReplace:NO];
    
    // Record the launch time
    self.launchTime_ = [[NSDate alloc] init];
    // TODO Need to ensure that if I persist the invocation_time in dealloc that when the app terminates it
    // will properly persist
    
    return self;
}

- (void) setAppKey:(NSString*)appKey andSecret:(NSString*)appSecret
{
    self.appKey_ = appKey;
    self.appSecret_ = appSecret;
}


#pragma mark Invocation
- (void) displayButtonOnView:(UIViewController *)viewController atLocation:(ButtonLocation)location {
	if ([self invalidState]) { return; }
    
    FeedbackButtonViewController *fbViewController = [[FeedbackButtonViewController alloc] initWithNibName:@"FeedbackButtonViewController" bundle:nil];
	[fbViewController displayAtTopCenter:viewController.view.frame];
	fbViewController.baseViewController = viewController;
	[viewController.view addSubview:fbViewController.view];
    
	// TODO fbViewController needs to be released at some point???
}

- (void) presentWowieConnectModalViewControllerForParent:(UIViewController *)viewController {
    if ([self invalidState]) { return; }
    
    if ([self.device_ buildDevice])
    {
        GatherDeviceInfoViewController *deviceViewController = [[[GatherDeviceInfoViewController alloc] init] autorelease];
        [viewController presentModalViewController:deviceViewController animated:YES];
        // TODO Present a view that asks the user for basic information
    } else
    {
        FeedbackViewController *feedbackViewController = [[[FeedbackViewController alloc] init] autorelease];
        [self showFeedback:feedbackViewController forController:viewController];
    }
}

#pragma mark Telemetry
- (BOOL) recordMetricWithKey:(NSString*)key
                andDateValue:(NSDate*)dateValue
             andDecimalValue:(NSDecimalNumber*)decimalValue 
              andStringValue:(NSString*)stringValue
                  forReplace:(BOOL)replace
{
    if ([self invalidState]) { return NO; }

    
    // Error checking-- at least a date, decimal, or string must be provided, as with a key
    // If replace, look for unpersisted and replace
    // Create and persist
    
    // Think about how this shows up in the dictionary -- key may occur multiple times, not sure if thats
    // OK
    
    
    DataPoint *dataPoint = [[[DataPoint alloc] init] autorelease];
    
    
    NSString *dataPointKey = [[[[NSDate alloc] init] autorelease] description];
    [wowieConnectDict setObject:dataPoint forKey:dataPointKey];
    
    return YES;
}

- (BOOL) recordFeedback:(NSString*)feedback withType:(NSString*)feedbackType {
    if ([self invalidState]) { return NO; }
    
    Feedback *feedback_ = [[[Feedback alloc] init] autorelease];
    feedback_.feedback = feedback;
    feedback_.feedbackType = feedbackType;
    
    NSString *feedbackKey = [[[[NSDate alloc] init] autorelease] description];
    [wowieConnectDict setObject:feedback_ forKey:feedbackKey];
    
    return YES;
}

- (void) recordDeviceWithFirstName:(NSString*)firstName 
                       andLastName:(NSString*)lastName 
                          andEmail:(NSString*)emailAddress {
    self.device_.firstName = firstName;
    self.device_.lastName = lastName;
    self.device_.emailAddress = emailAddress;
    [self.device_ archive];
}


#pragma mark LifeCycle
- (void) syncData
{}

#pragma mark Private Methods
- (void)showFeedback:(UIViewController *)feedbackViewController 
       forController:(UIViewController *)viewController
{
    //	[UVSession currentSession].isModal = YES;
    //	UINavigationController *userVoiceNav = [[[UINavigationController alloc] initWithRootViewController:rootViewController] autorelease];
    //	[[[UIApplication sharedApplication] keyWindow] presentModalViewController:rootViewController animated:YES];
    
    [viewController presentModalViewController:feedbackViewController animated:YES];
}

- (BOOL) invalidState
{
    if (hasError)
    {
        NSLog(@"An error has occured within WowieConnect.  Functionality has been disabled.");
        return YES;
    }
    if (self.appKey_ == nil || self.appSecret_ == nil)
    {
        NSLog(@"Your WowieConnect app key or secret has not been set.  Functionality has been disabled.");
        return YES;
    }
    return NO;
}

- (NSString*) getArchivePath:(NSError**)error 
{
    NSString *archivePath = [[Utilities applicationSupportFolder:error] stringByAppendingPathComponent:@"wowie.archive"];
    
    if (error != nil ) 
    {
        NSLog(@"unable to get archive path: %@", [*error code]);
        return nil;
    }
    return archivePath;
}


#pragma mark NSObject Methods
- (void) dealloc
{
    NSLog(@"dealloc WowieConnect");
    
    if (!hasError) {
        // TODO move to helper function
        NSDecimal secondsSinceLaunch = [[NSNumber numberWithDouble:(0-[self.launchTime_ timeIntervalSinceNow])]decimalValue];
        
        [self recordMetricWithKey:@"wcinternal.invocation_time"
                    andDateValue:launchTime_
                  andDecimalValue:[NSDecimalNumber decimalNumberWithDecimal:secondsSinceLaunch]
                   andStringValue:nil 
                       forReplace:NO];

        NSError *error;
        [NSKeyedArchiver archiveRootObject:wowieConnectDict toFile:[self getArchivePath:&error]];
        
        if (error != nil)
        {
            NSLog(@"Unable to persist dictionary: %@", [error code]);
        }
    }
    
    [device_ archive];
    [device_ release];

    [super dealloc];
}

@end

