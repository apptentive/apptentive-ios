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
#import "ApptentiveSerialNetworkQueue.h"
#import "ApptentiveSession.h"


@class ApptentiveConversation, ApptentiveEngagementManifest, ApptentiveAppConfiguration, ApptentiveMessageCenterViewController;

@protocol ATBackendMessageDelegate;

/**
 `ApptentiveBackend` contains the internals of the Apptentive SDK.
 Only a single backend object will be created by the Apptentive singleton
 at the time that the API key is set.
 
 It comprises a session object, containing all of the data collected
 about the user, device, app, SDK, and events and interactions that have 
 been engaged. 
 
 Additionally it manages a concurrent and a serial network queue. The
 former is used for GET requests (incoming messages, configuration, etc.)
 as well as for the initial conversation creation request. The latter is
 used for PUT and POST requests (person/device updates, events, messages,
 and survey responses).
 */
@interface ApptentiveBackend : NSObject <NSFetchedResultsControllerDelegate, ApptentiveSessionDelegate, ApptentiveRequestOperationDelegate>

@property (readonly, strong, nonatomic) ApptentiveSession *session;
@property (readonly, strong, nonatomic) ApptentiveAppConfiguration *configuration;
@property (readonly, strong, nonatomic) ApptentiveEngagementManifest *manifest;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSString *supportDirectoryPath;
@property (strong, nonatomic) UIViewController *presentedMessageCenterViewController;

@property (weak, nonatomic) id<ATBackendMessageDelegate> messageDelegate;

@property (readonly, nonatomic) NSURLCache *imageCache;


/**
 Initializes a new backend object.

 @param APIKey The Apptentive API key for the application.
 @param baseURL The base URL of the server with which the SDK communicates.
 @param storagePath The path (relative to the App's Application Support directory) to use for storage.
 @return The newly-initialized backend.
 */
- (instancetype)initWithAPIKey:(NSString *)APIKey baseURL:(NSURL *)baseURL storagePath:(NSString *)storagePath;


/**
 Instructs the serial network queue to add network operations for the currently-queued network payloads.
 */
- (void)processQueuedRecords;


/**
 Presents Message Center using the modal presentation style from the specified view controller.

 @param viewController The view controller from which to present message center
 @return <#return value description#>
 */
- (BOOL)presentMessageCenterFromViewController:(UIViewController *)viewController;
- (BOOL)presentMessageCenterFromViewController:(UIViewController *)viewController withCustomData:(NSDictionary *)customData;

- (void)attachCustomDataToMessage:(ApptentiveMessage *)message;
- (void)dismissMessageCenterAnimated:(BOOL)animated completion:(void (^)(void))completion;

- (ApptentiveMessage *)automatedMessageWithTitle:(NSString *)title body:(NSString *)body;
- (BOOL)sendAutomatedMessage:(ApptentiveMessage *)message;

- (ApptentiveMessage *)createTextMessageWithBody:(NSString *)body hiddenOnClient:(BOOL)hidden;
- (BOOL)sendTextMessageWithBody:(NSString *)body;
- (BOOL)sendTextMessageWithBody:(NSString *)body hiddenOnClient:(BOOL)hidden;
- (BOOL)sendTextMessage:(ApptentiveMessage *)message;

- (BOOL)sendImageMessageWithImage:(UIImage *)image;
- (BOOL)sendImageMessageWithImage:(UIImage *)image hiddenOnClient:(BOOL)hidden;

- (BOOL)sendFileMessageWithFileData:(NSData *)fileData andMimeType:(NSString *)mimeType;
- (BOOL)sendFileMessageWithFileData:(NSData *)fileData andMimeType:(NSString *)mimeType hiddenOnClient:(BOOL)hidden;

- (BOOL)sendCompoundMessageWithText:(NSString *)text attachments:(NSArray *)attachments hiddenOnClient:(BOOL)hidden;

- (NSString *)attachmentDirectoryPath;

- (NSUInteger)unreadMessageCount;

- (void)messageCenterEnteredForeground;
- (void)messageCenterLeftForeground;

- (BOOL)isReady;

- (void)checkForMessages;

- (void)fetchMessagesInBackground:(void (^)(UIBackgroundFetchResult))completionHandler;
- (void)completeMessageFetchWithResult:(UIBackgroundFetchResult)fetchResult;

- (void)resetBackend;

// Debugging

@property (strong, nonatomic) NSURL *localEngagementManifestURL;

@end

@protocol ATBackendMessageDelegate <NSObject>

- (void)backend:(ApptentiveBackend *)backend messageProgressDidChange:(float)progress;

@end
