//
//  ATConnect.m
//  wowie-sdk
//
//  Created by Andrew Wooster on 3/12/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import "ATConnect.h"
#import <QuartzCore/QuartzCore.h>
#import "ATFeedback.h"
#import "ATFeedbackController.h"

@implementation ATConnect

// From QA1703:
// http://developer.apple.com/library/ios/#qa/qa1703/_index.html
+ (UIImage*)screenshot {
    // Create a graphics context with the target size
    // On iOS 4 and later, use UIGraphicsBeginImageContextWithOptions to take the scale into consideration
    // On iOS prior to 4, fall back to use UIGraphicsBeginImageContext
    CGSize imageSize = [[UIScreen mainScreen] bounds].size;
    if (NULL != UIGraphicsBeginImageContextWithOptions)
        UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    else
        UIGraphicsBeginImageContext(imageSize);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Iterate over every window from back to front
    for (UIWindow *window in [[UIApplication sharedApplication] windows]) 
    {
        if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen])
        {
            CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
            // -renderInContext: renders in the coordinate space of the layer,
            // so we must first apply the layer's geometry to the graphics context
            CGContextSaveGState(context);
            // Center the context around the window's anchor point
            CGContextTranslateCTM(context, [window center].x, [window center].y);
            // Apply the window's transform about the anchor point
            CGContextConcatCTM(context, [window transform]);
            // Offset by the portion of the bounds left of and above the anchor point
            CGContextTranslateCTM(context,
                                  -[window bounds].size.width * [[window layer] anchorPoint].x,
                                  -[window bounds].size.height * [[window layer] anchorPoint].y - applicationFrame.origin.y);
            
            // Render the layer hierarchy to the current context
            [[window layer] renderInContext:context];
            
            // Restore the context
            CGContextRestoreGState(context);
        }
    }
    
    // Retrieve the screenshot image
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

+ (void)presentFeedbackControllerFromViewController:(UIViewController *)viewController {
    UIImage *screenshot = [ATConnect screenshot];
    ATFeedbackController *vc = [[ATFeedbackController alloc] init];
    vc.feedback = [[[ATFeedback alloc] init] autorelease];
    vc.feedback.screenshot = screenshot;
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [viewController presentModalViewController:nc animated:YES];
    } else {
        nc.modalPresentationStyle = UIModalPresentationFormSheet;
        [viewController presentModalViewController:nc animated:YES];
    }
    [nc release];
    [vc release];
}

+ (NSBundle *)resourceBundle {
    NSBundle *bundle = [[NSBundle alloc] initWithPath:@"ApptentiveResources.bundle"];
    NSLog(@"bundle is: %@", bundle);
    return [bundle autorelease];
}
@end
