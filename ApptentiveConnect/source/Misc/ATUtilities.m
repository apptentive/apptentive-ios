//
//  ATUtilities.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/19/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ATUtilities.h"
#import <QuartzCore/QuartzCore.h>
#if TARGET_OS_MAC
#import <Carbon/Carbon.h>
#import <SystemConfiguration/SystemConfiguration.h>
#endif

#define KINDA_EQUALS(a, b) (fabs(a - b) < 0.1)

@implementation ATUtilities

#if TARGET_OS_IPHONE
// From QA1703:
// http://developer.apple.com/library/ios/#qa/qa1703/_index.html
+ (UIImage*)imageByTakingScreenshot {
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
    for (UIWindow *window in [[UIApplication sharedApplication] windows])  {
        if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen]) {
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

+ (UIImage *)imageByRotatingImage:(UIImage *)image byRadians:(CGFloat)radians {
    UIImage *result = nil;
    
    if (KINDA_EQUALS(radians, 0.0) || KINDA_EQUALS(radians, M_PI * 2.0)) {
        return image;
    }
    
    CGAffineTransform t = CGAffineTransformIdentity;
    CGSize size = image.size;
    BOOL onSide = NO;
    
    // Upside down, weeeee.
    if (KINDA_EQUALS(fabsf(radians), M_PI)) {
        t = CGAffineTransformTranslate(t, size.width, size.height);
        t = CGAffineTransformRotate(t, M_PI);
    // Home button on right. Image is rotated right 90 degrees.
    } else if (KINDA_EQUALS(radians, M_PI * 0.5)) {
        onSide = YES;
        size = CGSizeMake(size.height, size.width);
        t = CGAffineTransformRotate(t, M_PI * 0.5);
        t = CGAffineTransformScale(t, size.height/size.width, size.width/size.height);
        t = CGAffineTransformTranslate(t, 0.0, -size.height);
    // Home button on left. Image is rotated left 90 degrees.
    } else if (KINDA_EQUALS(radians, -1.0 * M_PI * 0.5)) {
        onSide = YES;
        size = CGSizeMake(size.height, size.width);\
        t = CGAffineTransformRotate(t, -1.0 * M_PI * 0.5);
        t = CGAffineTransformScale(t, size.height/size.width, size.width/size.height);
        t = CGAffineTransformTranslate(t, -size.width, 0.0);
    }
    
    UIGraphicsBeginImageContext(size);
    CGRect r = CGRectMake(0.0, 0.0, size.width, size.height);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (onSide) {
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextTranslateCTM(context, 0.0, -size.height);
    } else {
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextTranslateCTM(context, 0.0, -size.height);
    }
    CGContextConcatCTM(context, t);
    CGContextDrawImage(context, r, image.CGImage);
    
    result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
}

+ (CGFloat)rotationOfViewHierarchyInRadians:(UIView *)leafView {
    CGAffineTransform t = leafView.transform;
    UIView *s = leafView.superview;
    while (s && s != leafView.window) {
        t = CGAffineTransformConcat(t, s.transform);
        s = s.superview;
    }
    return atan2(t.b, t.a);
}

+ (CGAffineTransform)viewTransformInWindow:(UIWindow *)window {
    CGAffineTransform result = CGAffineTransformIdentity;
    do { // once
        if (!window) break;
        
        if ([[window rootViewController] view]) {
            CGFloat rotation = [ATUtilities rotationOfViewHierarchyInRadians:[[window rootViewController] view]];
            result = CGAffineTransformMakeRotation(rotation);
            break;
        }
        
        if ([[window subviews] count]) {
            for (UIView *v in [window subviews]) {
                if (!CGAffineTransformIsIdentity(v.transform)) {
                    result = v.transform;
                    break;
                }
            }
        }
    } while (NO);
    return result;
}
#endif

#if TARGET_OS_MAC
+ (NSString *)currentMachineName {
    OSErr err;
    char *machineName = NULL;
    err = Gestalt(gestaltUserVisibleMachineName, (SInt32 *)&machineName);
    if (err == noErr) {
        return [[[NSString alloc] initWithBytes:machineName+1 length:machineName[0] encoding:NSASCIIStringEncoding] autorelease];
    } else {
        return @"Unknown";
    }
}

+ (NSString *)currentSystemName {
    NSProcessInfo *info = [NSProcessInfo processInfo];
    return [info operatingSystemName];
}

+ (NSString *)currentSystemVersion {
    NSProcessInfo *info = [NSProcessInfo processInfo];
    return [info operatingSystemVersionString];
}

+ (NSData *)pngRepresentationOfImage:(NSImage *)image {
    CGImageRef imageRef = [image CGImageForProposedRect:NULL context:NULL hints:nil];
    CGSize size = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithCGImage:imageRef size:size];
    NSData *result = [imageRep representationUsingType:NSPNGFileType properties:nil];
    [imageRep release];
    return result;
}
#endif

+ (NSString *)stringByEscapingForURLArguments:(NSString *)string {
    CFStringRef result = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)string, NULL, (CFStringRef)@"%:/?#[]@!$&'()*+,;=", kCFStringEncodingUTF8);
    return [NSMakeCollectable(result) autorelease];
}

+ (NSString *)randomStringOfLength:(NSUInteger)length {
    static NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
    NSMutableString *result = [NSMutableString stringWithString:@""];
    for (NSUInteger i = 0; i < length; i++) {
        [result appendFormat:@"%c", [letters characterAtIndex:rand()%[letters length]]];
    }
    return result;
}

+ (void)uniquifyArray:(NSMutableArray *)array {
    NSUInteger location = [array count];
    for (NSObject *value in [array reverseObjectEnumerator]) {
        location -= 1;
        NSUInteger index = [array indexOfObject:value];
        if (index < location) {
            [array removeObjectAtIndex:location];
        }
    }
}
@end


extern CGRect ATCGRectOfEvenSize(CGRect inRect) {
    CGRect result = CGRectMake(floor(inRect.origin.x), floor(inRect.origin.y), ceil(inRect.size.width), ceil(inRect.size.height));
    
    if (fmod(result.size.width, 2.0) != 0.0) {
        result.size.width += 1.0;
    }
    if (fmod(result.size.height, 2.0) != 0.0) {
        result.size.height += 1.0;
    }
    
    return result;
}
