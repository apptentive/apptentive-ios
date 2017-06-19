//
//  NSMutableData+Types.h
//  Apptentive
//
//  Created by Alex Lementuev on 6/15/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface NSMutableData (Strings)

- (void)apptentive_appendString:(NSString *)string;
- (void)apptentive_appendFormat:(NSString *)format, ...;

@end

NS_ASSUME_NONNULL_END
