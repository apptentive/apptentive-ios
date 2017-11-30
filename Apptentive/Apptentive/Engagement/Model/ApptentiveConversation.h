//
//  ApptentiveConversation.h
//  Apptentive
//
//  Created by Frank Schmitt on 11/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "Apptentive.h"
#import "ApptentiveAppInstall.h"
#import "ApptentiveState.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ApptentiveConversationState) {
	ApptentiveConversationStateUndefined = 0,
	ApptentiveConversationStateAnonymousPending,
	ApptentiveConversationStateLegacyPending,
	ApptentiveConversationStateAnonymous,
	ApptentiveConversationStateLoggedIn,
	ApptentiveConversationStateLoggedOut
};

extern NSString *NSStringFromApptentiveConversationState(ApptentiveConversationState state);

@class ApptentivePerson, ApptentiveDevice, ApptentiveSDK, ApptentiveAppRelease, ApptentiveEngagement, ApptentiveVersion, ApptentiveConversationMetadataItem;
@protocol ApptentiveConversationDelegate;

/**
 An `ApptentiveConversation` object stores data related to a conversation. It is
 intended to encompass all of the data necessary for an invocation to determine
 whether an interaction should be shown.
 
 In the most typical case, the conversation object will be unarchived from disk.
 
 If older conversation data (stored primarily in `NSUserDefaults`) is present,
 it can be migrated using the `-initAndMigrate` method.
 
 Finally, if this is a fresh installation of the SDK, the `-initWithAPIKey:`
 method should be used.
*/
@interface ApptentiveConversation : ApptentiveState <ApptentiveAppInstall>

/**
 Whether the conversation is anonymous, has a token, is logged in, etc.
 */
@property (readonly, nonatomic) ApptentiveConversationState state;

/**
 The `ApptentiveAppRelease` object for this conversation.
 */
@property (readonly, nonatomic) ApptentiveAppRelease *appRelease;

/**
 The `ApptentiveSDK` object for this conversation.
 */
@property (readonly, nonatomic) ApptentiveSDK *SDK;

/**
 The `ApptentivePerson` object for this conversation.
 */
@property (readonly, nonatomic) ApptentivePerson *person;

/**
 The `ApptentiveDevice` object for this conversation.
 */
@property (readonly, nonatomic) ApptentiveDevice *device;

/**
 The `ApptentiveEngagement` object for this conversation.
 */
@property (readonly, nonatomic) ApptentiveEngagement *engagement;

/**
 The authorization token obtained when creating the conversation.
 */
@property (readonly, nonatomic) NSString *token;

/**
 The identifier (obtained from server) for the conversation.
 */
@property (readonly, nonatomic) NSString *identifier;

/**
 The identifier (generated on the client) for the conversation.
 */
@property (readonly, nonatomic) NSString *localIdentifier;

/**
 The authorization token obtained when creating the conversation (for a legacy request)
 */
@property (readonly, nonatomic) NSString *legacyToken;

/**
 Optional user id for logged-in conversations.
 */
@property (readonly, nonatomic) NSString *userId;

/**
 Encryption key for sending payloads.
 */
@property (readonly, nonatomic) NSData *encryptionKey;

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
 The delegate for the conversation.
 */
@property (weak, nonatomic) id<ApptentiveConversationDelegate> delegate;

/**
 The name of the directory that contains the conversation archive. Copied from the conversation
 metadata item. The conversation manager uses this to save the conversation.
 */
@property (readonly, nonatomic) NSString *directoryName;

- (instancetype)initWithState:(ApptentiveConversationState)state;

/**
 This method will compare the current app release, SDK, and device information
 match that which is stored in the conversation. 
 
 If there are differences, the delegate is notified accordingly.
 
 Additionally, the counts for the current version or build in the engagement
 data are reset if the version or build has changed. 
 */
- (void)checkForDiffs;

/**
 Checks to see if the device differs from the last sent version, and notifies
 the delegate if so.
 */
- (void)checkForDeviceDiffs;

/**
 Checks to see if the person differs from the last sent version, and notifies
 the delegate if so.
 */
- (void)checkForPersonDiffs;

/**
 Adds the specified code point to the engagement history, having zero
 invocations and a `nil` last invoke date.

 @param codePoint The identifier for the code point.
 */
