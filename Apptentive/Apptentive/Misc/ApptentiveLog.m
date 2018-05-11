//
//  ApptentiveLog.m
//  Apptentive
//
//  Created by Alex Lementuev on 3/29/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveLog.h"
#import "ApptentiveDispatchQueue.h"
#import "ApptentiveAsyncLogWriter.h"

NS_ASSUME_NONNULL_BEGIN

static const NSUInteger kLogHistorySize = 2;

static ApptentiveLogLevel _logLevel = ApptentiveLogLevelInfo;
static ApptentiveAsyncLogWriter * _logWriter;
static BOOL _shouldSanitizeLogMessages;

static const char *_Nonnull _logLevelNameLookup[] = {
	"?", // ApptentiveLogLevelUndefined
	"C", // ApptentiveLogLevelCrit,
	"E", // ApptentiveLogLevelError,
	"W", // ApptentiveLogLevelWarn,
	"I", // ApptentiveLogLevelInfo,
	"D", // ApptentiveLogLevelDebug,
	"V", // ApptentiveLogLevelVerbose
};

#pragma mark -
#pragma mark Helper Functions

inline static BOOL shouldLogLevel(ApptentiveLogLevel logLevel) {
	return logLevel <= _logLevel;
}

#pragma mark -
#pragma mark Log Functions

static void _ApptentiveLogHelper(ApptentiveLogLevel level, id arg, va_list ap) {
	ApptentiveLogTag *tag = [arg isKindOfClass:[ApptentiveLogTag class]] ? arg : nil;
	if (tag != nil) {
		arg = va_arg(ap, ApptentiveLogTag *);
	}

	NSString *format = arg;
	NSString *threadName = ApptentiveGetCurrentThreadName();
	NSString *message = [[NSString alloc] initWithFormat:format arguments:ap];

	NSMutableString *fullMessage = [[NSMutableString alloc] initWithFormat:@"%s/Apptentive: ", _logLevelNameLookup[level]];
	if (threadName != nil) {
		[fullMessage appendFormat:@"[%@] ", threadName];
	}
	if (tag != nil) {
		[fullMessage appendFormat:@"[%@] ", tag.name];
	}
	[fullMessage appendString:message];

	if (shouldLogLevel(level)) {
		NSLog(@"%@", fullMessage);
	}

	if (_logWriter) {
		[_logWriter logMessage:fullMessage];
	}
}

void ApptentiveLogCrit(id arg, ...) {
	va_list ap;
	va_start(ap, arg);
	_ApptentiveLogHelper(ApptentiveLogLevelCrit, arg, ap);
	va_end(ap);
}

void ApptentiveLogError(id arg, ...) {
	va_list ap;
	va_start(ap, arg);
	_ApptentiveLogHelper(ApptentiveLogLevelError, arg, ap);
	va_end(ap);
}

void ApptentiveLogWarning(id arg, ...) {
	va_list ap;
	va_start(ap, arg);
	_ApptentiveLogHelper(ApptentiveLogLevelWarn, arg, ap);
	va_end(ap);
}

void ApptentiveLogInfo(id arg, ...) {
	va_list ap;
	va_start(ap, arg);
	_ApptentiveLogHelper(ApptentiveLogLevelInfo, arg, ap);
	va_end(ap);
}

void ApptentiveLogDebug(id arg, ...) {
	va_list ap;
	va_start(ap, arg);
	_ApptentiveLogHelper(ApptentiveLogLevelDebug, arg, ap);
	va_end(ap);
}

void ApptentiveLogVerbose(id arg, ...) {
	va_list ap;
	va_start(ap, arg);
	_ApptentiveLogHelper(ApptentiveLogLevelVerbose, arg, ap);
	va_end(ap);
}

ApptentiveLogLevel ApptentiveLogGetLevel(void) {
	return _logLevel;
}

void ApptentiveLogSetLevel(ApptentiveLogLevel level) {
	_logLevel = level;
}

BOOL ApptentiveCanLogLevel(ApptentiveLogLevel level) {
	return shouldLogLevel(level);
}

NSString *NSStringFromApptentiveLogLevel(ApptentiveLogLevel level) {
	switch (level) {
		case ApptentiveLogLevelCrit:
			return @"crit";
		case ApptentiveLogLevelWarn:
			return @"warn";
		case ApptentiveLogLevelInfo:
			return @"info";
		case ApptentiveLogLevelDebug:
			return @"debug";
		case ApptentiveLogLevelError:
			return @"error";
		case ApptentiveLogLevelVerbose:
			return @"verbose";
		default:
			return @"undefined";
	}
}

ApptentiveLogLevel ApptentiveLogLevelFromString(NSString *level) {
	if ([level isEqualToString:@"crit"]) {
		return ApptentiveLogLevelCrit;
	}
	if ([level isEqualToString:@"warn"]) {
		return ApptentiveLogLevelWarn;
	}
	if ([level isEqualToString:@"info"]) {
		return ApptentiveLogLevelInfo;
	}
	if ([level isEqualToString:@"debug"]) {
		return ApptentiveLogLevelDebug;
	}
	if ([level isEqualToString:@"error"]) {
		return ApptentiveLogLevelError;
	}
	if ([level isEqualToString:@"crit"]) {
		return ApptentiveLogLevelCrit;
	}
	if ([level isEqualToString:@"verbose"] || [level isEqualToString:@"very_verbose"]) {
		return ApptentiveLogLevelVerbose;
	}
	return ApptentiveLogLevelUndefined;
}

NSObject * _Nullable ApptentiveHideIfSanitized(NSObject * _Nullable value) {
	return value != nil && _shouldSanitizeLogMessages ? @"<HIDDEN>" : value;
}

NSDictionary *ApptentiveHideKeysIfSanitized(NSDictionary *dictionary, NSArray *sensitiveKeys) {
	if (dictionary == nil || !_shouldSanitizeLogMessages || ![dictionary isKindOfClass:[NSDictionary class]]) {
		return dictionary;
	}

	NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:dictionary.count];
	for (NSString *key in dictionary) {
		NSObject *value = dictionary[key];

		if ([value isKindOfClass:[NSDictionary class]]) {
			value = ApptentiveHideKeysIfSanitized((NSDictionary *)value, ((NSDictionary *)value).allKeys);
		} else if ([sensitiveKeys containsObject:key]) {
			value = @"<HIDDEN>";
		}

		[result setObject:value forKey:key];
	}

	return result;
}


void setShouldSanitizeApptentiveLogMessages(BOOL shouldSanitize) {
	_shouldSanitizeLogMessages = shouldSanitize;
}

void ApptentiveStartLogMonitor(NSString *logDir) {
	_logWriter = [[ApptentiveAsyncLogWriter alloc] initWithDestDir:logDir historySize:kLogHistorySize];
}

NSArray<NSString *> *ApptentiveListLogFiles(void) {
	return [_logWriter listLogFiles];
}

NS_ASSUME_NONNULL_END
