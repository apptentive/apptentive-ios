//
//  ApptentiveAssert.h
//  Apptentive
//
//  Created by Alex Lementuev on 3/20/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 * @define ApptentiveAssertNil(expression, ...)
 * Generates a failure when ((\a expression) != nil).
 * @param expression An expression of id type.
 * @param ... An optional supplementary description of the failure. A literal NSString, optionally with string format specifiers. This parameter can be completely omitted.
 */
#define ApptentiveAssertNil(expression, ...)

/*!
 * @define ApptentiveAssertNotNil(expression, ...)
 * Generates a failure when ((\a expression) == nil).
 * @param expression An expression of id type.
 * @param ... An optional supplementary description of the failure. A literal NSString, optionally with string format specifiers. This parameter can be completely omitted.
 */
#define ApptentiveAssertNotNil(expression, ...)

/*!
 * @define ApptentiveAssertTrue(expression, ...)
 * Generates a failure when ((\a expression) == false).
 * @param expression An expression of boolean type.
 * @param ... An optional supplementary description of the failure. A literal NSString, optionally with string format specifiers. This parameter can be completely omitted.
 */
#define ApptentiveAssertTrue(expression, ...)

/*!
 * @define ApptentiveAssertDispatchQueue(expression, ...)
 * Generates a failure when ((\a expression1) does not match the current dispatch queue.
 * @param expression An expression of dispatch_queue_t type.
 * @param ... An optional supplementary description of the failure. A literal NSString, optionally with string format specifiers. This parameter can be completely omitted.
 */
#define ApptentiveAssertDispatchQueue(expression, ...)
