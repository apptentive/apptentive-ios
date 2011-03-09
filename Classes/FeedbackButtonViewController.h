//
//  FeedbackButtonViewController.h
//  WowieConnect
//
//  Created by Michael Saffitz on 12/20/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface FeedbackButtonViewController : UIViewController {
    UIViewController *baseViewController;
}

@property (nonatomic, retain) UIViewController *baseViewController;

- (IBAction) sendFeedback:(id)sender;
- (void) displayAtTopCenter:(CGRect)frame;
- (void) displayAtBottomCenter:(CGRect)frame;

@end
