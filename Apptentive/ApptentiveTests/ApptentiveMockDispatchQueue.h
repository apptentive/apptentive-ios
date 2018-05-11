//
//  ApptentiveMockDispatchQueue.h
//  ApptentiveTests
//
//  Created by Alex Lementuev on 2/23/18.
//  Copyright © 2018 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ApptentiveDispatchQueue.h"

@interface ApptentiveMockDispatchQueue : ApptentiveDispatchQueue

- (instancetype)initWithRunImmediately:(BOOL)runImmediately;

- (void)dispatchTasks;

@end
