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
#import <BDRSACryptor.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import "ComposeTableViewController.h"
#import "LTHPasscodeViewController.h"
#import "Common.h"


#define UPLOAD_DEBUG NO // forces setup view


@interface bithashTableViewController () <LTHPasscodeViewControllerDelegate, NSURLConnectionDataDelegate, NSURLConnectionDelegate>
{
    DeviceIdentifiers *identify;
    NSMutableArray *quedMessages;
    liborthros *orthros;
}
@end

@implementation bithashTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    identify = [[DeviceIdentifiers alloc] init];
    orthros = [[liborthros alloc] initWithUUID:[identify UUID]];
    if (![JNKeychain loadValueForKey:PRIV_KEY] || ![JNKeychain loadValueForKey:PUB_KEY] || UPLOAD_DEBUG || ![[NSUserDefaults standardUserDefaults] boolForKey:@"successfulSetup"]) {
        [self performSegueWithIdentifier:@"IntroductionView" sender:self];
    } else {
        [LTHPasscodeViewController sharedUser].delegate = self;
        [LTHPasscodeViewController sharedUser].maxNumberOfAllowedFailedAttempts = 3;
        if ([LTHPasscodeViewController doesPasscodeExist] && [LTHPasscodeViewController didPasscodeTimerEnd]) {
            [[LTHPasscodeViewController sharedUser] showLockScreenWithAnimation:YES
                                                                     withLogout:NO
                                                                 andLogoutTitle:nil];
        }
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
    self.refreshControl.backgroundColor = [UIColor purpleColor];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self
                            action:@selector(reloadMessages:)
                  forControlEvents:UIControlEventValueChanged];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self reloadMessages:YES];
}

- (void)handleMessagePassoff:(NSNotification *) notification {
    self.passed_id = [notification object];
    [self performSegueWithIdentifier:@"urlSegue" sender:self];
}

- (void)reloadMessages:(BOOL)quiet {
    if (!quiet) {
        [KVNProgress showWithStatus:@"Querying messages..."];
    }
    quedMessages = [[NSMutableArray alloc] init]; //empty/create new array for if one already exists.
    quedMessages = [orthros messagesInQueue];
    if (!quiet) {
        if ([orthros messagesInQueue].count > 0) {
            [KVNProgress showSuccessWithStatus:@"Retrieved successfully" completion:^{
                [KVNProgress dismiss];
            }];
        }else {
            [KVNProgress showSuccessWithStatus:@"No messages found" completion:^{
                [KVNProgress dismiss];
            }];
        }
    }
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - bithash api calls
- (NSString *)readQued:(NSInteger *)msg_id {
    NSString *encrypted = [orthros read:msg_id];
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
    if (![orthros delete:msg_id withKey:[RSACryptor decrypt:enc_key key:[JNKeychain loadValueForKey:PRIV_KEY] error:nil]]) {
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
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"contacts"]) {
        contactsArray = [[[NSUserDefaults standardUserDefaults] objectForKey:@"contacts"] mutableCopy];
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
    if ([quedMessages count] > 0) {
        return [quedMessages count];
    }else {
        return 1;
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([quedMessages count] > 0) {
        return 44;
    }
    return 90;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([quedMessages count] > 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"msgCell" forIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        NSTimeInterval epoch = [quedMessages[indexPath.row] doubleValue];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"d/MM/y h:mm a"];
        NSString *dateString = [NSString stringWithFormat:@"Sent on: %@",[formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:epoch]]];
        cell.detailTextLabel.text = dateString;
        NSString *sender = [orthros sender:(NSInteger *)[quedMessages[indexPath.row] integerValue]];
        if ([self contactNameForID:sender]) {
            sender = [self contactNameForID:sender];
        }
        cell.textLabel.text = [NSString stringWithFormat:@"From: %@", sender];
        return cell;
    }else {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"noMessages"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        UILabel *noMsgs = [[UILabel alloc] initWithFrame:CGRectMake(0, cell.center.y-10, [UIScreen mainScreen].bounds.size.width, cell.frame.size.height)];
        noMsgs.text = @"No messages found!";
        noMsgs.textAlignment = NSTextAlignmentCenter;
        noMsgs.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:25];
        noMsgs.numberOfLines = 2;
        [cell addSubview:noMsgs];
        
        UILabel *myID = [[UILabel alloc] initWithFrame:CGRectMake(0, cell.center.y+20, [UIScreen mainScreen].bounds.size.width, cell.frame.size.height)];
        myID.text = [NSString stringWithFormat:@"Your ID; %@", [identify UUID]];
        myID.textAlignment = NSTextAlignmentCenter;
        myID.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:12];
        myID.adjustsFontSizeToFitWidth = YES;
        myID.numberOfLines = 2;
        [cell addSubview:myID];
        
        return  cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
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
        controller.sender = [orthros sender:(NSInteger *)[quedMessages[indexPath.row] integerValue]];
        controller.message = [self readQued:(NSInteger *)[quedMessages[indexPath.row] integerValue]];
        controller.msg_id = (NSInteger *)[quedMessages[indexPath.row] integerValue];
    } else if ([segue.identifier isEqualToString:@"urlSegue"]){
        UINavigationController *nav = [segue destinationViewController];
        ComposeTableViewController *controller = (ComposeTableViewController *)nav.topViewController;
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

@end
