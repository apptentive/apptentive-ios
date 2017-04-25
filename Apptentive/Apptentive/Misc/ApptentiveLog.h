//
//  ApptentiveLog.h
//  Apptentive
//
//  Created by Alex Lementuev on 3/29/17.
//  Copyright (c) 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Apptentive.h"
#import "ApptentiveLogTag.h"

#define ApptentiveLogTagConversation [ApptentiveLogTag conversationTag]
#define ApptentiveLogTagNetworking [ApptentiveLogTag networkingTag]
#define ApptentiveLogTagPayload [ApptentiveLogTag payloadTag]

extern ApptentiveLogLevel ApptentiveLogGetLevel(void);
extern void ApptentiveLogSetLevel(ApptentiveLogLevel level);

void ApptentiveLogCrit(id arg, ...);
void ApptentiveLogError(id arg, ...);
void ApptentiveLogWarning(id arg, ...);
void ApptentiveLogInfo(id arg, ...);
void ApptentiveLogDebug(id arg, ...);
void ApptentiveLogVerbose(id arg, ...);
