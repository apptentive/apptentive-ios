//
//  ATBackend.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/19/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
#endif

@class ATContactUpdater;
@class ATFeedback;

/*! Handles all of the backend activities, such as sending feedback. */
@interface ATBackend : NSObject {
@private
    ATContactUpdater *contactUpdater;
    BOOL userDataWasUpdated;
}
@property (nonatomic, retain) NSString *apiKey;
/*! The feedback currently being worked on by the user. */
@property (nonatomic, retain) ATFeedback *currentFeedback;

+ (ATBackend *)sharedBackend;
#if TARGET_OS_IPHONE
+ (UIImage *)imageNamed:(NSString *)name;
#elif TARGET_OS_MAC
+ (NSImage *)imageNamed:(NSString *)name;
#endif

- (void)sendFeedback:(ATFeedback *)feedback;
- (void)updateUserData;
- (NSString *)supportDirectoryPath;
- (NSString *)deviceUUID;
@end
