//
//  ATFeedbackTask.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/20/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ATTask.h"

@class ATWebClient;
@class ATFeedback;

@interface ATFeedbackTask : ATTask {
@private
    ATWebClient *client;
}
@property (nonatomic, retain) ATFeedback *feedback;

@end
