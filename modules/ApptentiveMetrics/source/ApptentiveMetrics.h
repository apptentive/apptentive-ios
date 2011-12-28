//
//  ApptentiveMetrics.h
//  ApptentiveMetrics
//
//  Created by Andrew Wooster on 12/27/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ApptentiveMetrics : NSObject {
@private
	NSMutableArray *queuedMetrics;
}
+ (id)sharedMetrics;
@end

