//
//  ApptentiveAssert.h
//  Apptentive
//
//  Created by Alex Lementuev on 3/20/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ApptentiveAssertionCallback)(NSString *filename, NSInteger line, NSString *message);

extern void ApptentiveSetAssertionCallback(ApptentiveAssertionCallback callback);
extern NSString * _Nullable ApptentiveGetCurrentThreadName(void);

/*!
 * @define ApptentiveAssertFail(...)
 * Generates a failure.
 * @param ... An optional supplementary description of the failure. A literal NSString, optionally with string format specifiers. This parameter can be completely omitted.
 */
#define ApptentiveAssertFail(...) __ApptentiveAssertHelper("", __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)

/*!
 * @define ApptentiveAssertNil(expression, ...)
 * Generates a failure when ((\a expression) != nil).
 * @param expression An expression of id type.
 * @param ... An optional supplementary description of the failure. A literal NSString, optionally with string format specifiers. This parameter can be completely omitted.
 */
#define ApptentiveAssertNil(expression, ...) \
	if (expression) __ApptentiveAssertHelper(#expression, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)

/*!
 * @define ApptentiveAssertNotNil(expression, ...)
 * Generates a failure when ((\a expression) == nil).
 * @param expression An expression of id type.
 * @param ... An optional supplementary description of the failure. A literal NSString, optionally with string format specifiers. This parameter can be completely omitted.
 */
#define ApptentiveAssertNotNil(expression, ...) \
	if (!(expression)) __ApptentiveAssertHelper(#expression, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)

/*!
 * @define ApptentiveAssertNotEmpty(expression, ...)
 * Generates a failure when ((\a expression).length == 0).
 * @param expression An expression of NSString type.
 * @param ... An optional supplementary description of the failure. A literal NSString, optionally with string format specifiers. This parameter can be completely omitted.
 */
#define ApptentiveAssertNotEmpty(expression, ...) \
	if (expression.length == 0) __ApptentiveAssertHelper(#expression, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)

/*!
 * @define ApptentiveAssertTrue(expression, ...)
 * Generates a failure when ((\a expression) == false).
 * @param expression An expression of boolean type.
 * @param ... An optional supplementary description of the failure. A literal NSString, optionally with string format specifiers. This parameter can be completely omitted.
 */
#define ApptentiveAssertTrue(expression, ...) \
	if (!(expression)) __ApptentiveAssertHelper(#expression, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)

/*!
 * @define ApptentiveAssertDispatchQueue(expression, ...)
 * Generates a failure when ((\a expression1) does not match the current dispatch queue.
 * @param expression An expression of dispatch_queue_t type.
 * @param ... An optional supplementary description of the failure. A literal NSString, optionally with string format specifiers. This parameter can be completely omitted.
 */
#define ApptentiveAssertOperationQueue(expression) \
	if (!(expression).isCurrent) __ApptentiveAssertHelper(#expression, __FILE__, __LINE__, __PRETTY_FUNCTION__, @"Unexpected operation queue: %@", ApptentiveGetCurrentThreadName())

/*!
 * @define ApptentiveAssertMainQueue(...)
 * Generates a failure when ((\a expression1) does not match the current dispatch queue.
 * @param expression An expression of dispatch_queue_t type.
 * @param ... An optional supplementary description of the failure. A literal NSString, optionally with string format specifiers. This parameter can be completely omitted.
 */
#define ApptentiveAssertMainQueue \
if (![NSThread isMainThread]) __ApptentiveAssertHelper("[NSThread isMainThread]", __FILE__, __LINE__, __PRETTY_FUNCTION__, @"Unexpected operation queue: %@", ApptentiveGetCurrentThreadName());

void __ApptentiveAssertHelper(const char *expression, const char *file, int line, const char *function, ...);

NS_ASSUME_NONNULL_END
