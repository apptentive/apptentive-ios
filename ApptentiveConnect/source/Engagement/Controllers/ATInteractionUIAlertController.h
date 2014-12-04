//
//  ATInteractionUIAlertController.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 12/1/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ATInteraction.h"

@interface ATInteractionUIAlertController : UIAlertController

+ (instancetype)alertControllerWithInteraction:(ATInteraction *)interaction;

@end
