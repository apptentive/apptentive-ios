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
	if (@available(iOS 10.0, *)) {
		[UIApplication.sharedApplication openURL:url options:@{} completionHandler:completion];
	} else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
		BOOL result = [UIApplication.sharedApplication openURL:url];
#pragma clang diagnostic pop
		if (completion) {
			completion(result);
		}
	}
}

@end
