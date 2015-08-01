//
//  bithashTableViewController.m
//  bithash
//
//  Created by Haifisch on 2/14/15.
//  Copyright (c) 2015 Haifisch. All rights reserved.
//

#import "bithashTableViewController.h"
#import "JNKeychain.h"
#import "DeviceIdentifiers.h"
#import "KVNProgress.h"
#import "MessageDetailTableViewController.h"
#import "BDRSACryptor.h"
#import "BDRSACryptorKeyPair.h"
#import "BDError.h"
#import "BDLog.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import "ComposeTableViewController.h"
#import "LTHPasscodeViewController.h"
#import "Common.h"

#define UPLOAD_DEBUG NO // forces setup view


@interface bithashTableViewController () <LTHPasscodeViewControllerDelegate, NSURLConnectionDataDelegate, NSURLConnectionDelegate>
{
    DeviceIdentifiers *identify;
    NSMutableArray *quedMessages;
    NSMutableArray *plainTextMessages;
    liborthros *orthros;
    NSUserDefaults *defaults;
    NSDate *updatedEpoch;
    NSInteger epochHours;
}
@end

@implementation bithashTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    defaults = [[NSUserDefaults alloc] initWithSuiteName:@"ninja.orthros.group.suite"];
    self.tableView.backgroundColor = [UIColor colorWithRed:33/255.0f green:33/255.0f blue:33/255.0f alpha:1];

    identify = [[DeviceIdentifiers alloc] init];
    if ([JNKeychain loadValueForKey:@"api_endpoint"]) {
        orthros = [[liborthros alloc] initWithAPIAddress:[JNKeychain loadValueForKey:@"api_endpoint"] withUUID:[identify UUID]];
    } else {
        orthros = [[liborthros alloc] initWithUUID:[identify UUID]];
        [orthros setAPIAdress:@"https://api.orthros.ninja"];
    }
    
    [LTHPasscodeViewController sharedUser].delegate = self;
    [LTHPasscodeViewController sharedUser].maxNumberOfAllowedFailedAttempts = 3;
    if ([LTHPasscodeViewController doesPasscodeExist] && [LTHPasscodeViewController didPasscodeTimerEnd]) {
        [[LTHPasscodeViewController sharedUser] showLockScreenWithAnimation:YES
                                                                 withLogout:NO
                                                             andLogoutTitle:nil];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMessagePassoff:)
                                                 name:@"BITHASH_URL_CALLED"
                                               object:nil];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    self.title = @"Messages";
    [self.tabBarController setHidesBottomBarWhenPushed:YES];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = orthros_purple;
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self
                            action:@selector(reloadMessages:)
                  forControlEvents:UIControlEventValueChanged];
    
    UIBarButtonItem *myQR = [[UIBarButtonItem alloc] initWithTitle:@"My QR" style:UIBarButtonItemStylePlain target:self action:@selector(viewMyQR:)];
    [myQR setTintColor:orthros_purple];
    [self.navigationItem setLeftBarButtonItem:myQR];
    updatedEpoch = [orthros userPublicKeyLifetime];
    if (updatedEpoch) {
        NSDate *today = [NSDate date];
        NSUInteger unitFlags = NSCalendarUnitHour | NSCalendarUnitMinute;
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents *components = [calendar components:unitFlags fromDate:updatedEpoch toDate:today options:0];
        epochHours = [components hour];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (![JNKeychain loadValueForKey:PRIV_KEY] || ![JNKeychain loadValueForKey:PUB_KEY] || UPLOAD_DEBUG || ![defaults boolForKey:@"successfulSetup"]) {
        [self performSegueWithIdentifier:@"IntroductionView" sender:self];
    } else {
        // this will attempt to submit until it was sucessfully done.
        if (![defaults boolForKey:@"hasSubmitedToken"]) {
            if ([orthros submitToken:[defaults objectForKey:@"device_token"]]) {
                [defaults setBool:YES forKey:@"hasSubmitedToken"];
            } else {
                [defaults setBool:NO forKey:@"hasSubmitedToken"];
            }
        }
    }
    [self reloadMessages:YES];
}

- (void)handleMessagePassoff:(NSNotification *) notification {
    self.passed_id = [notification object];
    [self performSegueWithIdentifier:@"urlSegue" sender:self];
}

