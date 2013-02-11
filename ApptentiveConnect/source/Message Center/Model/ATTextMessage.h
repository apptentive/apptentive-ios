//
//  ATTextMessage.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/6/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "ATMessage.h"
#import "ATPendingMessage.h"

@interface ATTextMessage : ATMessage

@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSString * subject;

+ (ATTextMessage *)createMessageWithPendingMessage:(ATPendingMessage *)pendingMessage;
+ (void)clearComposingMessages;
@end
