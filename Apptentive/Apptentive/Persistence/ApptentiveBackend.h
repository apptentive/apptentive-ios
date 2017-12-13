//
//  ApptentiveBackend.h
//  Apptentive
//
//  Created by Andrew Wooster on 3/19/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>

#import "ApptentiveClient.h"
#import "ApptentiveConversationManager.h"
#import "ApptentiveMessage.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const ApptentiveAuthenticationDidFailNotification;
extern NSString *const ApptentiveAuthenticationDidFailNotificationKeyErrorType;
extern NSString *const ApptentiveAuthenticationDidFailNotificationKeyErrorMessage;
extern NSString *const ApptentiveAuthenticationDidFailNotificationKeyConversationIdentifier;

@class ApptentiveConversation, ApptentiveEngagementManifest, ApptentiveAppConfiguration, ApptentiveMessageCenterViewController, ApptentiveMessageManager, ApptentivePayloadSender, ApptentiveDispatchQueue;

/**
 `ApptentiveBackend` contains the internals of the Apptentive SDK.
 Only a single backend object will be created by the Apptentive singleton
 at the time that the API key is set.
 
 It comprises a conversation object, containing all of the data collected
 about the user, device, app, SDK, and events and interactions that have 
 been engaged. 
 
 Additionally it manages a concurrent and a serial network queue. The
 former is used for GET requests (incoming messages, configuration, etc.)
 as well as for the initial conversation creation request. The latter is
 used for PUT and POST requests (person/device updates, events, messages,
 and survey responses).
 */
@interface ApptentiveBackend : NSObject <NSFetchedResultsControllerDelegate, ApptentiveConversationManagerDelegate>

@property (readonly, strong, nonatomic) ApptentiveConversationManager *conversationManager;
@property (readonly, strong, nonatomic) ApptentiveAppConfiguration *configuration;
@property (readonly, strong, nonatomic) ApptentiveDispatchQueue *operationQueue;
@property (readonly, strong, nonatomic) ApptentiveClient *client;
@property (readonly, strong, nonatomic) ApptentivePayloadSender *payloadSender;
@property (readonly, nonatomic, getter=isForeground) BOOL foreground;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSString *supportDirectoryPath;
@property (strong, nullable, nonatomic) UIViewController *presentedMessageCenterViewController;

@property (copy, nullable, nonatomic) NSDictionary *currentCustomData;
@property (copy, nonatomic) ApptentiveAuthenticationFailureCallback authenticationFailureCallback;

@property (readonly, nonatomic) BOOL networkAvailable;
@property (assign, nonatomic) NSUInteger unreadMessageCount;

@property (strong, nonatomic) NSString *personName;
@property (strong, nonatomic) NSString *personEmailAddress;

/**
 Initializes a new backend object.

 @param apptentiveKey The Apptentive App key for the application.
 @param signature The Apptentive App signature for the application.
 @param baseURL The base URL of the server with which the SDK communicates.
 @param storagePath The path (relative to the App's Application Support directory) to use for storage.
 @return The newly-initialized backend.
 */
- (instancetype)initWithApptentiveKey:(NSString *)apptentiveKey signature:(NSString *)signature baseURL:(NSURL *)baseURL storagePath:(NSString *)storagePath operationQueue:(ApptentiveDispatchQueue *)operationQueue;

@property (readonly, strong, nonatomic) NSString *apptentiveKey;
@property (readonly, strong, nonatomic) NSString *apptentiveSignature;
@property (readonly, strong, nonatomic) NSURL *baseURL;
@property (readonly, strong, nonatomic) NSString *storagePath;

/**
 Instructs the serial network queue to add network operations for the currently-queued network payloads.
 */
- (void)processQueuedRecords;

- (void)migrateLegacyCoreDataAndTaskQueueForConversation:(ApptentiveConversation *)conversation conversationDirectoryPath:(NSString *)directoryPath;


/**
 Presents Message Center using the modal presentation style from the specified view controller.

 @param viewController The view controller from which to present message center
 */
- (void)presentMessageCenterFromViewController:(nullable UIViewController *)viewController completion:(void (^_Nullable)(BOOL presented))completion;
- (void)presentMessageCenterFromViewController:(nullable UIViewController *)viewController withCustomData:(nullable NSDictionary *)customData completion:(void (^_Nullable)(BOOL presented))completion;

- (void)dismissMessageCenterAnimated:(BOOL)animated completion:(void (^)(void))completion;

//- (NSString *)attachmentDirectoryPath;

- (NSUInteger)unreadMessageCount;

- (void)messageCenterEnteredForeground;
- (void)messageCenterLeftForeground;

- (void)schedulePersonUpdate;
- (void)scheduleDeviceUpdate;

@end

NS_ASSUME_NONNULL_END
