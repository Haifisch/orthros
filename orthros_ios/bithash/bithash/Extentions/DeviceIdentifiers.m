//
//  DeviceIdentifiers.m
//  bithash
//
//  Created by Haifisch on 2/15/15.
//  Copyright (c) 2015 Haifisch. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>

#import "DeviceIdentifiers.h"
#import "JNKeychain.h"

@implementation DeviceIdentifiers

- (NSString *)createUUID
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    [JNKeychain saveValue:(__bridge NSString *)string forKey:@"bithash_uuid"];
    return (__bridge NSString *)string;
}

- (NSString*)UUID
{
    return [JNKeychain loadValueForKey:@"bithash_uuid"];
}

@end
