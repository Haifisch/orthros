//
//  SupportTableViewController.m
//  Orthros
//
//  Created by haifisch on 7/31/15.
//  Copyright (c) 2015 Haifisch. All rights reserved.
//

#import "SupportTableViewController.h"

@interface SupportTableViewController ()

@end

@implementation SupportTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Support / FAQ";
    
    self.tableView.backgroundColor = [UIColor colorWithRed:33/255.0f green:33/255.0f blue:33/255.0f alpha:1];
    [self.tableView setSeparatorColor:[UIColor colorWithRed:33/255.0f green:33/255.0f blue:33/255.0f alpha:1]];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 35;
}

- (CGFloat)tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section {
    return 1.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        return 185;
    } else if (indexPath.section == 2) {
        return 40;
    }
    return 85;
}

- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"faqAnswer"];
    if (indexPath.section == 2) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    }
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    cell.textLabel.textColor = [UIColor whiteColor];
    [cell.textLabel setNumberOfLines:10];
    [cell.textLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:16]];
    if (indexPath.section == 0) {
        cell.textLabel.text = @"Yes, your RSA keypair expires after 24 hours of the public keys life. A new keypair is created and the new public key is submitted to the server.";
    } else if (indexPath.section == 1) {
        cell.textLabel.text = @"Messages are encrypted with the recipient's public key, the server then authenticates that the sender is truly who it is by requiring a random nonce to be created then encrypted once for the user and once for itself only the sender may decrypt this nonce and use it only once to send the message. The message is encrypted again on the server with a private AES key and a dynamic IV.";
    } else if (indexPath.section == 2) {
        cell.textLabel.text = @"Support email";
        cell.backgroundColor = [UIColor colorWithRed:72/255.0f green:72/255.0f blue:72/255.0f alpha:1];
        cell.detailTextLabel.textColor = [UIColor whiteColor];
        [cell.detailTextLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:15]];
        cell.detailTextLabel.text = @"haifisch@hbang.ws";
    }
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(10, 0, 200, 35)];
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:headerView.frame];
    headerLabel.textColor = [UIColor whiteColor];
    headerLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:15];
    switch (section) {
        case 0:
            headerLabel.text = @"Does my keypair expire?";
            break;
            
        case 1:
            headerLabel.text = @"What encryption is used?";
            break;
            
        case 2:
            headerLabel.text = @"Support";
            break;
            
        default:
            break;
    }
    [headerView addSubview:headerLabel];
    return headerView;
}

@end
