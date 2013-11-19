//
//  ATLongMessageViewController.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/18/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATLongMessageViewController.h"

@interface ATLongMessageViewController ()

@end

@implementation ATLongMessageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	self.textView.text = self.text;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
	[_textView release];
	[_text release];
	[super dealloc];
}
- (void)viewDidUnload {
	[self setTextView:nil];
	[super viewDidUnload];
}
@end
