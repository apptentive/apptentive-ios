//
//  FeedbackButtonViewController.m
//  WowieConnect
//
//  Created by Michael Saffitz on 12/20/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "FeedbackButtonViewController.h"
#import "WowieConnect.h"


@implementation FeedbackButtonViewController

@synthesize baseViewController;

- (IBAction) sendFeedback:(id)sender {
    NSLog(@"Logging Feedback");
		
    [[WowieConnect sharedInstance] presentWowieConnectModalViewControllerForParent:baseViewController];
}

- (void) displayAtTopCenter:(CGRect)frame {
    int xPosition = (frame.size.width/ 2 ) - (self.view.frame.size.width / 2);
    self.view.frame = CGRectOffset(self.view.frame, xPosition, 0);
}

- (void) displayAtBottomCenter:(CGRect)frame {
    int xPosition = (frame.size.width/ 2 ) - (self.view.frame.size.width / 2);
    int yPosition = (frame.size.height) - (self.view.frame.size.height);
    self.view.frame = CGRectOffset(self.view.frame, xPosition, yPosition);
}


/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
