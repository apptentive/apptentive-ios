//
//  ApptentiveLogWriter.h
//  Apptentive
//
//  Created by Alex Lementuev on 10/10/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ApptentiveLogWriter : NSObject

@property (nonatomic, readonly) NSString *path;
@property (nonatomic, copy) void (^finishCallback)(ApptentiveLogWriter *writer);

- (instancetype)initWithPath:(NSString *)path;
- (void)start;
- (void)stop;

- (void)appendMessage:(NSString *)message;

@end
