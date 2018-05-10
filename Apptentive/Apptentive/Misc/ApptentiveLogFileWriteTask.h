//
//  ApptentiveLogFileWriteTask.h
//  Apptentive
//
//  Created by Alex Lementuev on 2/22/18.
//  Copyright © 2018 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ApptentiveDispatchTask.h"

NS_ASSUME_NONNULL_BEGIN

@interface ApptentiveLogFileWriteTask : ApptentiveDispatchTask

- (instancetype)initWithFile:(NSString *)file buffer:(NSMutableArray<NSString *> *)buffer;

@end

NS_ASSUME_NONNULL_END
