//
//  Device.m
//  WowieConnect
//
//  Created by Michael Saffitz on 1/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Device.h"
#import "Response.h"

static const int	currentVersion = 01;		// Current version

@implementation Device

@synthesize deviceId;
@synthesize udid;
@synthesize emailAddress;
@synthesize firstName;
@synthesize lastName;

+ (void)initialize
{
    if (self == [Device class])
    {
        [self setVersion: currentVersion];
    }
}

-(id)init
{
    self.udid = [UIDevice currentDevice].uniqueIdentifier;
    return self;
}

- initWithCoder: (NSCoder *)coder
{
    int	version = [coder versionForClassName:@"Device"];
    
    if ((self=[super initWithCoder:coder])) {
        if (version < currentVersion) {}
        
        self.deviceId = [coder decodeObjectForKey:@"deviceId"];
        self.udid = [coder decodeObjectForKey:@"udid"];
        self.emailAddress = [coder decodeObjectForKey:@"emailAddress"];
        self.firstName = [coder decodeObjectForKey:@"firstName"];
        self.lastName = [coder decodeObjectForKey:@"lastName"];
    }
    return self;
}

//#pragma mark Archiving
//+ (NSString*)archivePath
//{
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    
//    NSString *folder = @"~/Library/Application Support/wowie.connect/";
//    folder = [folder stringByExpandingTildeInPath];
//    
//    if ([fileManager fileExistsAtPath:folder] == NO)
//    {
//        [fileManager createDirectoryAtPath:folder 
//               withIntermediateDirectories:YES 
//                                attributes:nil
//                                     error:nil];  // TODO error checking
//    }
//    
//    return [folder stringByAppendingPathComponent:@"device.archive"];
//}

+ (Device *)createOrRetrieveDevice:(NSString*)archivePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:archivePath] == NO )
    {
        
        NSString *devicePath = [NSString stringWithFormat:@"%@%@/%@/%@%@",
                                [ObjectiveResourceConfig getRemoteSite],
                                [self getRemoteCollectionName],
                                [UIDevice currentDevice].uniqueIdentifier,
                                [self getRemoteCollectionName],
                                [self getRemoteProtocolExtension]];
        Response *res = [Connection get:devicePath];
        
        if ( [res isSuccess] ) {
            Device *device = [[Device alloc] init];
            return [device setProperties:[[Device fromXMLData:res.body] properties]];
        }
        return [[Device alloc] init];
    }
    return [NSKeyedUnarchiver unarchiveObjectWithFile:archivePath];
}

- (void)archive:(NSString*)archivePath
{
    [NSKeyedArchiver archiveRootObject:self toFile:archivePath];
}

-(BOOL)buildDevice
{
    return (([firstName length] == 0) ||
            ([lastName length] == 0) ||
            ([emailAddress length] == 0));
}

- (void) encodeWithCoder: (NSCoder *)coder
{
    [super encodeWithCoder:coder];
    [coder encodeObject:deviceId forKey:@"deviceId"];
    [coder encodeObject:udid forKey:@"udid"];
    [coder encodeObject:emailAddress forKey:@"emailAddress"];
    [coder encodeObject:firstName forKey:@"firstName"];
    [coder encodeObject:lastName forKey:@"lastName"];
}

@end
