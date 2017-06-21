//
//  ApptentiveBackend.h
//  Apptentive
//
//  Created by Andrew Wooster on 3/19/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "ApptentiveMessage.h"
#import "ApptentiveConversationManager.h"
#import "ApptentiveClient.h"


@class ApptentiveConversation, ApptentiveEngagementManifest, ApptentiveAppConfiguration, ApptentiveMessageCenterViewController, ApptentiveMessageManager, ApptentivePayloadSender;

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
@interface ApptentiveBackend : NSObject <NSFetchedResultsControllerDelegate, ApptentiveConversationManagerDelegate, ApptentiveRequestOperationDelegate>

@property (readonly, strong, nonatomic) ApptentiveConversationManager *conversationManager;
@property (readonly, strong, nonatomic) ApptentiveAppConfiguration *configuration;
@property (readonly, strong, nonatomic) NSOperationQueue *operationQueue;
@property (readonly, strong, nonatomic) ApptentiveClient *client;
@property (readonly, strong, nonatomic) ApptentivePayloadSender *payloadSender;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSString *supportDirectoryPath;
@property (strong, nonatomic) UIViewController *presentedMessageCenterViewController;

@property (readonly, nonatomic) NSURLCache *imageCache;

@property (copy, nonatomic) NSDictionary *currentCustomData;
@property (copy, nonatomic) ApptentiveAuthenticationFailureCallback authenticationFailureCallback;

/**
 Initializes a new backend object.

 @param apptentiveKey The Apptentive App key for the application.
 @param signature The Apptentive App signature for the application.
 @param baseURL The base URL of the server with which the SDK communicates.
 @param storagePath The path (relative to the App's Application Support directory) to use for storage.
 @return The newly-initialized backend.
 */
- (instancetype)initWithApptentiveKey:(NSString *)apptentiveKey signature:(NSString *)signature baseURL:(NSURL *)baseURL storagePath:(NSString *)storagePath;

@property (readonly, strong, nonatomic) NSString *apptentiveKey;
@property (readonly, strong, nonatomic) NSString *apptentiveSignature;
@property (readonly, strong, nonatomic) NSURL *baseURL;
@property (readonly, strong, nonatomic) NSString *storagePath;

/**
 Instructs the serial network queue to add network operations for the currently-queued network payloads.
 */
- (void)processQueuedRecords;

- (void)migrateLegacyCoreDataAndTaskQueueForConversation:(ApptentiveConversation *)conversation;


/**
 Presents Message Center using the modal presentation style from the specified view controller.

 @param viewController The view controller from which to present message center
 @return Whether message center was displayed
 */
- (BOOL)presentMessageCenterFromViewController:(UIViewController *)viewController;
- (BOOL)presentMessageCenterFromViewController:(UIViewController *)viewController withCustomData:(NSDictionary *)customData;

- (void)dismissMessageCenterAnimated:(BOOL)animated completion:(void (^)(void))completion;

//- (NSString *)attachmentDirectoryPath;

- (NSUInteger)unreadMessageCount;

- (void)messageCenterEnteredForeground;
- (void)messageCenterLeftForeground;

- (BOOL)isReady;

- (void)schedulePersonUpdate;
- (void)scheduleDeviceUpdate;

- (void)resetBackend;

@end
