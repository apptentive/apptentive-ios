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
#import "ATAppConfigurationUpdater.h"
#import "ATEngagementManifestUpdater.h"
#import "ATFileAttachment.h"
#if TARGET_OS_IPHONE
#import "ATCompoundMessage.h"
#import "ATFeedbackTypes.h"
#endif

@class ATMessageCenterViewController;

extern NSString *const ATBackendBecameReadyNotification;

#define USE_STAGING 0

@class  ATAppConfiguration, ATPersonInfo, ATDeviceInfo, ATConversation;
@class ATDataManager, ATAPIRequest, ATMessageTask;

@protocol ATBackendMessageDelegate;

/*! Handles all of the backend activities, such as sending feedback. */
@interface ATBackend : NSObject <ATUpdaterDelegate
#if TARGET_OS_IPHONE
						   ,
						   NSFetchedResultsControllerDelegate, UIAlertViewDelegate
#endif
						   >

@property (strong, nonatomic) ATDeviceUpdater *deviceUpdater;
@property (strong, nonatomic) NSDictionary *currentCustomData;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;

@property (readonly, strong, nonatomic) NSString *storagePath;

@property (strong, nonatomic) UIViewController *presentedMessageCenterViewController;
@property (readonly, nonatomic) ATPersonInfo *currentPerson;
@property (readonly, nonatomic) ATDeviceInfo *currentDevice;
@property (readonly, nonatomic) ATConversation *currentConversation;
@property (readonly, nonatomic) ATAppConfiguration *appConfiguration;

@property (readonly, assign, nonatomic) BOOL hideBranding;
@property (readonly, assign, nonatomic) BOOL notificationPopupsEnabled;

- (instancetype)initWithStoragePath:(NSString *)storagePath;
- (void)startup;

/*! Message send progress. */
@property (weak, nonatomic) id<ATBackendMessageDelegate> messageDelegate;
- (void)messageTaskDidBegin:(ATMessageTask *)messageTask;
- (void)messageTask:(ATMessageTask *)messageTask didProgress:(float)progress;
- (void)messageTaskDidFinish:(ATMessageTask *)messageTask;
- (void)messageTaskDidFail:(ATMessageTask *)messageTask;

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
- (BOOL)isUpdatingPerson;
- (void)updatePersonIfNeeded;
- (void)saveConversation;

- (NSURLCache *)imageCache;

@end

@protocol ATBackendMessageDelegate <NSObject>

- (void)backend:(ATBackend *)backend messageProgressDidChange:(float)progress;

@end
