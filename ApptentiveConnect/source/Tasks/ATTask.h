//
//  ATTask.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/20/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ATTask : NSObject <NSCoding> {
}
@property (nonatomic, assign) BOOL finished;
@property (nonatomic, assign) BOOL failed;
@property (nonatomic, assign) NSUInteger failureCount;
- (void)start;
- (void)stop;
@end
