//
//  ApptentiveIndentPrinter.h
//  Apptentive
//
//  Created by Frank Schmitt on 2/21/18.
//  Copyright © 2018 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ApptentiveIndentPrinter : NSObject

@property (readonly, nonatomic) NSInteger indentLevel;
@property (assign, nonatomic) NSInteger indentWidth;
@property (readonly, nonatomic) NSString *output;

- (void)indent;
- (void)outdent;

- (void)appendString:(NSString *)string;
- (void)appendFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1, 2);

@end

NS_ASSUME_NONNULL_END