- (void)reloadMessages:(BOOL)quiet {

    quedMessages = [orthros messagesInQueue];
    plainTextMessages = [[NSMutableArray alloc] initWithCapacity:[quedMessages count]];
    
    //add all plain text messages to array
    for (id msdID in quedMessages) {
        [plainTextMessages addObject:[self readQued:(NSInteger *)[msdID integerValue]]];
    }
    
    NSMutableArray *finalPlainMessages = [[NSMutableArray alloc] init];
    
    //cycle through all plain text messages and stitch grouped ones together
    int cycle = (int)[plainTextMessages count] - 1;
    while (cycle >= 0) {
        
        NSString *message = plainTextMessages[cycle];

        //detirmine if it needs to be grouped
        if ([message length] >= 350 && [[message substringWithRange:NSMakeRange([message length] - 3, 1)] isEqualToString:@";"]) {
            
            //message is part of a series of messages, start piecing them together
            NSMutableString *longMessage = [[NSMutableString alloc] init];;//WithString:[message substringToIndex:348]];
            
            NSInteger remaining = [[NSString stringWithFormat:@"%@", [message substringWithRange:NSMakeRange([message length] - 2, 1)]] integerValue];
            
            int nextCount = -1;
            while (remaining > 0) {
                
                nextCount++;
                NSString *nextMessage = plainTextMessages[[plainTextMessages indexOfObject:message] - nextCount];
                
                remaining = [[NSString stringWithFormat:@"%@", [nextMessage substringWithRange:NSMakeRange([nextMessage length] - 2, 1)]] integerValue];
                
                nextMessage = [nextMessage substringToIndex:[nextMessage length] - 3];
                [longMessage appendString:nextMessage];
                
                cycle--;
                
            }

            [finalPlainMessages addObject:longMessage];
            
        }
        else {
            
            [finalPlainMessages addObject:message];
            cycle--;

        }
        

    }
    
    //add texts back in, revered
    [plainTextMessages removeAllObjects];
    int ccount = (int)[finalPlainMessages count] - 1;
    while (ccount >= 0) {
        [plainTextMessages addObject:finalPlainMessages[ccount]];
        ccount--;
    }
    
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (IBAction)viewMyQR:(id)sender {
    [self performSegueWithIdentifier:@"ViewMyQR" sender:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)checkKeypairAge:(id)sender {
    if (sender) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Manual keypair renew " message:@"Performing this will obliterate your previous public key from the Orthros backend and the copy on your device then create and submit a newly generated public key. This occurs automatically every 24 hours." preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Renew keys" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            BDError *error = [[BDError alloc] init];
            BDRSACryptor *RSACryptor = [[BDRSACryptor alloc] init];
            BDRSACryptorKeyPair *RSAKeyPair = [RSACryptor generateKeyPairWithKeyIdentifier:@"orthros_pair_popped" error:error];
            NSString *nonce = [orthros genNonce];
            if ([orthros submitNewPublicKey:RSAKeyPair.publicKey withKey:[RSACryptor decrypt:nonce key:[JNKeychain loadValueForKey:PRIV_KEY] error:error]]) {
                [JNKeychain deleteValueForKey:PRIV_KEY];
                [JNKeychain deleteValueForKey:PUB_KEY];
                [JNKeychain saveValue:RSAKeyPair.publicKey forKey:PUB_KEY];
                [JNKeychain saveValue:RSAKeyPair.privateKey forKey:PRIV_KEY];
            }
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    } else if (epochHours > 24) {
        BDError *error = [[BDError alloc] init];
        BDRSACryptor *RSACryptor = [[BDRSACryptor alloc] init];
        BDRSACryptorKeyPair *RSAKeyPair = [RSACryptor generateKeyPairWithKeyIdentifier:@"orthros_pair_popped" error:error];
        NSString *nonce = [orthros genNonce];
        if ([orthros submitNewPublicKey:RSAKeyPair.publicKey withKey:[RSACryptor decrypt:nonce key:[JNKeychain loadValueForKey:PRIV_KEY] error:error]]) {
            [JNKeychain deleteValueForKey:PRIV_KEY];
            [JNKeychain deleteValueForKey:PUB_KEY];
            [JNKeychain saveValue:RSAKeyPair.publicKey forKey:PUB_KEY];
            [JNKeychain saveValue:RSAKeyPair.privateKey forKey:PRIV_KEY];
        }
    }
}

#pragma mark - bithash api calls
- (NSString *)readQued:(NSInteger *)msg_id {
    NSString *encrypted = [orthros readMessageWithID:msg_id];
    if (encrypted) {
        BDRSACryptor *RSACryptor = [[BDRSACryptor alloc] init];
        NSString *cipherText = [RSACryptor decrypt:encrypted
                                               key:[JNKeychain loadValueForKey:PRIV_KEY]
                                             error:nil];
        return cipherText;
    }
    return nil;
}

-(void)deleteMsg:(NSInteger *)msg_id {
    NSString *enc_key = [orthros genNonce];
    BDRSACryptor *RSACryptor = [[BDRSACryptor alloc] init];
    if (![orthros deleteMessageWithID:msg_id withKey:[RSACryptor decrypt:enc_key key:[JNKeychain loadValueForKey:PRIV_KEY] error:nil]]) {
        [KVNProgress showErrorWithStatus:@"Error'd out! Try again." completion:^{ // give better diagnostics when this happens pl0x
            [self reloadMessages:YES]; // reload just because
            [KVNProgress dismiss];
        }];
    }else {
        [KVNProgress showSuccess];
        [self reloadMessages:YES];
        [KVNProgress dismiss];
    }
}

- (NSString *)contactNameForID:(NSString *)user_id {
    NSMutableArray *contactsArray;
    NSString *sender;
    if ([defaults objectForKey:@"contacts"]) {
        contactsArray = [[defaults objectForKey:@"contacts"] mutableCopy];
    }
    for (int count = 0; count < contactsArray.count; count++) {
        if ([[[contactsArray[count] allKeys] objectAtIndex:0] isEqualToString:user_id]) {
            sender = [contactsArray[count] allValues][0];
        }
    }
    return sender;
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if ([plainTextMessages count] > 0) {
        return [plainTextMessages count];
    }else {
        return 1;
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([plainTextMessages count] > 0) {
        return 44;
    }
    return 65;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([plainTextMessages count] > 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"msgCell" forIndexPath:indexPath];
        cell.backgroundColor = [UIColor colorWithRed:72/255.0f green:72/255.0f blue:72/255.0f alpha:1];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        NSTimeInterval epoch = [quedMessages[indexPath.row] doubleValue];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"d/MM/y h:mm a"];
        NSString *dateString = [NSString stringWithFormat:@"Sent on: %@",[formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:epoch]]];
        cell.detailTextLabel.text = dateString;
        cell.detailTextLabel.textColor = [UIColor whiteColor];
        NSString *sender = [orthros senderForMessageID:(NSInteger *)[quedMessages[indexPath.row] integerValue]];
        if ([self contactNameForID:sender]) {
            sender = [self contactNameForID:sender];
        }
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.text = [NSString stringWithFormat:@"From: %@", sender];
        tableView.separatorColor = [UIColor colorWithRed:33/255.0f green:33/255.0f blue:33/255.0f alpha:1];
        return cell;
    }else {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"noMessages"];
        cell.backgroundColor = [UIColor colorWithRed:33/255.0f green:33/255.0f blue:33/255.0f alpha:1];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        UILabel *noMsgs = [[UILabel alloc] initWithFrame:CGRectMake(0, cell.center.y-10, [UIScreen mainScreen].bounds.size.width, cell.frame.size.height)];
        noMsgs.text = @"No messages found!";
        noMsgs.textAlignment = NSTextAlignmentCenter;
        noMsgs.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:30];
        noMsgs.numberOfLines = 2;
        noMsgs.textColor = [UIColor whiteColor];
        [cell addSubview:noMsgs];
        
        tableView.separatorColor = [UIColor clearColor];
        UILabel *myID = [[UILabel alloc] initWithFrame:CGRectMake(0, cell.center.y+20, [UIScreen mainScreen].bounds.size.width, cell.frame.size.height)];
        myID.text = [NSString stringWithFormat:@"Tap the \"My QR\" to show your Orthros ID in QR form."];
        myID.textAlignment = NSTextAlignmentCenter;
        myID.textColor = [UIColor whiteColor];
        myID.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:12];
        myID.adjustsFontSizeToFitWidth = YES;
        myID.numberOfLines = 2;
        [cell addSubview:myID];
        tableView.separatorColor = [UIColor clearColor];
        return  cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([plainTextMessages count] > 0) {
        return YES;
    }
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self deleteMsg:(NSInteger *)[quedMessages[indexPath.row] integerValue]];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath * indexPath = [self.tableView indexPathForCell:sender];
    if ([segue.identifier isEqualToString:@"viewMessage"]) {
        MessageDetailTableViewController *controller = (MessageDetailTableViewController *)segue.destinationViewController;
        controller.sender = [orthros senderForMessageID:(NSInteger *)[quedMessages[indexPath.row] integerValue]];
        controller.message = plainTextMessages[indexPath.row];
        controller.msg_id = (NSInteger *)[quedMessages[indexPath.row] integerValue];
    } else if ([segue.identifier isEqualToString:@"urlSegue"]){
        ComposeTableViewController *controller = (ComposeTableViewController *)[segue destinationViewController];
        controller.reply_id = self.passed_id;
        controller.fromContactsOrURL = YES;
    }
}

#pragma mark - NSURLConnection

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"connectionFailed: %@", error.localizedDescription);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

// Local md5 string function
- (NSString *)md5:(NSString *)str {
    const char *cStr = [str UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (unsigned int)strlen(cStr), result );
    return [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1],
            result[2], result[3],
            result[4], result[5],
            result[6], result[7],
            result[8], result[9],
            result[10], result[11],
            result[12], result[13],
            result[14], result[15]
            ];
}

@end
