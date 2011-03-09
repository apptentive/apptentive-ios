//
//  WowieConnect.h
//  WowieConnect
//
//  Created by Michael Saffitz on 12/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ObjectiveResource.h"
#import "Device.h"

typedef enum {
	TopCenter,
	BottomCenter
} ButtonLocation;

@interface WowieConnect : NSObject {
    @private
    NSString *appKey_;
    NSString *appSecret_;
    Device *device_;
    NSDate *launchTime_;
    NSMutableDictionary *wowieConnectDict;
    BOOL hasError;
}

@property (nonatomic, readonly) BOOL hasError;

#pragma mark Initialization
+ (WowieConnect*)sharedInstance;
+ (WowieConnect*)sharedInstanceWithAppKey:(NSString *)appKey andSecret:(NSString *)appSecret;
- (void) setAppKey:(NSString*)appKey andSecret:(NSString*)appSecret;

#pragma mark Invocation
- (void) displayButtonOnView:(UIViewController *)viewController atLocation:(ButtonLocation)location;
- (void) presentWowieConnectModalViewControllerForParent:(UIViewController *)viewController;

#pragma mark Telemetry
- (BOOL) recordMetricWithKey:(NSString*)key
                andDateValue:(NSDate*)dateValue
             andDecimalValue:(NSDecimalNumber*)decimalValue 
              andStringValue:(NSString*)stringValue
                  forReplace:(BOOL)replace;
- (BOOL) recordFeedback:(NSString*)feedback withType:(NSString*)feedbackType;
- (void) recordDeviceWithFirstName:(NSString*)firstName 
                       andLastName:(NSString*)lastName 
                          andEmail:(NSString*)emailAddress;

#pragma mark LifeCycle

// FUTURE
/*
 Disable automated collection
 */

- (void) syncData;
- (BOOL) invalidState;

@end
