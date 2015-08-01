//
//  MessageDetailTableViewController.m
//  bithash
//
//  Created by Haifisch on 4/12/15.
//  Copyright (c) 2015 Haifisch. All rights reserved.
//

#import "MessageDetailTableViewController.h"
#import "DeviceIdentifiers.h"
#import "KVNProgress.h"
#import "ComposeTableViewController.h"
#import "AddContactTableViewController.h"
#import "Common.h"
#import "BDRSACryptor.h"
#import "JNKeychain.h"
@interface MessageDetailTableViewController (){
    DeviceIdentifiers *identify;
    liborthros *orthros;
    NSUserDefaults *defaults;
}
@property (strong, nonatomic) IBOutlet UITextView *messageBox;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *addContactBtn;

@end

@implementation MessageDetailTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.backgroundColor = [UIColor colorWithRed:33/255.0f green:33/255.0f blue:33/255.0f alpha:1];
    [self.tableView setSeparatorColor:[UIColor colorWithRed:33/255.0f green:33/255.0f blue:33/255.0f alpha:1]];
    defaults = [[NSUserDefaults alloc] initWithSuiteName:@"ninja.orthros.group.suite"];
    identify = [[DeviceIdentifiers alloc] init];
    if ([JNKeychain loadValueForKey:@"api_endpoint"]) {
        orthros = [[liborthros alloc] initWithAPIAddress:[JNKeychain loadValueForKey:@"api_endpoint"] withUUID:[identify UUID]];
    } else {
        orthros = [[liborthros alloc] initWithUUID:[identify UUID]];
        [orthros setAPIAdress:@"https://api.orthros.ninja"];
    }
    self.title = @"Message";
    if (!self.message) {
        [self.navigationController dismissViewControllerAnimated:YES completion:^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Failed Decryption" message:@"Something went awry while decrypting your message! Try again later" preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }];
    }
    if ([self contactNameForID:self.sender]) {
        [self.addContactBtn setEnabled:NO];
        self.addContactBtn.title = @"";
        self.fromLabel.text = [self contactNameForID:self.sender];
    } else {
        [self.addContactBtn setEnabled:YES];
        self.addContactBtn.title = @"Add to contacts";
        self.fromLabel.text = self.sender;
    }
    self.messageBox.text = self.message;
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)deleteMessage:(id)sender {
    [KVNProgress showWithStatus:@"Deleting message..."];
    [self deleteMsg:self.msg_id];
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

-(void)deleteMsg:(NSInteger *)msg_id {
    NSString *enc_key = [orthros genNonce];
    BDRSACryptor *RSACryptor = [[BDRSACryptor alloc] init];
    if ([orthros deleteMessageWithID:msg_id withKey:[RSACryptor decrypt:enc_key key:[JNKeychain loadValueForKey:PRIV_KEY] error:nil]]) {
        [KVNProgress showSuccessWithCompletion:^{
            [KVNProgress dismiss];
            [self.navigationController popToRootViewControllerAnimated:YES];
        }];
    }else {
        [KVNProgress showErrorWithStatus:@"Error'd out while trying to delete! Try again." completion:^{ // give better diagnostics when this happens pl0x
            [KVNProgress dismiss];
            [self.navigationController popToRootViewControllerAnimated:YES];
        }];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showCompose"]) {
        ComposeTableViewController *controller = (ComposeTableViewController *)[segue destinationViewController];
        controller.isReply = YES;
        controller.reply_id = self.sender;
    }else if ([segue.identifier isEqualToString:@"addContact"]) {
        AddContactTableViewController *controller = (AddContactTableViewController *)[segue destinationViewController];
        controller.isFromMessage = YES;
        controller.recieving_id = self.sender;
    }
}

@end
