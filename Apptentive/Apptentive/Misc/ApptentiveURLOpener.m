//
//  ApptentiveURLOpener.m
//  Apptentive
//
//  Created by Frank Schmitt on 3/9/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveURLOpener.h"

@implementation ApptentiveURLOpener

+ (void)openURL:(NSURL *)url completionHandler:(void (^ __nullable)(BOOL success))completion {
	[UIApplication.sharedApplication openURL:url options:@{} completionHandler:completion];
}

@end
