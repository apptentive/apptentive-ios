//
//  ATContactStorage.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/21/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ATContactStorage.h"
#import "ATBackend.h"

#define kATContactStorageVersion 1

// Interval, in seconds, after which we'll update the contact storage from the
// server, if it hasn't been modified locally.
#define kATContactStorageUpdateInterval (60*60*24*7)

static ATContactStorage *sharedContactStorage = nil;

@interface ATContactStorage (Private)
- (void)setup;
- (void)teardown;
@end

@implementation ATContactStorage
@synthesize name, email, phone;

+ (NSString *)contactStoragePath {
    return [[[ATBackend sharedBackend] supportDirectoryPath] stringByAppendingPathComponent:@"contactinfo.objects"];
}

+ (BOOL)serializedVersionExists {
    NSFileManager *fm = [NSFileManager defaultManager];
    return [fm fileExistsAtPath:[ATContactStorage contactStoragePath]];
}


+ (ATContactStorage *)sharedContactStorage {
    @synchronized(self) {
        if (sharedContactStorage == nil) {
            if ([ATContactStorage serializedVersionExists]) {
                sharedContactStorage = [[NSKeyedUnarchiver unarchiveObjectWithFile:[ATContactStorage contactStoragePath]] retain];
            }
            if (!sharedContactStorage) {
                sharedContactStorage = [[ATContactStorage alloc] init];
            }
        }
    }
    return sharedContactStorage;
}

+ (void)releaseSharedContactStorage {
    @synchronized(self) {
        if (sharedContactStorage != nil) {
            [sharedContactStorage save];
            [sharedContactStorage release];
            sharedContactStorage = nil;
        }
    }
}

- (BOOL)shouldCheckForUpdate {
    BOOL result = YES;
    
    do { // once
        NSFileManager *fm = [NSFileManager defaultManager];
        NSString *path = [ATContactStorage contactStoragePath];
        
        if (![fm fileExistsAtPath:path]) {
            break;
        }
        
        NSError *error = nil;
        NSDictionary *attrs = [fm attributesOfItemAtPath:path error:&error];
        if (!attrs) {
            // Try to delete.
            if ([fm isDeletableFileAtPath:path]) {
                [fm removeItemAtPath:path error:&error];
            }
            break;
        }
        
        NSDate *modificationDate = [attrs fileModificationDate];
        if (!modificationDate) {
            break;
        }
        
        NSTimeInterval interval = [modificationDate timeIntervalSinceNow];
		
        if (interval <= -kATContactStorageUpdateInterval) {
            break;
        }
        result = NO;
    } while (NO);
    
    return result;
}

- (void)save {
    @synchronized(self) {
        [NSKeyedArchiver archiveRootObject:sharedContactStorage toFile:[ATContactStorage contactStoragePath]];
    }
}

- (id)initWithCoder:(NSCoder *)coder {
    if ((self = [super init])) {
        int version = [coder decodeIntForKey:@"version"];
        if (version == kATContactStorageVersion) {
            self.name = [coder decodeObjectForKey:@"name"];
            self.email = [coder decodeObjectForKey:@"email"];
            self.phone = [coder decodeObjectForKey:@"phone"];
        } else {
            [self release];
            return nil;
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt:kATContactStorageVersion forKey:@"version"];
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.email forKey:@"email"];
    [coder encodeObject:self.phone forKey:@"phone"];
}

- (void)dealloc {
    [self teardown];
    [super dealloc];
}
@end

@implementation ATContactStorage (Private)
- (void)setup {
    
}

- (void)teardown {
    self.name = nil;
    self.phone = nil;
    self.email = nil;
}
@end
