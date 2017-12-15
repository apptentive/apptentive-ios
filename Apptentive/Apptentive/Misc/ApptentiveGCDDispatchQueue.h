//
//  ApptentiveGCDDispatchQueue.h
//  Apptentive
//
//  Created by Alex Lementuev on 12/4/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveDispatchQueue.h"

NS_ASSUME_NONNULL_BEGIN

@interface ApptentiveGCDDispatchQueue : ApptentiveDispatchQueue

@property (nonatomic, readonly) NSOperationQueue *queue;

- (instancetype)initWithQueue:(NSOperationQueue *)queue;

@end

NS_ASSUME_NONNULL_END
