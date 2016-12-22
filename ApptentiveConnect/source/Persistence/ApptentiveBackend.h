//
//  ApptentiveBackend.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/19/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "ApptentiveMessage.h"
#import "ApptentiveSerialNetworkQueue.h"
#import "ApptentiveSession.h"


extern NSString *const ATBackendBecameReadyNotification;
extern NSString *const ATConfigurationPreferencesChangedNotification;

@class ApptentiveConversation, ApptentiveEngagementManifest, ApptentiveAppConfiguration, ApptentiveMessageCenterViewController;

@protocol ATBackendMessageDelegate;

/*! Handles all of the backend activities, such as sending feedback. */
@interface ApptentiveBackend : NSObject <NSFetchedResultsControllerDelegate, ApptentiveSessionDelegate, ApptentiveRequestOperationDelegate>

@property (copy, nonatomic) NSDictionary *currentCustomData;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSString *supportDirectoryPath;
@property (strong, nonatomic) UIViewController *presentedMessageCenterViewController;

@property (readonly, strong, nonatomic) NSOperationQueue *queue;
@property (readonly, strong, nonatomic) ApptentiveNetworkQueue *networkQueue;
@property (readonly, strong, nonatomic) ApptentiveSerialNetworkQueue *serialQueue;

@property (readonly, strong, nonatomic) ApptentiveAppConfiguration *configuration;
@property (readonly, strong, nonatomic) ApptentiveEngagementManifest *manifest;
@property (readonly, strong, nonatomic) ApptentiveSession *session;

- (instancetype)initWithAPIKey:(NSString *)APIKey baseURL:(NSURL *)baseURL;
- (void)processQueuedRecords;

@property (weak, nonatomic) id<ATBackendMessageDelegate> messageDelegate;

+ (UIImage *)imageNamed:(NSString *)name;
- (BOOL)presentMessageCenterFromViewController:(UIViewController *)viewController;
- (BOOL)presentMessageCenterFromViewController:(UIViewController *)viewController withCustomData:(NSDictionary *)customData;
- (void)messageCenterWillDismiss:(ApptentiveMessageCenterViewController *)messageCenter;

- (void)attachCustomDataToMessage:(ApptentiveMessage *)message;
- (void)dismissMessageCenterAnimated:(BOOL)animated completion:(void (^)(void))completion;

/*! ATAutomatedMessage messages. */
- (ApptentiveMessage *)automatedMessageWithTitle:(NSString *)title body:(NSString *)body;
- (BOOL)sendAutomatedMessage:(ApptentiveMessage *)message;

/*! Send ATTextMessage messages. */
- (ApptentiveMessage *)createTextMessageWithBody:(NSString *)body hiddenOnClient:(BOOL)hidden;
- (BOOL)sendTextMessageWithBody:(NSString *)body;
- (BOOL)sendTextMessageWithBody:(NSString *)body hiddenOnClient:(BOOL)hidden;
- (BOOL)sendTextMessage:(ApptentiveMessage *)message;
/*! Send ATFileMessage messages. */
- (BOOL)sendImageMessageWithImage:(UIImage *)image;
- (BOOL)sendImageMessageWithImage:(UIImage *)image hiddenOnClient:(BOOL)hidden;

- (BOOL)sendFileMessageWithFileData:(NSData *)fileData andMimeType:(NSString *)mimeType;
- (BOOL)sendFileMessageWithFileData:(NSData *)fileData andMimeType:(NSString *)mimeType hiddenOnClient:(BOOL)hidden;

- (BOOL)sendCompoundMessageWithText:(NSString *)text attachments:(NSArray *)attachments hiddenOnClient:(BOOL)hidden;

/*! Path to directory for storing attachments. */
- (NSString *)attachmentDirectoryPath;
- (NSString *)deviceUUID;

- (NSURL *)apptentiveHomepageURL;
- (NSURL *)apptentivePrivacyPolicyURL;

- (NSUInteger)unreadMessageCount;

- (void)messageCenterEnteredForeground;
- (void)messageCenterLeftForeground;

- (NSString *)appName;

- (BOOL)isReady;

- (void)checkForMessages;

- (void)fetchMessagesInBackground:(void (^)(UIBackgroundFetchResult))completionHandler;
- (void)completeMessageFetchWithResult:(UIBackgroundFetchResult)fetchResult;

@property (readonly, nonatomic) NSURLCache *imageCache;

// Debugging

@property (strong, nonatomic) NSURL *localEngagementManifestURL;

@end

@protocol ATBackendMessageDelegate <NSObject>

- (void)backend:(ApptentiveBackend *)backend messageProgressDidChange:(float)progress;

@end
