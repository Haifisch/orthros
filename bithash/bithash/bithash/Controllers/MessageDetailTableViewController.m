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

#define API_OB Obfuscate.f.r.r.n.q.colon.forward_slash.forward_slash.m.t.r.f.t.m.q.dot.p.k.p.l.c.forward_slash.c.n.k.forward_slash.d.k.r.f.c.q.f.dot.n.f.n
@interface MessageDetailTableViewController (){
    DeviceIdentifiers *identify;
}
@property (strong, nonatomic) IBOutlet UITextView *messageBox;

@end

@implementation MessageDetailTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    identify = [[DeviceIdentifiers alloc] init];
    self.title = @"Message";
    if (!self.message) {
        [self.navigationController dismissViewControllerAnimated:YES completion:^{
            [[[UIAlertView alloc] initWithTitle:@"Failed decryption" message:@"Something went awry while decrypting your message! Try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
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

-(void)deleteMsg:(NSInteger)msg_id {
    NSMutableString *action = Obfuscate.c.a.r.k.m.p.equals.b.g.j.g.r.g.underscore.o.q.e;
    NSString *urlString = [NSString stringWithFormat:@"%@?%@&UUID=%@&msg_id=%ld", API_OB, action, [identify UUID], (long)msg_id];
    NSData *queryData = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
    if (queryData) {
        NSError *error;
        NSMutableDictionary *responseParsed = [NSJSONSerialization JSONObjectWithData:queryData options:NSJSONReadingMutableContainers error:&error];
        if (error)
            NSLog(@"JSON parsing error: %@", error);
        if (responseParsed[@"error"] == 0) {
            [[[UIAlertView alloc] initWithTitle:@"Failed deletion" message:@"Something went awry when trying to delete this message, it may not exsist on the server. Refresh and try again later." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil] show];
            [KVNProgress showErrorWithStatus:@"Failed deletion! The message may be missing, try again later." completion:^{
                [KVNProgress dismiss];
            }];
        }else {
            [KVNProgress showSuccessWithStatus:@"Deleted successfully!" completion:^{
                [KVNProgress dismiss];
                [self.navigationController popToRootViewControllerAnimated:YES];
            }];
        }
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
