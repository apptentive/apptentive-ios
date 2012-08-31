//
//  ATTask.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/20/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ATTask : NSObject <NSCoding> {
@private
	BOOL inProgress;
	BOOL finished;
	BOOL failed;
	NSUInteger failureCount;
	NSString *lastErrorTitle;
	NSString *lastErrorMessage;
}
@property (nonatomic, assign) BOOL inProgress;
@property (nonatomic, assign) BOOL finished;
@property (nonatomic, assign) BOOL failed;
@property (nonatomic, assign) NSUInteger failureCount;

@property (nonatomic, retain) NSString *lastErrorTitle;
@property (nonatomic, retain) NSString *lastErrorMessage;

- (BOOL)canStart;
- (BOOL)shouldArchive;
- (void)start;
- (void)stop;
- (float)percentComplete;
- (NSString *)taskName;
@end
