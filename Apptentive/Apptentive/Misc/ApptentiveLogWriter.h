//
//  ApptentiveLogWriter.h
//  Apptentive
//
//  Created by Alex Lementuev on 10/10/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ApptentiveLogWriter : NSObject

- (instancetype)initWithPath:(NSString *)path;
- (void)start;
- (void)stop;

@end
