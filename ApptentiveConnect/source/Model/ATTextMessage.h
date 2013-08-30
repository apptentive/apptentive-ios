//
//  ATTextMessage.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/6/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "ATAbstractMessage.h"

@interface ATTextMessage : ATAbstractMessage

@property (nonatomic, retain) NSString *body;
@property (nonatomic, retain) NSString *title;

+ (void)clearComposingMessages;
@end
