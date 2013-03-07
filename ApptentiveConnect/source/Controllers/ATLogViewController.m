//
//  ATLogViewController.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/6/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATLogViewController.h"

@implementation ATLogViewController
@synthesize textView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc {
	[textView removeFromSuperview];
	[textView release], textView = nil;
	[super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	textView = [[UITextView alloc] initWithFrame:self.view.bounds];
	[self.view addSubview:textView];
	
	self.navigationItem.title = @"Debug Logs";
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
	[textView removeFromSuperview];
	[textView release], textView = nil;
}

- (void)done:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}
@end
