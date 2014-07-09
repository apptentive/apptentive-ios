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
#if TARGET_OS_IPHONE
#import "ATMessageCenterViewController.h"
#import "ATMessageCenterV7ViewController.h"
#import "ATMessagePanelViewController.h"
#endif

NSString *const ATBackendBecameReadyNotification;

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
> {
@private
	NSString *apiKey;
	ATFeedback *currentFeedback;
	BOOL networkAvailable;
	BOOL apiKeySet;
	BOOL shouldStopWorking;
	BOOL working;
	
	ATConversationUpdater *conversationUpdater;
	ATDeviceUpdater *deviceUpdater;
	ATPersonUpdater *personUpdater;
	
	NSTimer *messageRetrievalTimer;
	ATDataManager *dataManager;
#if TARGET_OS_IPHONE
	NSFetchedResultsController *unreadCountController;
	NSInteger previousUnreadCount;
#endif
}
@property (nonatomic, copy) NSString *apiKey;
/*! The feedback currently being worked on by the user. */
@property (nonatomic, retain) ATFeedback *currentFeedback;
@property (nonatomic, retain) NSDictionary *currentCustomData;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;

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
- (void)presentIntroDialogWithInteraction:(ATInteraction *)interaction fromViewController:(UIViewController *)viewController;

#elif TARGET_OS_MAC
+ (NSImage *)imageNamed:(NSString *)name;
#endif

/*! Use this to add the feedback to a queue of feedback tasks which
    will be sent in the background. */
- (void)sendFeedback:(ATFeedback *)feedback;

/*! Send ATAutomatedMessage messages. */
- (void)sendAutomatedMessageWithTitle:(NSString *)title body:(NSString *)body;

/*! Send ATTextMessage messages. */
- (BOOL)sendTextMessageWithBody:(NSString *)body completion:(void (^)(NSString *pendingMessageID))completion;
- (BOOL)sendTextMessageWithBody:(NSString *)body hiddenOnClient:(BOOL)hidden completion:(void (^)(NSString *pendingMessageID))completion;

/*! Send ATFileMessage messages. */
- (BOOL)sendImageMessageWithImage:(UIImage *)image fromSource:(ATFeedbackImageSource)imageSource;
- (BOOL)sendImageMessageWithImage:(UIImage *)image hiddenOnClient:(BOOL)hidden fromSource:(ATFeedbackImageSource)imageSource;

- (BOOL)sendFileMessageWithFileData:(NSData *)fileData andMimeType:(NSString *)mimeType fromSource:(ATFIleAttachmentSource)source;
- (BOOL)sendFileMessageWithFileData:(NSData *)fileData andMimeType:(NSString *)mimeType hiddenOnClient:(BOOL)hidden fromSource:(ATFIleAttachmentSource)source;

- (NSString *)supportDirectoryPath;

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

/*! True if the backend is currently updating the person. */
- (BOOL)isUpdatingPerson;

- (NSURLCache *)imageCache;
@end
