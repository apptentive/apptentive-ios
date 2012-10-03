//
//  ATMessage.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	ATMessageTypeUnknown,
	ATMessageTypeText,
	ATMessageTypeShareRequest,
	ATMessageTypeUpgradeRequest,
} ATMessageType;

typedef enum {
	ATMessageDisplayTypeUnknown,
	ATMessageDisplayTypeModal,
	ATMessageDisplayTypeMessageCenter,
} ATMessageDisplayType;

@interface ATMessage : NSObject <NSCoding> {
	NSString *apptentiveID;
	NSTimeInterval creationTime;
	NSString *senderID;
	NSString *recipientID;
	NSNumber *priority;
	NSMutableArray *displayTypes;
}
@property (nonatomic, assign) ATMessageType messageType;
@property (nonatomic, retain) NSString *apptentiveID;
@property (nonatomic, assign) NSTimeInterval creationTime;
@property (nonatomic, retain) NSString *senderID;
@property (nonatomic, retain) NSString *recipientID;
@property (nonatomic, retain) NSNumber *priority;
@property (nonatomic, readonly) NSArray *displayTypes;

- (BOOL)isOfMessageDisplayType:(ATMessageDisplayType)displayType;
@end
