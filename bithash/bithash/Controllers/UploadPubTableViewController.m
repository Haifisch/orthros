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
    liborthros *orthros;
}
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@end

@implementation UploadPubTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitle:@"Submit Keys"];
    identify = [[DeviceIdentifiers alloc] init];
    orthros = [[liborthros alloc] initWithUUID:[identify UUID]];
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
    if ([orthros check]) {
        [self updateStatusWithString:@"Keys exist, You're all set!"];
        [self updateCellsForNextStep:YES];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }else {
        [self updateStatusWithString:@"No keys exist, please upload them."];
        [self updateCellsForNextStep:NO];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }
}

-(void)attemptUploadForUUID:(NSString*)UUID {
    if ([orthros upload:[JNKeychain loadValueForKey:PUB_KEY]]) {
        [self updateStatusWithString:@"Public key uploaded!"];
        [self updateCellsForNextStep:YES];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"successfulSetup"];
    }else {
        [self updateStatusWithString:@"Failed to upload public key!"];
        [self updateCellsForNextStep:NO];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"successfulSetup"];
    }
}

-(void)updateStatusWithString:(NSString*)newString {
    self.statusLabel.text = newString;
}
#pragma mark - Table view data source

-(void)updateCellsForNextStep:(BOOL)enabled {
    UITableViewCell *nextCell = (UITableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
    UITableViewCell *uploadCell = (UITableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    dispatch_async(dispatch_get_main_queue(), ^{
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
    });
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

@end
