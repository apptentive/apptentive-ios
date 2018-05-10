//
//  ApptentiveDispatchTask+Internal.h
//  Apptentive
//
//  Created by Alex Lementuev on 2/22/18.
//  Copyright © 2018 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveDispatchTask.h"

@interface ApptentiveDispatchTask (Internal)

- (void)executeTask;
- (void)setScheduled:(BOOL)scheduled;
- (void)setCancelled:(BOOL)cancelled;

@end
