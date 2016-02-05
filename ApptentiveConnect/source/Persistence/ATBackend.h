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
#import <CoreData/CoreData.h>

#import "ATConversationUpdater.h"
#import "ATDeviceUpdater.h"
#import "ATPersonUpdater.h"
#import "ATFileAttachment.h"
#if TARGET_OS_IPHONE
#import "ATCompoundMessage.h"
#import "ATFeedbackTypes.h"
#endif

@class ATMessageCenterViewController;

extern NSString *const ATBackendBecameReadyNotification;

#define USE_STAGING 0

@class ATAppConfigurationUpdater;
@class ATDataManager;
@class ATFeedback;
@class ATAPIRequest;
@class ATMessageTask;

@protocol ATBackendMessageDelegate;

/*! Handles all of the backend activities, such as sending feedback. */
@interface ATBackend : NSObject <ATConversationUpdaterDelegate, ATDeviceUpdaterDelegate, ATPersonUpdaterDelegate
#if TARGET_OS_IPHONE
						   ,
						   NSFetchedResultsControllerDelegate, UIAlertViewDelegate
#endif
						   >
@property (copy, nonatomic) NSString *apiKey;
/*! The feedback currently being worked on by the user. */
@property (strong, nonatomic) ATFeedback *currentFeedback;
@property (strong, nonatomic) NSDictionary *currentCustomData;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSString *supportDirectoryPath;
@property (strong, nonatomic) UIViewController *presentedMessageCenterViewController;

@property (readonly, assign, nonatomic) BOOL hideBranding;
@property (readonly, assign, nonatomic) BOOL notificationPopupsEnabled;

/*! Message send progress. */
@property (weak, nonatomic) id<ATBackendMessageDelegate> messageDelegate;
- (void)messageTaskDidBegin:(ATMessageTask *)messageTask;
- (void)messageTask:(ATMessageTask *)messageTask didProgress:(float)progress;
- (void)messageTaskDidFinish:(ATMessageTask *)messageTask;
- (void)messageTaskDidFail:(ATMessageTask *)messageTask;

+ (ATBackend *)sharedBackend;
#if TARGET_OS_IPHONE
+ (UIImage *)imageNamed:(NSString *)name;
- (BOOL)presentMessageCenterFromViewController:(UIViewController *)viewController;
- (BOOL)presentMessageCenterFromViewController:(UIViewController *)viewController withCustomData:(NSDictionary *)customData;
- (void)messageCenterWillDismiss:(ATMessageCenterViewController *)messageCenter;

- (void)attachCustomDataToMessage:(ATCompoundMessage *)message;
- (void)dismissMessageCenterAnimated:(BOOL)animated completion:(void (^)(void))completion;
#elif TARGET_OS_MAC
+ (NSImage *)imageNamed:(NSString *)name;
#endif

/*! ATAutomatedMessage messages. */
- (ATCompoundMessage *)automatedMessageWithTitle:(NSString *)title body:(NSString *)body;
- (BOOL)sendAutomatedMessage:(ATCompoundMessage *)message;

/*! Send ATTextMessage messages. */
- (ATCompoundMessage *)createTextMessageWithBody:(NSString *)body hiddenOnClient:(BOOL)hidden;
- (BOOL)sendTextMessageWithBody:(NSString *)body;
- (BOOL)sendTextMessageWithBody:(NSString *)body hiddenOnClient:(BOOL)hidden;
- (BOOL)sendTextMessage:(ATCompoundMessage *)message;
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

- (NSString *)distributionName;
- (NSString *)distributionVersion;

- (NSUInteger)unreadMessageCount;

- (void)messageCenterEnteredForeground;
- (void)messageCenterLeftForeground;

- (NSString *)appName;

- (BOOL)isReady;

- (void)checkForMessages;

- (void)fetchMessagesInBackground:(void (^)(UIBackgroundFetchResult))completionHandler;
- (void)completeMessageFetchWithResult:(UIBackgroundFetchResult)fetchResult;

/*! True if the backend is currently updating the person. */
- (BOOL)isUpdatingPerson;

- (void)updatePersonIfNeeded;

- (NSURLCache *)imageCache;

@end

@protocol ATBackendMessageDelegate <NSObject>

- (void)backend:(ATBackend *)backend messageProgressDidChange:(float)progress;

@end
