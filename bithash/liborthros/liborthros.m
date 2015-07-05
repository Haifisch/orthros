//
//  liborthros.m
//  liborthros
//
//  Created by haifisch on 7/3/15.
//  Copyright (c) 2015 Haifisch. All rights reserved.
//

#import "liborthros.h"

@implementation liborthros

#pragma mark orthros init

- (id)initWithUUID:(NSString *)uuid {
    return [self initWithAPIAddress:@"https://api.orthros.ninja" withUUID:uuid];
}

- (id)initWithAPIAddress:(NSString *)url withUUID:(NSString*)uuid {
    self = [super init];
    if (self) {
        apiAddress = [NSURL URLWithString:url];
        UUID = uuid;
    }
    return self;
}

#pragma mark orthos message functions

// Read message for ID, response is encrypted.
- (NSString *)read:(NSInteger *)msg_id {
    NSString *action = @"get";
    NSString *urlString = [NSString stringWithFormat:@"%@?action=%@&msg_id=%ld&UUID=%@", apiAddress, action, (long)msg_id, UUID];
    NSData *queryData = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
    if (queryData) {
        NSError *error;
        NSMutableDictionary *responseParsed = [NSJSONSerialization JSONObjectWithData:queryData options:0 error:&error];
        if (error)
            NSLog(@"liborthros; JSON parsing error: %@", error);
        NSString *fixedString = [responseParsed[@"msg"][@"msg"] stringByReplacingOccurrencesOfString:@" " withString:@"+"];
        return fixedString;
    }
    return nil;
}

// Get sender for message ID
- (NSString *)sender:(NSInteger *)msg_id {
    NSString *action = @"get";
    NSString *urlString = [NSString stringWithFormat:@"%@?action=%@&msg_id=%ld&UUID=%@", apiAddress, action, (long)msg_id, UUID];
    NSData *queryData = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
    if (queryData) {
        NSError *error;
        NSMutableDictionary *responseParsed = [NSJSONSerialization JSONObjectWithData:queryData options:0 error:&error];
        if (error)
            NSLog(@"liborthros; JSON parsing error: %@", error);
        NSString *senderString = responseParsed[@"msg"][@"sender"];
        return senderString;
    }
    return nil;
}

// Get all messages in the user's queue.
- (NSMutableArray *)messagesInQueue {
    NSMutableArray *returnedArray = [[NSMutableArray alloc] init];
    NSString *action = @"list";
    NSData *queryData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?action=%@&UUID=%@", apiAddress, action, UUID]]];
    if (queryData) {
        NSError *error;
        NSMutableDictionary *responseParsed = [NSJSONSerialization JSONObjectWithData:queryData options:NSJSONReadingMutableContainers error:&error];
        returnedArray = responseParsed[@"msgs"];
        if (error)
            NSLog(@"liborthros; JSON parsing error: %@", error);
    }
    return returnedArray;
}

// Delete message for ID, returns YES for a sucessful deletion or NO for unsucessful
- (BOOL)delete:(NSInteger *)msg_id withKey:(NSString *)key {
    NSString *action = @"delete_msg";
    NSString *post = [NSString stringWithFormat:@"key=%@",key];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?action=%@&UUID=%@&msg_id=%ld", apiAddress, action, UUID, (long)msg_id]]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = postData;
    __block BOOL deletionResponse;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            NSLog(@"Status code: %li", (long)((NSHTTPURLResponse *)response).statusCode);
            NSMutableDictionary *parsedDict = [[NSJSONSerialization JSONObjectWithData:data options:0 error:nil] mutableCopy];
            if ([parsedDict[@"error"] integerValue] == 1 || parsedDict == nil) {
                deletionResponse = NO;
            }else {
                deletionResponse = YES;
            }
        } else {
            deletionResponse = NO;
        }
        dispatch_semaphore_signal(semaphore);
    }] resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return deletionResponse;
}

