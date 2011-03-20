//
//  ATUtilities.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/19/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ATUtilities : NSObject {
    
}
+ (UIImage *)imageByTakingScreenshot;
+ (NSString *)stringByEscapingForURLArguments:(NSString *)string;
@end
