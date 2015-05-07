//
//  ATMessageCenterViewController.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 9/28/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ATAutomatedMessageCell.h"
#import "ATFileMessageCell.h"
#import "ATMessageCenterBaseViewController.h"
#import "ATMessageCenterDataSource.h"
#import "ATMessageInputView.h"
#import "ATSimpleImageViewController.h"
#import "ATTextMessageUserCell.h"

@interface ATMessageCenterViewController : ATMessageCenterBaseViewController <ATMessageCenterDataSourceDelegate, ATMessageInputViewDelegate, UIActionSheetDelegate, UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate>
@end
