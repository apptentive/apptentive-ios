//
//  ATMessageCenterViewController.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 5/20/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ATMessageCenterDataSource.h"
#import "ATBackend.h"

@class ATMessageCenterInteraction;

@interface ATMessageCenterViewController : UITableViewController <ATMessageCenterDataSourceDelegate, UITextViewDelegate, UITextFieldDelegate, ATBackendMessageDelegate, UIActionSheetDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) ATMessageCenterInteraction *interaction;

@end
