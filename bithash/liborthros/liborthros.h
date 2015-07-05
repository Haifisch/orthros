//
//  liborthros.h
//  liborthros
//
//  Created by haifisch on 7/3/15.
//  Copyright (c) 2015 Haifisch. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface liborthros : NSObject {
    NSURL *apiAddress;
    NSString *UUID;
}

// liborthros initilization methods
- (id)initWithUUID:(NSString *)uuid;
- (id)initWithAPIAddress:(NSString *)url withUUID:(NSString *)uuid;

// liborthros message methods
- (NSString *)read:(NSInteger *)msg_id;
- (NSString *)sender:(NSInteger *)msg_id;
- (BOOL)delete:(NSInteger *)msg_id withKey:(NSString *)key;
- (NSMutableArray *)messagesInQueue;
- (BOOL)send:(NSString *)crypted_message toUser:(NSString *)to_id withKey:(NSString *)key;

// liborthros nonce management
- (NSString *)genNonce;

// liborthros general server queries
- (BOOL)check;
- (BOOL)upload:(NSString *)pub;
- (NSString *)publicKeyFor:(NSString *)user_id;

@end
