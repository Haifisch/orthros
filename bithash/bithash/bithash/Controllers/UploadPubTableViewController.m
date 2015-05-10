//
//  UploadPubTableViewController.m
//  bithash
//
//  Created by Haifisch on 2/15/15.
//  Copyright (c) 2015 Haifisch. All rights reserved.
//

#import "UploadPubTableViewController.h"
#import "DeviceIdentifiers.h"
#import "JNKeychain.h"
#import "bithashTableViewController.h"
#import "Common.h"

#define HEADER_HEIGHT 80

@interface UploadPubTableViewController ()
{
    DeviceIdentifiers *identify;
}
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@end

@implementation UploadPubTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitle:@"Submit Keys"];
    identify = [[DeviceIdentifiers alloc] init];
    [self updateStatusWithString:@"Querying server for exsisting keys... One sec."];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self queryServerForUUID:[identify UUID]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)queryServerForUUID:(NSString*)UUID{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSMutableString *action = Obfuscate.c.a.r.k.m.p.equals.a.f.g.a.i;
    NSString *url = [NSString stringWithFormat:@"%@?%@&UUID=%@", API_OB, action, UUID];
    NSData *queryData = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    if (queryData) {
        NSError *error;
        NSMutableDictionary *responseParsed = [NSJSONSerialization JSONObjectWithData:queryData options:NSJSONReadingMutableContainers error:&error];
        if (error)
            NSLog(@"JSON parsing error: %@", error);
        if ([responseParsed[@"error"] intValue] != 1) {
            [self updateStatusWithString:@"Keys exsist, You're all set!"];
            [self updateCellsForNextStep:YES];
        }else {
            [self updateStatusWithString:@"No keys exsist, please upload them."];
            [self updateCellsForNextStep:NO];
        }
    }
}

-(void)attemptUploadForUUID:(NSString*)UUID {
    NSString *post = [NSString stringWithFormat:@"pub=%@",[JNKeychain loadValueForKey:PUB_KEY]];
    NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    NSString *postLength = [NSString stringWithFormat:@"%lu",(unsigned long)[postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSMutableString *action = Obfuscate.c.a.r.k.m.p.equals.w.n.j.m.c.b;
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?%@&UUID=%@", API_OB, action, UUID]]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    NSURLConnection *conn = [[NSURLConnection alloc]initWithRequest:request delegate:self];
    if(conn) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        NSLog(@"Connection Successful");
    } else {
        NSLog(@"Connection could not be made");
    }
}

-(void)updateStatusWithString:(NSString*)newString {
    self.statusLabel.text = newString;
}
#pragma mark - Table view data source

-(void)updateCellsForNextStep:(BOOL)enabled {
    UITableViewCell *nextCell = (UITableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
    UITableViewCell *uploadCell = (UITableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [UIView animateWithDuration:0.3f
                     animations:^{
                         if (!enabled) {
                             uploadCell.alpha = 1.0;
                             nextCell.alpha = 0.2;
                         }else {
                             uploadCell.alpha = 0.2;
                             nextCell.alpha = 1.0;
                         }
                         uploadCell.userInteractionEnabled = !enabled;
                         uploadCell.textLabel.enabled = !enabled;
                         uploadCell.detailTextLabel.enabled = !enabled;
                         nextCell.userInteractionEnabled = enabled;
                         nextCell.textLabel.enabled = enabled;
                         nextCell.detailTextLabel.enabled = enabled;
                     }
     ];
}


-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, HEADER_HEIGHT)];
        UILabel *rsaLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, headerView.bounds.size.width - 20, headerView.bounds.size.height)];
        rsaLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
        rsaLabel.text = @"In order for people to encrypt messages with your public key, we will store it in an encrypted database on our servers for download by other users, just as you can with theirs."; // we should have this localized.
        // Setting a passcode is highly suggested, by setting one you're adding another layer of security to Orthros and allows protection to accessing the application. If you have a device with Touch ID, setting a passcode will allow you to unlock Orthros with your finger!
        rsaLabel.adjustsFontSizeToFitWidth = YES;
        [rsaLabel setNumberOfLines:6];
        rsaLabel.textAlignment = NSTextAlignmentCenter;
        [headerView addSubview:rsaLabel];
        return headerView;
    }else {
        return nil;
    }
}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return HEADER_HEIGHT;
    }
    return UITableViewAutomaticDimension;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return HEADER_HEIGHT;
    }
    return UITableViewAutomaticDimension;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0 && indexPath.row == 0) {
        [self attemptUploadForUUID:[identify UUID]];
    }else if (indexPath.section == 1 && indexPath.row == 1) {
        [self performSegueWithIdentifier:@"SetupPasscode" sender:self];
    }
}
#pragma mark - NSURLConnection
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData*)data {
    NSError *error;
    NSMutableDictionary *responseParsed = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    if (error)
        NSLog(@"JSON parsing error: %@", error);
    if ((int)responseParsed[@"error"] != 1) {
        [self updateStatusWithString:@"Public key uploaded!"];
        [self updateCellsForNextStep:YES];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"successfulSetup"];
    }else {
        [self updateStatusWithString:@"Failed to upload public key!"];
        [self updateCellsForNextStep:NO];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"successfulSetup"];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"connectionFailed: %@", error.localizedDescription);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

@end
