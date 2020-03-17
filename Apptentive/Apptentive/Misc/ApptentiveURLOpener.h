//
//  ApptentiveURLOpener.h
//  Apptentive
//
//  Created by Frank Schmitt on 3/9/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ApptentiveURLOpener : NSObject

+ (void)openURL:(NSURL *)url completionHandler:(void (^ __nullable)(BOOL success))completion;

@end

NS_ASSUME_NONNULL_END
