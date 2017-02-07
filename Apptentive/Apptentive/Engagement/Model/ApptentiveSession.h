//
//  ApptentiveSession.h
//  Apptentive
//
//  Created by Frank Schmitt on 11/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveState.h"

@class ApptentivePerson, ApptentiveDevice, ApptentiveSDK, ApptentiveAppRelease, ApptentiveEngagement, ApptentiveMutablePerson, ApptentiveMutableDevice, ApptentiveVersion;
@protocol ApptentiveSessionDelegate;

/**
 An `ApptentiveSession` object stores data related to a user session. It is
 intended to encompass all of the data necessary for an invocation to determine
 whether an interaction should be shown.
 
 In the most typical case, the session object will be unarchived from disk. 
 
 If older session data (stored primarily in `NSUserDefaults`) is present, it
 can be migrated using the `-initAndMigrate` method. 
 
 Finally, if this is a fresh installation of the SDK, the `-initWithAPIKey:`
 method should be used.
*/
@interface ApptentiveSession : ApptentiveState

/**
 The `ApptentiveAppRelease` object for this session.
 */
@property (readonly, nonatomic) ApptentiveAppRelease *appRelease;

/**
 The `ApptentiveSDK` object for this session.
 */
@property (readonly, nonatomic) ApptentiveSDK *SDK;

/**
 The `ApptentivePerson` object for this session.
 */
@property (readonly, nonatomic) ApptentivePerson *person;

/**
 The `ApptentiveDevice` object for this session.
 */
@property (readonly, nonatomic) ApptentiveDevice *device;

/**
 The `ApptentiveEngagement` object for this session.
 */
@property (readonly, nonatomic) ApptentiveEngagement *engagement;

/**
 The API key used to initialize the session.
 */
@property (readonly, nonatomic) NSString *APIKey;

/**
 The authorization token obtained when creating the conversation.
 */
@property (readonly, nonatomic) NSString *token;

/**
 The identifier for the last message downloaded from the conversation.
 */
@property (readonly, nonatomic) NSString *lastMessageID;

/**
 The current time. Subclasses can override this for testing purposes.
 */
@property (readonly, nonatomic) NSDate *currentTime;

/**
 Freeform key-value data used for things `NSUserDefaults` would typically be
 used for in an app.
 */
@property (readonly, nonatomic) NSDictionary *userInfo;

/**
 The delegate for the session.
 */
@property (weak, nonatomic) id<ApptentiveSessionDelegate> delegate;

/**
 Creates a new `ApptentiveSession` object, using the specified API key.

 @param APIKey The Apptentive API key to be used for the session.
 @return The newly-initialized session object.
 */
- (instancetype)initWithAPIKey:(NSString *)APIKey;


/**
 This method is called when a conversation request completes, which specifies
 the identifiers for the person and device along with the token that will be
 used to authorize subsequent network requests.

 @param token The token to be used to authorize future network requests.
 @param personID The idenfier for the person associated with this session.
 @param deviceID The idenfier for the device associated with this session.
 */
- (void)setToken:(NSString *)token personID:(NSString *)personID deviceID:(NSString *)deviceID;


/**
 This method will compare the current app release, SDK, and device information
 match that which is stored in the session. 
 
 If there are differences, the delegate is notified accordingly.
 
 Additionally, the counts for the current version or build in the engagement
 data are reset if the version or build has changed. 
 */
- (void)checkForDiffs;


/**
 Makes a batch of changes to the session's person object.
 The updated person object is then compared to the previous version, and the
 delegate is notified of any differences.

 @param personUpdateBlock A block accepting a `ApptentiveMutablePerson`
 parameter which it modifies before returning.
 */
- (void)updatePerson:(void (^)(ApptentiveMutablePerson *))personUpdateBlock;


/**
 Makes a batch of changes to the session's device object.
 The updated device object is then compared to the previous version, and the
 delegate is notified of any differences.

 @param deviceUpdateBlock A block accepting a `ApptentiveMutableDevice`
 parameter which it modifies before returning.
 */
- (void)updateDevice:(void (^)(ApptentiveMutableDevice *))deviceUpdateBlock;


/**
 This method should be called when the developer has made changes to the 
 styling of the Apptentive SDK.
 */
- (void)didOverrideStyles;


/**
 This method shoud be called to track the identifer of the last downloaded
 message.

 @param lastMessageID The identifier of the last downloaded message.
 */
- (void)didDownloadMessagesUpTo:(NSString *)lastMessageID;


/**
 A dictionary representing the data needed to create a conversation object in
 a format suitable for encoding in JSON.
 */
@property (readonly, nonatomic) NSDictionary *conversationCreationJSON;

/**
 A dictionary representing the data needed to update a conversation object in
 a format suitable for encoding in JSON.
 */
@property (readonly, nonatomic) NSDictionary *conversationUpdateJSON;


/**
 Sets free-form user info on the session object.

 @param object The object to be set or updated
 @param key The key representing the object
 */
- (void)setUserInfo:(NSObject *)object forKey:(NSString *)key;


/**
 Clears free-form user info on the session object

 @param key The key representing the object.
 */
- (void)removeUserInfoForKey:(NSString *)key;

@end


/**
 The `ApptentiveLegacyConversation` object is used to unarchive data for
 migrating from older (<= 3.4.x) versions of the Apptentive SDK.
 */
@interface ApptentiveLegacyConversation : NSObject <NSCoding>


/**
 The token used to authorize requests to the Apptentive SDK once the
 conversation has been created.
 */
@property (readonly, nonatomic) NSString *token;


/**
 The indentifier for the person associated with this session on the server.
 */
@property (readonly, nonatomic) NSString *personID;


/**
 The identifier for the device associated with this session on the server.
 */
@property (readonly, nonatomic) NSString *deviceID;

@end


/**
 The `ApptentiveSessionDelegate` protocol is used to communicate updates to the
 person, device, and conversation objects, and user info. These updates are
 intended to be communicated to the Apptentive server, or in the case of user
 info, saved locally.
 */
@protocol ApptentiveSessionDelegate <NSObject>


/**
 Indicates that the conversation object (comprised of the app release and SDK
 objects) has changed.

 @param session The session associated with the change.
 @param payload A dictionary suitable for encoding as JSON and sending to the
 server.
 */
- (void)session:(ApptentiveSession *)session conversationDidChange:(NSDictionary *)payload;


/**
 Indicates that the device object has changed.

 @param session The session associated with the change.
 @param diffs A dictionary suitable for encoding as JSON and sending to the
 server.
 */
- (void)session:(ApptentiveSession *)session deviceDidChange:(NSDictionary *)diffs;


/**
 Indicates that the person object has changed.

 @param session The session associated with the change.
 @param diffs A dictionary suitable for encoding as JSON and sending to the
 server.
 */
- (void)session:(ApptentiveSession *)session personDidChange:(NSDictionary *)diffs;


/**
 Indicates that the user info has changed

 @param session The session associated with the change.
 */
- (void)sessionUserInfoDidChange:(ApptentiveSession *)session;

@end
