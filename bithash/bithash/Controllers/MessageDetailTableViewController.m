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
}
@property (strong, nonatomic) IBOutlet UITextView *messageBox;

@end

@implementation MessageDetailTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    identify = [[DeviceIdentifiers alloc] init];
    orthros = [[liborthros alloc] initWithUUID:[identify UUID]];
    self.title = @"Message";
    if (!self.message) {
        [self.navigationController dismissViewControllerAnimated:YES completion:^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Failed Decryption" message:@"Something went awry while decrypting your message! Try again later" preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }];
    }
    self.fromLabel.text = self.sender;
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

-(void)deleteMsg:(NSInteger *)msg_id {
    NSString *enc_key = [orthros genNonce];
    BDRSACryptor *RSACryptor = [[BDRSACryptor alloc] init];
    if ([orthros delete:msg_id withKey:[RSACryptor decrypt:enc_key key:[JNKeychain loadValueForKey:PRIV_KEY] error:nil]]) {
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
        UINavigationController *nav = [segue destinationViewController];
        ComposeTableViewController *controller = (ComposeTableViewController *)nav.topViewController;
        controller.isReply = YES;
        controller.reply_id = self.sender;
    }else if ([segue.identifier isEqualToString:@"addContact"]) {
        UINavigationController *nav = [segue destinationViewController];
        AddContactTableViewController *controller = (AddContactTableViewController *)nav.topViewController;
        controller.isFromMessage = YES;
        controller.recieving_id = self.sender;
    }
}

@end
