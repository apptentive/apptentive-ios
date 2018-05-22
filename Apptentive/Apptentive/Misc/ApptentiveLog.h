//
//  ApptentiveLog.h
//  Apptentive
//
//  Created by Alex Lementuev on 3/29/17.
//  Copyright (c) 2017 Apptentive, Inc. All rights reserved.
//

#import "Apptentive.h"
#import "ApptentiveLogTag.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define ApptentiveLogTagConversation [ApptentiveLogTag conversationTag]
#define ApptentiveLogTagNetwork [ApptentiveLogTag networkTag]
#define ApptentiveLogTagPayload [ApptentiveLogTag payloadTag]
#define ApptentiveLogTagUtility [ApptentiveLogTag utilityTag]
#define ApptentiveLogTagStorage [ApptentiveLogTag storageTag]
#define ApptentiveLogTagMonitor [ApptentiveLogTag logMonitorTag]
#define ApptentiveLogTagCriteria [ApptentiveLogTag criteriaTag]
#define ApptentiveLogTagInteractions [ApptentiveLogTag interactionsTag]
#define ApptentiveLogTagPush [ApptentiveLogTag pushTag]
#define ApptentiveLogTagMessages [ApptentiveLogTag messagesTag]
#define ApptentiveLogTagApptimize [ApptentiveLogTag apptimizeTag]

extern ApptentiveLogLevel ApptentiveLogGetLevel(void);
extern void ApptentiveLogSetLevel(ApptentiveLogLevel level);
extern BOOL ApptentiveCanLogLevel(ApptentiveLogLevel level);
extern NSString *NSStringFromApptentiveLogLevel(ApptentiveLogLevel level);
extern ApptentiveLogLevel ApptentiveLogLevelFromString(NSString *level);
extern NSObject * _Nullable ApptentiveHideIfSanitized(NSObject * _Nullable value);
NSDictionary *ApptentiveHideKeysIfSanitized(NSDictionary *dictionary, NSArray *sensitiveKeys);
extern void setShouldSanitizeApptentiveLogMessages(BOOL shouldSanitize);

void ApptentiveLogCrit(id arg, ...);
void ApptentiveLogError(id arg, ...);
void ApptentiveLogWarning(id arg, ...);
void ApptentiveLogInfo(id arg, ...);
void ApptentiveLogDebug(id arg, ...);
void ApptentiveLogVerbose(id arg, ...);

void ApptentiveStartLogMonitor(NSString *logDir);
NSArray<NSString *> * _Nullable ApptentiveListLogFiles(void);

NS_ASSUME_NONNULL_END
