//
//  ApptentiveSerialRequest.m
//  Apptentive
//
//  Created by Frank Schmitt on 12/16/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSerialRequest.h"
#import "ApptentiveAttachment.h"
#import "ApptentiveRequestOperation.h"
#import "ApptentiveSerialRequestAttachment.h"
#import "ApptentiveConversation.h"
#import "ApptentivePayload.h"
#import "NSData+Encryption.h"
#import "ApptentiveUtilities.h"


@implementation ApptentiveSerialRequest

@dynamic apiVersion;
@dynamic attachments;
@dynamic contentType;
@dynamic conversationIdentifier;
@dynamic authToken;
@dynamic date;
@dynamic identifier;
@dynamic method;
@dynamic path;
@dynamic payload;
@dynamic encrypted;

+ (BOOL)enqueuePayload:(ApptentivePayload *)payload forConversation:(ApptentiveConversation *)conversation usingAuthToken:(nullable NSString *)authToken inContext:(NSManagedObjectContext *)context {
    ApptentiveAssertNotNil(payload, @"Attempted to enqueue nil payload");
    if (payload == nil) {
        return NO;
    }
    
	ApptentiveAssertNotNil(conversation, @"Attempted to enqueue payload with nil conversation: %@", payload);
	if (conversation == nil) {
		return NO;
	}

	ApptentiveAssertTrue(conversation.state != ApptentiveConversationStateUndefined && conversation.state != ApptentiveConversationStateLoggedOut, @"Attempted to enqueue payload with wrong conversation state (%@): %@", NSStringFromApptentiveConversationState(conversation.state), payload);
	if (conversation.state == ApptentiveConversationStateUndefined ||
		conversation.state == ApptentiveConversationStateLoggedOut) {
		return NO;
	}

	ApptentiveAssertNotNil(context, @"Managed object context is nill");
	if (context == nil) {
		ApptentiveLogError(@"Unable encode enqueue request: managed object context is nil");
		return NO;
	}
    
    // create a child context on a private concurrent queue
    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    
    // set parent context
    [childContext setParentContext:context];
    
    // execute the block on a background thread (this call returns immediatelly)
    [childContext performBlock:^{
        
        ApptentiveSerialRequest *request = (ApptentiveSerialRequest *)[[NSManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:@"QueuedRequest" inManagedObjectContext:childContext] insertIntoManagedObjectContext:childContext];
        
        ApptentiveAssertNotNil(request, @"Can't load managed request object");
        if (request == nil) {
            ApptentiveLogError(@"Unable encode enqueue request '%@': can't load managed request object", payload.path);
            return;
        }
        
        request.date = [NSDate date];
        request.path = payload.path;
        request.method = payload.method;
        request.identifier = payload.localIdentifier;
        request.conversationIdentifier = conversation.identifier;
        request.apiVersion = payload.apiVersion;
        request.authToken = authToken;
        request.contentType = @"application/json";
        request.payload = payload.payload;
        
        NSMutableArray *attachmentArray = [NSMutableArray arrayWithCapacity:payload.attachments.count];
        for (ApptentiveAttachment *attachment in payload.attachments) {
            [attachmentArray addObject:[ApptentiveSerialRequestAttachment queuedAttachmentWithName:attachment.name path:attachment.fullLocalPath MIMEType:attachment.contentType inContext:childContext]];
        }
        request.attachments = [NSOrderedSet orderedSetWithArray:attachmentArray];
        
        if (conversation.state == ApptentiveConversationStateLoggedIn) {
            ApptentiveAssertNotNil(conversation.encryptionKey, @"Encryption key is nil for a logged-in conversation!");
            
            [request encryptWithKey:conversation.encryptionKey];
        }
        
        // save child context
        NSError *saveError;
        if (![childContext save:&saveError]) {
            ApptentiveLogError(@"Unable to save temporary managed object context: %@", saveError);
        }
        
        // save parent context
        [context performBlockAndWait:^{
            NSError *parentSaveError;
            if (![context save:&parentSaveError]) {
                ApptentiveLogError(@"Unable to save parent managed object context: %@", parentSaveError);
            }
        }];
    }];

	return YES;
}

- (void)awakeFromFetch {
	if (self.conversationIdentifier.length > 0 && [self.path containsString:@"<cid>"]) {
		self.path = [self.path stringByReplacingOccurrencesOfString:@"<cid>" withString:self.conversationIdentifier];
	}
}

- (BOOL)encryptWithKey:(NSData *)key {
	NSError *error;
	NSDictionary *JSONPayload = [NSJSONSerialization JSONObjectWithData:self.payload options:0 error:&error];

	ApptentiveAssertNotNil(JSONPayload, @"Unable to read JSON-encoded payload data: %@", error);

	if (JSONPayload == nil) {
		return NO;
	}

	NSMutableDictionary *mutablePayload = [JSONPayload mutableCopy];
	mutablePayload[@"token"] = self.authToken;

	NSData *JSONPayloadWithToken = [NSJSONSerialization dataWithJSONObject:mutablePayload options:0 error:&error];

	ApptentiveAssertNotNil(JSONPayloadWithToken, @"Unable to encode payload data as JSON: %@", error);

	if (JSONPayloadWithToken == nil) {
		return NO;
	}

	NSData *encryptedPayload = [JSONPayloadWithToken apptentive_dataEncryptedWithKey:key];

	ApptentiveAssertNotNil(encryptedPayload, @"Unable to encrypt payload");
    
    // encrypt each attachments and write to a file in a form of a part of the multi-part request
    if (self.attachments.count > 0) {
        NSMutableArray *encryptedAttachments = [[NSMutableArray alloc] initWithCapacity:self.attachments.count];
        for (ApptentiveAttachment *attachment in self.attachments) {
            ApptentiveAttachment *encryptedAttachment = [self encryptedAttachment:attachment usingKey:key];
            ApptentiveAssertNotNil(encryptedAttachment, @"Unable to encrypt attachment: %@", attachment.name);
            
            if (encryptedAttachment != nil) {
                [encryptedAttachments addObject:encryptedAttachment];
            }
        }
        self.attachments = [NSOrderedSet orderedSetWithArray:encryptedAttachments];
    }

	self.payload = encryptedPayload;
	self.encrypted = YES;
	self.contentType = @"application/octet-stream";

	return self.payload != nil;
}

- (ApptentiveAttachment *)encryptedAttachment:(ApptentiveAttachment *)attachment usingKey:(NSData *)key {
    NSError *error;
    NSData *fileData = [NSData dataWithContentsOfFile:attachment.fullLocalPath options:0 error:&error];
    if (error) {
        ApptentiveLogError(@"Unable to read attachment data: %@", error);
        return nil;
    }
    
    NSMutableString *multipartHeader = [NSMutableString string];
    [multipartHeader appendString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", @"file[]", attachment.name]];
    [multipartHeader appendString:[NSString stringWithFormat:@"Content-Type: %@\r\n", attachment.contentType]];
    
    NSMutableData *multipartData = [NSMutableData new];
    [multipartData appendData:[multipartHeader dataUsingEncoding:NSUTF8StringEncoding]];
    [multipartData appendData:fileData];
    
    NSData *multipartEncryptedData = [multipartData apptentive_dataEncryptedWithKey:key];
    ApptentiveAssertNotNil(multipartEncryptedData, @"Unable to encrypt attachment multipart data");
    if (multipartEncryptedData == nil) {
        return nil;
    }
    
    #warning Delete the un-encrypted file?
    
    return [[ApptentiveAttachment alloc] initWithData:multipartEncryptedData contentType:@"application/octet-stream" name:attachment.name];
}

@end
