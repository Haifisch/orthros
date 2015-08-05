//
//  liborthros.h
//  liborthros
//
//  Created by haifisch on 7/3/15.
//  Copyright (c) 2015 Haifisch. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * liborthros is a simple objc library used to communicate to an Orthros API server. Using this you can query all of the API functions implemented on the server-side.
 * This library will not perform the RSA encryption required to properly encrypt messages or authenticate users, that is up to you to implement and handle. 
 *
 * This library will download public keys from Orthros, upload public keys, check for an existing public key for an Orthros ID, push encrypted messages to Orthros to be added to a user's queue, delete messages, and handle nonce generation requests.
 */
@interface liborthros : NSObject

/// @name Initialization methods
/**
 * Initializes liborthros the default API server for requests and stores the UUID in an NSString object for later use.
 *
 * @param uuid The user's UUID (Orthros identifier) to be used with API requests.
 * @returns A liborthros object.
 */
- (id)initWithUUID:(NSString *)uuid;

/**
 * Initializes liborthros with a custom API URL to use for requests and stores the UUID in an NSString object for later use.
 *
 * @param uuid The user's UUID (Orthros identifier) to be used with API requests.
 * @param url A custom API address location to use for requests.
 * @returns A liborthros object.
 */
- (id)initWithAPIAddress:(NSString *)url withUUID:(NSString *)uuid;

- (void)setAPIAdress:(NSString *)newAPIURL;
- (void)setOrthrosID:(NSString *)orthros_id;

/// @name Message Management methods
/**
 * Gets an array list of all the messages queued for the user's UUID.
 *
 * @returns An NSMutableArray object containing the list of message ID's present in the user's queue.
 */
- (NSMutableArray *)messagesInQueue;

/**
 * Downloads a message from the server for the message's ID.
 *
 * @param msg_id The message ID (and timestamp of the message.)
 * @returns The message for ID that is stored in an NSString object. This text should be encrypted with the receivers public key and can only be decrypted with the paired private key.
 */
- (NSString *)readMessageWithID:(NSInteger *)msg_id;

/**
 * Gets the sender's ID for a specified message ID.
 *
 * @param msg_id The message ID (and timestamp of the message.)
 * @returns An NSString object containing the UUID for the message's sender.
 */
- (NSString *)senderForMessageID:(NSInteger *)msg_id;

/**
 * Deletes a specified message from the server
 *
 * @param msg_id The message ID (and timestamp of the message.)
 * @param key A generated nonce key, this can be generated by using method genNonce.
 * @returns YES/TRUE if the message was deleted successfully, NO/FALSE if it was not deleted successfully
 */
- (BOOL)deleteMessageWithID:(NSInteger *)msg_id withKey:(NSString *)key;

/**
 * Downloads the public key for a specified Orthros ID
 *
 * @param user_id An Orthros ID
 * @returns A NSString object containing the public key of the requested user, will return NULL if none exists. Use upload:(NSString *)pub to verify that a user exists before requesting this.
 */
- (NSString *)publicKeyForUserID:(NSString *)user_id;

/**
 * Sends an encrypted message to a specific user's Orthros ID.
 *
 * @param crypted_message An encrypted message, encrypted with a user's public key requested from method publicKeyFor:(NSString *)user_id
 * @param to_id The recieving user's Orthros ID.
 * @param key A generated nonce key, this can be generated by using method genNonce.
 * @returns YES/TRUE if the message was sent successfully, NO/FALSE if it was not sent successfully.
 */
- (BOOL)sendMessage:(NSString *)crypted_message toUser:(NSString *)to_id withKey:(NSString *)key;

/// @name Nonce Key Managment
/**
 * Requests a randomly generated Nonce key from the server, this key is encrypted with the requesting user's Orthros ID and needs to be decrypted before use.
 * This key is to be used when a method such as send:(NSString *)crypted_message toUser:(NSString *)to_id withKey:(NSString *)key needs
 * to authenicate with the server that the requesting user is in fact the legitimate requesting user.
 *
 * @returns A 20 digit alphanumeric nonce key.
 */
- (NSString *)genNonce;

/// @name General Server Queries
/**
 * Checks if a public key exists under the user's generated UUID
 *
 * @returns YES/TRUE if the public key already exists on the server, NO/FALSE if no public key exists.
 */
- (BOOL)checkForUUID;

/**
 * Gets the creation unix epoch timestamp of the newest public key for our user
 *
 * @returns A NSDate object of the created date
 */
- (NSDate *)userPublicKeyLifetime;

/**
 * Attempts to upload the public key to the server for the user
 *
 * @param pub An unencrypted public key
 * @returns YES/TRUE if the public key was uploaded successfully, NO/FALSE if the public key was not uploaded successfully.
 */
- (BOOL)uploadPublicKey:(NSString *)pub;

/**
 * Attempts to upload a new public key to the server for the user, this is for when a public key "expires".
 *
 * @param pub An unencrypted public key
 * @returns YES/TRUE if the public key was uploaded successfully, NO/FALSE if the public key was not uploaded successfully.
 */
- (BOOL)submitNewPublicKey:(NSString *)pub withKey:(NSString *)nonce;

/**
 * Attempts to submit a user's APNS device token to the server
 *
 * @param pub An unencrypted public key
 * @returns YES/TRUE if the public key was uploaded successfully, NO/FALSE if the public key was not uploaded successfully.
 */
- (BOOL)submitToken:(NSString *)device_token;

/**
 * Attempts to obliterate a user for the passed UUID
 *
 * @param key A generated nonce key, this can be generated by using method genNonce.
 * @returns YES/TRUE if the user was obliterated, NO/FALSE if the user was not obliterated.
 */
- (BOOL)obliterateWithKey:(NSString *)key;

@end
