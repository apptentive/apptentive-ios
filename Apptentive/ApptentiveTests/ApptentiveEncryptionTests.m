//
//  ApptentiveEncryptionTests.m
//  Apptentive
//
//  Created by Frank Schmitt on 5/1/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveEventPayload.h"
#import "ApptentiveSerialRequest.h"
#import "NSData+Encryption.h"
#import <XCTest/XCTest.h>


@interface ApptentiveEncryptionTests : XCTestCase

@property (readonly, nonatomic) NSData *key;
@property (readonly, nonatomic) NSData *initializationVector;
@property (readonly, nonatomic) NSData *ciphertext;
@property (readonly, nonatomic) NSData *plaintext;

@end


@interface ApptentiveMockSerialRequest : ApptentiveSerialRequest

@property (strong, nonatomic) NSData *synthesizedPayload;
@property (strong, nonatomic) NSString *synthesizedAuthToken;
@property (strong, nonatomic) NSString *synthesizedContentType;
@property (assign, nonatomic) BOOL synthesizedEncrypted;

@end


@implementation ApptentiveEncryptionTests

- (void)setUp {
	[super setUp];

	NSString *base64Ciphertext = @"mJHauCPEN8cpRVEVWvqSO/90tsUtiXp35PnKppc13LfVvuJqwCRFAnyiehBhnhPIFJpoXyFWxPf7U7/rmn2BykA2syeV9ALDMP+Wb6R12C+f36GhNALPOBa8204yiwO517suJ032eAG4ey4WroDN0wjegqtFSYhUsxd8PhGqT9TBgXYAKO9HwHp6khOyqhPNEu7qnGcOC98OryV0Aq0ZrrOuNFVPeNOv+YJ0H0VeJWEDl1R9dn0JOnlSFxCmoCXnIB8US7aT/IpvTxNHqrRMj7Ddp8V/CE23rB5GA4Ecov2zXrKdO1pfo1LGoYQLy0x3Vz4BbBKTH61/z7f5cfYBK7uUCpsds9BJqgNWKkTl7F+JTaDBF34wQu9kcevasjxVRWvQyWjBpsSU3YN9g0DuOZTQ/Ole4VpO9J/nAIncGwGkaKUCwZMDVgOvxyGLAgaiRjZanTWfQi42mnbU4drF+7R4LK+PmBfDaf8Z5rz64Nei8Wi5x1m/v1CY42job2UDr8yQnJnYv1tgMKnSJOrIY4jccpmoYFAiPYaQ3IoaQ9f/gO0IXoWYy1eKHYi9rKC9gY35gVhifNrtqxcZZMMGq+eeLzKjsI3+F8fiT4ErpEk=";

	_ciphertext = [[NSData alloc] initWithBase64EncodedString:base64Ciphertext options:NSDataBase64DecodingIgnoreUnknownCharacters];

	NSString *plaintextString = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.";

	_plaintext = [plaintextString dataUsingEncoding:NSUTF8StringEncoding];

	_key = [[NSData alloc] initWithBase64EncodedString:@"liKoHsRVREFSUw2xjFr0gC2RI8+BbrjAUC8lp9MDV+s=" options:NSDataBase64DecodingIgnoreUnknownCharacters];

	_initializationVector = [[NSData alloc] initWithBase64EncodedString:@"mJHauCPEN8cpRVEVWvqSOw==" options:NSDataBase64DecodingIgnoreUnknownCharacters];
}

- (void)testEncryption {
	NSData *encryptedPlainText = [self.plaintext apptentive_dataEncryptedWithKey:self.key initializationVector:self.initializationVector];

	XCTAssertEqualObjects(encryptedPlainText, self.ciphertext);
}

- (void)testDecryption {
	NSData *decryptedCipherText = [self.ciphertext apptentive_dataDecryptedWithKey:self.key];

	XCTAssertEqualObjects(decryptedCipherText, self.plaintext);
}

- (void)testKeyParsing {
	NSData *hexKeyData = [NSData apptentive_dataWithHexString:@"1234567890ABCDEF1234567890ABCDEF"];

	XCTAssertEqual(hexKeyData.length, 16);
	XCTAssertTrue([hexKeyData.description containsString:@"12345678"]);
}

@end


// This is needed because NSManagedObject subclasses need to be initialized
// in a certain way for their accessors to work. We're just alloc-initing
// for testing purposes.
@implementation ApptentiveMockSerialRequest

@synthesize synthesizedPayload = _synthesizedPayload;
@synthesize synthesizedAuthToken = _synthesizedAuthToken;
@synthesize synthesizedContentType = _synthesizedContentType;
@synthesize synthesizedEncrypted = _synthesizedEncrypted;

- (void)setAuthToken:(NSString *)authToken {
	self.synthesizedAuthToken = authToken;
}

- (NSString *)authToken {
	return self.synthesizedAuthToken;
}

- (void)setPayload:(NSData *)payload {
	self.synthesizedPayload = payload;
}

- (NSData *)payload {
	return self.synthesizedPayload;
}

- (void)setContentType:(NSString *)contentType {
	self.synthesizedContentType = contentType;
}

- (NSString *)contentType {
	return self.synthesizedContentType;
}

- (void)setEncrypted:(BOOL)encrypted {
	self.synthesizedEncrypted = encrypted;
}

- (BOOL)encrypted {
	return self.synthesizedEncrypted;
}

@end
