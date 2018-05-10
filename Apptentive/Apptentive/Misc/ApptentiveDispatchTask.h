//
//  ApptentiveDispatchTask.h
//  Apptentive
//
//  Created by Alex Lementuev on 2/22/18.
//  Copyright © 2018 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ApptentiveDispatchTask : NSObject

@property (atomic, readonly) BOOL scheduled;
@property (atomic, readonly) BOOL cancelled;

- (void)execute;

@end
