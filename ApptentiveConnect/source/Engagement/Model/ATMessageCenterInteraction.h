//
//  ATMessageCenterInteraction.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 5/22/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ATInteraction.h"

@interface ATMessageCenterInteraction : ATInteraction

+ (id)messageCenterInteractionFromInteraction:(ATInteraction *)interaction;

@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *branding;

@property (nonatomic, readonly) NSString *composerTitle;
@property (nonatomic, readonly) NSString *composerPlaceholderText;
@property (nonatomic, readonly) NSString *composerSendButtonTitle;

@property (nonatomic, readonly) NSString *greetingTitle;
@property (nonatomic, readonly) NSString *greetingBody;
@property (nonatomic, readonly) NSURL *greetingImageURL;

@property (nonatomic, readonly) NSString *statusBody;

@property (nonatomic, readonly) NSString *contextMessageBody;

@property (nonatomic, readonly) NSString *HTTPErrorTitle;
@property (nonatomic, readonly) NSString *HTTPErrorBody;
@property (nonatomic, readonly) NSString *networkErrorTitle;
@property (nonatomic, readonly) NSString *networkErrorBody;

@property (nonatomic, readonly) BOOL profileRequested;
@property (nonatomic, readonly) BOOL profileRequired;

@property (nonatomic, readonly) NSString *profileInitialTitle;
@property (nonatomic, readonly) NSString *profileInitialNamePlaceholder;
@property (nonatomic, readonly) NSString *profileInitialEmailPlaceholder;
@property (nonatomic, readonly) NSString *profileInitialSkipButtonTitle;
@property (nonatomic, readonly) NSString *profileInitialSaveButtonTitle;
@property (nonatomic, readonly) NSString *profileInitialEmailExplanation;

@property (nonatomic, readonly) NSString *profileEditTitle;
@property (nonatomic, readonly) NSString *profileEditNamePlaceholder;
@property (nonatomic, readonly) NSString *profileEditEmailPlaceholder;
@property (nonatomic, readonly) NSString *profileEditSkipButtonTitle;
@property (nonatomic, readonly) NSString *profileEditSaveButtonTitle;

@property (nonatomic, readonly) NSString *aboutText;
@property (nonatomic, readonly) NSString *aboutButtonTitle;
@property (nonatomic, readonly) NSString *privacyButtonTitle;

@end
