//
//  ApptentiveLog.h
//  Apptentive
//
//  Created by Alex Lementuev on 3/29/17.
//  Copyright (c) 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ApptentiveLogTag.h"

typedef enum : NSUInteger {
    ApptentiveLogLevelCrit    = 0,
    ApptentiveLogLevelError   = 1,
    ApptentiveLogLevelWarn    = 2,
    ApptentiveLogLevelInfo    = 3,
    ApptentiveLogLevelDebug   = 4,
    ApptentiveLogLevelVerbose = 5
} ApptentiveLogLevel;

#define ApptentiveLogTagConversation [ApptentiveLogTag conversationTag]

extern void ApptentiveLogSetLevel(ApptentiveLogLevel level);
void _ApptentiveLogHelper(ApptentiveLogLevel level, id arg, ...);

#define ApptentiveLogCrit(...)    _ApptentiveLogHelper(ApptentiveLogLevelCrit, __VA_ARGS__)
#define ApptentiveLogError(...)   _ApptentiveLogHelper(ApptentiveLogLevelError, __VA_ARGS__)
#define ApptentiveLogWarning(...) _ApptentiveLogHelper(ApptentiveLogLevelWarn, __VA_ARGS__)
#define ApptentiveLogInfo(...)    _ApptentiveLogHelper(ApptentiveLogLevelInfo, __VA_ARGS__)
#define ApptentiveLogDebug(...)   _ApptentiveLogHelper(ApptentiveLogLevelDebug, __VA_ARGS__)
#define ApptentiveLogVerbose(...) _ApptentiveLogHelper(ApptentiveLogLevelVerbose, __VA_ARGS__)
