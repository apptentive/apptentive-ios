//
//  ApptentiveMessageCenterViewController.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 5/20/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ApptentiveMessageCenterDataSource.h"
#import "ApptentiveBackend.h"

@class ApptentiveMessageCenterInteraction, ApptentiveInteractionController;


@interface ApptentiveMessageCenterViewController : UITableViewController <ApptentiveMessageCenterDataSourceDelegate, UITextViewDelegate, UITextFieldDelegate, ATBackendMessageDelegate, UIActionSheetDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

+ (void)resetPreferences;

@property (strong, nonatomic) ApptentiveMessageCenterInteraction *interaction;

// This strong reference makes sure the interaction controller sticks around
// until the view controller is dismissed (required for
// `-dismissAllInteractions:` calls).
@property (strong, nonatomic) ApptentiveInteractionController *interactionController;

@end
