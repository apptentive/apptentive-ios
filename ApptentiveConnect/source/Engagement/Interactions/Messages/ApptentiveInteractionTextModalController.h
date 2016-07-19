//
//  ApptentiveInteractionTextModalController.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 1/27/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveInteractionController.h"

typedef void (^alertActionHandler)(UIAlertAction *);


@interface ApptentiveInteractionTextModalController : ApptentiveInteractionController <UIAlertViewDelegate>
@end
