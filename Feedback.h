//
//  Feedback.h
//  WowieConnect
//
//  Created by Michael Saffitz on 12/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Base.h"
#import "ObjectiveResource.h"

typedef enum {
	Feature,
	Bug
} FeedbackTypes;


@interface Feedback : Base {
	NSString *feedbackId;
    NSString *applicationId;
    NSString *deviceId;
	NSString *feedback;
    NSString *feedbackType;
}

@property (nonatomic, retain) NSString *feedbackId;
@property (nonatomic, retain) NSString *applicationId;
@property (nonatomic, retain) NSString *deviceId;
@property (nonatomic, retain) NSString *feedback;
@property (nonatomic, retain) NSString *feedbackType;

@end
