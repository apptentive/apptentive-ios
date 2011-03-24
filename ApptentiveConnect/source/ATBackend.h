//
//  ATBackend.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/19/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

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
- (void)sendFeedback:(ATFeedback *)feedback;
- (void)updateUserData;
- (NSString *)supportDirectoryPath;
- (NSString *)deviceUUID;
@end
