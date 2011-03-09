//
//  Utilities.m
//  WowieConnect
//
//  Created by Michael Saffitz on 1/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Utilities.h"


@implementation Utilities



+ (NSString *)applicationSupportFolder:(NSError **)error
{
    
    NSString *dir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
                                                          NSUserDomainMask, YES) lastObject];
    
    // TODO:  Ensure that this directory will be writable by multiple applications on the system
    // TODO:  Provide some better means of protecting this data
    //dir = [dir stringByAppendingPathComponent:[[NSProcessInfo processInfo] processName]];
    dir = [dir stringByAppendingPathComponent:@"wowie.connect"];
    
    if ( ! [[NSFileManager defaultManager] fileExistsAtPath:dir] )
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:error];
        
        
        if (error != nil)
        {
            NSLog(@"Error creating application support directory: %@", [*error code]);
            return nil;
        }
    }
    return dir;
}


@end
