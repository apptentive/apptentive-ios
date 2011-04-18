//
//  ATBackend.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/19/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ATContactUpdater;
@class ATFeedback;

/*! Handles all of the backend activities, such as sending feedback. */
@interface ATBackend : NSObject {
@private
    ATContactUpdater *contactUpdater;
    BOOL userDataWasUpdated;
}
@property (nonatomic, retain) NSString *apiKey;

+ (ATBackend *)sharedBackend;
+ (UIImage *)imageNamed:(NSString *)name;

- (void)sendFeedback:(ATFeedback *)feedback;
- (void)updateUserData;
- (NSString *)supportDirectoryPath;
- (NSString *)deviceUUID;
@end
