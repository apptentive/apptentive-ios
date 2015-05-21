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
#import "ATMessageCenterViewController.h"
#import "ATMessagePanelViewController.h"
#import "ATAbstractMessage.h"
#import "ATTextMessage.h"
#import "ATFeedback.h"
#endif

extern NSString *const ATBackendBecameReadyNotification;

#define USE_STAGING 0

@class ATAppConfigurationUpdater;
@class ATDataManager;
@class ATFeedback;
@class ATAPIRequest;

/*! Handles all of the backend activities, such as sending feedback. */
@interface ATBackend : NSObject <ATConversationUpdaterDelegate, ATDeviceUpdaterDelegate, ATPersonUpdaterDelegate
#if TARGET_OS_IPHONE
, NSFetchedResultsControllerDelegate, ATMessageCenterDismissalDelegate, ATMessagePanelDelegate, UIAlertViewDelegate
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

@property (nonatomic, assign, readonly) BOOL hideBranding;

+ (ATBackend *)sharedBackend;
#if TARGET_OS_IPHONE
+ (UIImage *)imageNamed:(NSString *)name;
- (void)presentMessageCenterFromViewController:(UIViewController *)viewController;
- (void)presentMessageCenterFromViewController:(UIViewController *)viewController withCustomData:(NSDictionary *)customData;
- (void)attachCustomDataToMessage:(ATAbstractMessage *)message;
- (void)dismissMessageCenterAnimated:(BOOL)animated completion:(void (^)(void))completion;
- (void)presentIntroDialogFromViewController:(UIViewController *)viewController;
- (void)presentIntroDialogFromViewController:(UIViewController *)viewController withTitle:(NSString *)title prompt:(NSString *)prompt placeholderText:(NSString *)placeholder;
#elif TARGET_OS_MAC
+ (NSImage *)imageNamed:(NSString *)name;
#endif

/*! Use this to add the feedback to a queue of feedback tasks which
    will be sent in the background. */
- (void)sendFeedback:(ATFeedback *)feedback;

/*! Send ATAutomatedMessage messages. */
- (void)sendAutomatedMessageWithTitle:(NSString *)title body:(NSString *)body;

/*! Send ATTextMessage messages. */
- (ATTextMessage *)createTextMessageWithBody:(NSString *)body hiddenOnClient:(BOOL)hidden;
- (BOOL)sendTextMessageWithBody:(NSString *)body completion:(void (^)(NSString *pendingMessageID))completion;
- (BOOL)sendTextMessageWithBody:(NSString *)body hiddenOnClient:(BOOL)hidden completion:(void (^)(NSString *pendingMessageID))completion;
- (BOOL)sendTextMessage:(ATTextMessage *)message completion:(void (^)(NSString *pendingMessageID))completion;

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
- (NSString *)initialEmailAddressForMessagePanel;

- (BOOL)isReady;

/*! True if the backend is currently updating the person. */
- (BOOL)isUpdatingPerson;

- (NSURLCache *)imageCache;
@end
