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
#import "ATAbstractMessage.h"
#import "ATTextMessage.h"
#import "ATAutomatedMessage.h"
#import "ATFileMessage.h"
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

@protocol  ATBackendMessageDelegate;

/*! Handles all of the backend activities, such as sending feedback. */
@interface ATBackend : NSObject <ATConversationUpdaterDelegate, ATDeviceUpdaterDelegate, ATPersonUpdaterDelegate
#if TARGET_OS_IPHONE
, NSFetchedResultsControllerDelegate, UIAlertViewDelegate
#endif
>
@property (nonatomic, copy) NSString *apiKey;
/*! The feedback currently being worked on by the user. */
@property (nonatomic, strong) ATFeedback *currentFeedback;
@property (nonatomic, strong) NSDictionary *currentCustomData;
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readonly) NSString *supportDirectoryPath;
@property (nonatomic, strong) UIViewController *presentedMessageCenterViewController;

@property (nonatomic, assign, readonly) BOOL hideBranding;
@property (nonatomic, assign, readonly) BOOL notificationPopupsEnabled;

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

- (void)attachCustomDataToMessage:(ATAbstractMessage *)message;
- (void)dismissMessageCenterAnimated:(BOOL)animated completion:(void (^)(void))completion;
#elif TARGET_OS_MAC
+ (NSImage *)imageNamed:(NSString *)name;
#endif

/*! ATAutomatedMessage messages. */
- (ATAutomatedMessage *)automatedMessageWithTitle:(NSString *)title body:(NSString *)body;
- (BOOL)sendAutomatedMessage:(ATAutomatedMessage *)message;

/*! Send ATTextMessage messages. */
- (ATTextMessage *)createTextMessageWithBody:(NSString *)body hiddenOnClient:(BOOL)hidden;
- (BOOL)sendTextMessageWithBody:(NSString *)body;
- (BOOL)sendTextMessageWithBody:(NSString *)body hiddenOnClient:(BOOL)hidden;
- (BOOL)sendTextMessage:(ATTextMessage *)message;
/*! Send ATFileMessage messages. */
- (BOOL)sendImageMessageWithImage:(UIImage *)image fromSource:(ATFeedbackImageSource)imageSource;
- (BOOL)sendImageMessageWithImage:(UIImage *)image hiddenOnClient:(BOOL)hidden fromSource:(ATFeedbackImageSource)imageSource;

- (BOOL)sendFileMessageWithFileData:(NSData *)fileData andMimeType:(NSString *)mimeType fromSource:(ATFileAttachmentSource)source;
- (BOOL)sendFileMessageWithFileData:(NSData *)fileData andMimeType:(NSString *)mimeType hiddenOnClient:(BOOL)hidden fromSource:(ATFileAttachmentSource)source;

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
