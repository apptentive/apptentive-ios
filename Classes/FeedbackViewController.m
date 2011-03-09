//
//  FeedbackViewController.m
//  WowieConnect
//
//  Created by Michael Saffitz on 12/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "FeedbackViewController.h"
#import "WowieConnect.h"

@implementation FeedbackViewController

@synthesize feedback;
@synthesize phoneNumber;
@synthesize emailAddress;

-(IBAction) sendFeedback:(id)sender {
	NSLog(@"Creating Feedback");
	
    [[WowieConnect sharedInstanceWithAppKey:@"foo" andSecret:@"bar"] 
        recordFeedback:self.feedback.text withType:nil];
    
//	NSLog(@"Submitting Feedback");
//	
//	NSError *remoteSaveError = nil;
//	if ([fb saveRemoteWithResponse:&remoteSaveError]) {
//		NSLog(@"Saved without error");
//	} else {
//		NSLog(@"%@:%s Error saving context: %@", [self class], _cmd, [remoteSaveError localizedDescription]);
//	}
	
	[self dismissModalViewControllerAnimated:YES];
}

- (BOOL)textFieldShouldReturn: (UITextField *)textField {
	[textField resignFirstResponder];
	return NO;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    // Any new character added is passed in as the "text" parameter
    if ([text isEqualToString:@"\n"]) {
        // Be sure to test for equality using the "isEqualToString" message
        [textView resignFirstResponder];
		
        // Return FALSE so that the final '\n' character doesn't get added
        return FALSE;
    }
    // For any other character return TRUE so that the text gets added to the view
    return TRUE;
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


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
//	self.phoneNumber = [[NSUserDefaults standardUserDefaults] objectForKey: @"SBFormattedPhoneNumber"];
}

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
