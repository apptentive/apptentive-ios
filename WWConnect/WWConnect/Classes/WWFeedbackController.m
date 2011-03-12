//
//  WWFeedbackController.m
//  wowie-sdk
//
//  Created by Andrew Wooster on 3/12/11.
//  Copyright 2011 Uncorked Apps LLC. All rights reserved.
//

#import "WWFeedbackController.h"

@interface WWFeedbackController (Private)
- (void)setup;
- (void)teardown;
@end

@implementation WWFeedbackController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc {
    [self teardown];
    [feedbackCell release];
    [nameCell release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}

- (void)viewDidUnload {
    [self teardown];
    [feedbackCell release];
    feedbackCell = nil;
    [nameCell release];
    nameCell = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}
@end


@implementation WWFeedbackController (Private)
- (void)setup {
    
}

- (void)teardown {
    [tableView release];
    tableView = nil;
}
@end