- (void)warmCodePoint:(NSString *)codePoint;


/**
 Marks the specified code point as having been engaged.

 @param codePoint The identifier for the code point.
 */
- (void)engageCodePoint:(NSString *)codePoint;


/**
 Adds the specified interaction to the engagement history, having zero
 invocations and a `nil` last invoke date.

 @param interactionIdentifier The identifier for the interaction.
 */
- (void)warmInteraction:(NSString *)interactionIdentifier;


/**
 Marks the specified interaction as having been engaged.

 @param interactionIdentifier The identifier for the interaction.
 */
- (void)engageInteraction:(NSString *)interactionIdentifier;


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
 Sets free-form user info on the conversation object.

 @param object The object to be set or updated
 @param key The key representing the object
 */
- (void)setUserInfo:(NSObject *)object forKey:(NSString *)key;


/**
 Clears free-form user info on the conversation object

 @param key The key representing the object.
 */
- (void)removeUserInfoForKey:(NSString *)key;

- (void)updateWithCurrentValues;

/**
 Checks if conversation is in active state
 */
- (BOOL)hasActiveState;

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
 The indentifier for the person associated with this conversation on the server.
 */
@property (readonly, nonatomic) NSString *personID;


/**
 The identifier for the device associated with this conversation on the server.
 */
@property (readonly, nonatomic) NSString *deviceID;

@end


/**
 The `ApptentiveconversationDelegate` protocol is used to communicate updates to the
 person, device, and conversation objects, and user info. These updates are
 intended to be communicated to the Apptentive server, or in the case of user
 info, saved locally.
 */
@protocol ApptentiveConversationDelegate <NSObject>

@optional

/**
 Indicates that the conversation object (any of its parts) has changed.
 
 @param conversation The conversation associated with the change.
 server.
 */
- (void)conversationDidChange:(ApptentiveConversation *)conversation;

/**
 Indicates that the conversation object (comprised of the app release and SDK
 objects) has changed.

 @param conversation The conversation associated with the change.
 server.
 */
- (void)conversationAppReleaseOrSDKDidChange:(ApptentiveConversation *)conversation;


/**
 Indicates that the device object has changed.

 @param conversation The conversation associated with the change.
 @param diffs A dictionary suitable for encoding as JSON and sending to the
 server.
 */
- (void)conversation:(ApptentiveConversation *)conversation deviceDidChange:(NSDictionary *)diffs;


/**
 Indicates that the person object has changed.

 @param conversation The conversation associated with the change.
 @param diffs A dictionary suitable for encoding as JSON and sending to the
 server.
 */
- (void)conversation:(ApptentiveConversation *)conversation personDidChange:(NSDictionary *)diffs;


/**
 Indicates that the user info has changed

 @param conversation The session associated with the change.
 */
- (void)conversationUserInfoDidChange:(ApptentiveConversation *)conversation;


/**
 Indicates that the engagement data has changed.

 @param conversation The conversation associated with the change.
 */
- (void)conversationEngagementDidChange:(ApptentiveConversation *)conversation;

@end


@interface ApptentiveMutableConversation : ApptentiveConversation

@property (assign, nonatomic) ApptentiveConversationState state;
@property (strong, nonatomic) NSString *token;
@property (strong, nonatomic) NSString *legacyToken;
@property (strong, nonatomic) NSString *userId;
@property (strong, nonatomic) NSData *encryptionKey;

/**
 This method is called when a conversation request completes, which specifies
 the identifiers for the person and device along with the token that will be
 used to authorize subsequent network requests.
 
 @param token The token to be used to authorize future network requests.
 @param personID The idenfier for the person associated with this conversation.
 @param deviceID The idenfier for the device associated with this conversation.
 */
- (void)setToken:(NSString *)token conversationID:(NSString *)conversationID personID:(NSString *)personID deviceID:(NSString *)deviceID;

/**
 This method is called when a conversation request completes, which specifies
 the conversation identifier along with JWT to authorize subsequent network requests.
 */
- (void)setConversationIdentifier:(NSString *)identifier JWT:(NSString *)JWT;

@end

NS_ASSUME_NONNULL_END
