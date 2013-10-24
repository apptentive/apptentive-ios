//
//  ATInteractionEnjoymentDialogController.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 10/24/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ATInteraction.h"

@interface ATInteractionEnjoymentDialogController : NSObject

@property (nonatomic, retain) ATInteraction *enjoymentDialogInteraction;

- (id)initWithInteraction:(ATInteraction *)interaction;

- (void)presentEnjoymentDialogFromViewController:(UIViewController *)viewController;

@end
