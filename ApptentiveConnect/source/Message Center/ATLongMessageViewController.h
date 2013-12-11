//
//  ATLongMessageViewController.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/18/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ATLongMessageViewController : UIViewController
@property (retain, nonatomic) IBOutlet UITextView *textView;
@property (copy, nonatomic) NSString *text;

@end