// Send encrypted message to a user's ID
- (BOOL)send:(NSString *)crypted_message toUser:(NSString *)to_id withKey:(NSString *)key {
    NSDictionary* jsonDict = @{@"sender":UUID,@"msg":crypted_message};
    NSData* json = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:nil];
    NSString *jsonStr = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
    NSString *post = [NSString stringWithFormat:@"msg=%@&key=%@", jsonStr, key];
    NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    NSString *action = @"send";
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?action=%@&UUID=%@&receiver=%@", apiAddress, action, UUID, to_id]]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = postData;
    __block BOOL sendResponse;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            NSLog(@"Status code: %li", (long)((NSHTTPURLResponse *)response).statusCode);
            NSMutableDictionary *parsedDict = [[NSJSONSerialization JSONObjectWithData:data options:0 error:nil] mutableCopy];
            if ([parsedDict[@"error"] integerValue] == 1 || parsedDict == nil) {
                sendResponse = NO;
            }else {
                sendResponse = YES;
            }

        } else {
            NSLog(@"liborthros; Error: %@", error.localizedDescription);
        }
        dispatch_semaphore_signal(semaphore);
    }] resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return sendResponse;
}

#pragma mark nonce managment

// Get onetime key
-(NSString *)genNonce {
    NSString *returnedKey = [[NSString alloc] init];
    NSString *action = @"gen_key";
    NSString *url = [NSString stringWithFormat:@"%@?action=%@&UUID=%@", apiAddress, action, UUID];
    NSData *queryData = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    if (queryData) {
        NSError *error;
        NSMutableDictionary *responseParsed = [NSJSONSerialization JSONObjectWithData:queryData options:NSJSONReadingMutableContainers error:&error];
        if (!error)
            returnedKey = responseParsed[@"key"];
    }
    return returnedKey;
}

#pragma mark General UUID queries

// Check if UUID exists
-(BOOL)check {
    NSString *action = @"check";
    NSString *url = [NSString stringWithFormat:@"%@?action=%@&UUID=%@", apiAddress, action, UUID];
    NSData *queryData = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    if (queryData) {
        NSError *error;
        NSMutableDictionary *responseParsed = [NSJSONSerialization JSONObjectWithData:queryData options:NSJSONReadingMutableContainers error:&error];
        if (error)
            NSLog(@"liborthros; JSON parsing error: %@", error);
        if ([responseParsed[@"error"] intValue] != 1) {
            return YES;
        }else {
            return NO;
        }
    }
    return NO;
}

// Submit the user's public key to the server
-(BOOL)upload:(NSString *)pub {
    NSString *post = [NSString stringWithFormat:@"pub=%@",pub];
    NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    NSString *action = @"upload";
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?action=%@&UUID=%@", apiAddress, action, UUID]]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = postData;
    __block BOOL uploadResponse;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            NSError *error;
            NSMutableDictionary *responseParsed = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            if (error)
                NSLog(@"liborthros; JSON parsing error: %@", error);
            if ((int)responseParsed[@"error"] != 1) {
                uploadResponse = YES;
            }else {
                uploadResponse = NO;
            }
        } else {
            uploadResponse = NO;
        }
        dispatch_semaphore_signal(semaphore);
    }] resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return uploadResponse;
}

// Download public key for user's ID
-(NSString *)publicKeyFor:(NSString *)user_id {
    NSString *returnedPub = [[NSString alloc] init];
    NSString *action = @"download";
    NSString *url = [NSString stringWithFormat:@"%@?action=%@&UUID=%@&receiver=%@", apiAddress, action, UUID, user_id];
    NSData *queryData = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    if (queryData) {
        NSError *error;
        NSMutableDictionary *responseParsed = [NSJSONSerialization JSONObjectWithData:queryData options:NSJSONReadingMutableContainers error:&error];
        // what the hell
        // cut it up, fix it, put it back together. :) fuck this
        returnedPub = [responseParsed[@"pub"] stringByReplacingOccurrencesOfString:@"-----BEGIN PUBLIC KEY-----" withString:@""];
        returnedPub = [returnedPub stringByReplacingOccurrencesOfString:@"-----END PUBLIC KEY-----" withString:@""];
        if (!returnedPub) {
            return nil;
        }
        returnedPub = [returnedPub stringByReplacingOccurrencesOfString:@" " withString:@"+"];
        returnedPub = [NSString stringWithFormat:@"-----BEGIN PUBLIC KEY-----%@-----END PUBLIC KEY-----", returnedPub];
        if (error)
            NSLog(@"liborthros; JSON parsing error: %@", error);
    }
    return returnedPub;
}
@end
