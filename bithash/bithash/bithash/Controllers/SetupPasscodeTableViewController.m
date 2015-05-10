//
//  SetupPasscodeTableViewController.m
//  Orthros
//
//  Created by Haifisch on 5/2/15.
//  Copyright (c) 2015 Haifisch. All rights reserved.
//

#import "SetupPasscodeTableViewController.h"
#import "LTHPasscodeViewController.h"
#import "UIAlertView+Blocks.h"
#import "Common.h"

#define HEADER_HEIGHT 120

@interface SetupPasscodeTableViewController ()

@end

@implementation SetupPasscodeTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Passcode";
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0 && indexPath.row == 0) {
        [[LTHPasscodeViewController sharedUser] showForEnablingPasscodeInViewController:self asModal:YES];
    }else if (indexPath.section == 0 && indexPath.row == 1) {
        if ([LTHPasscodeViewController doesPasscodeExist]) {
            [self.navigationController popToRootViewControllerAnimated:YES];
        }else {
            [UIAlertView showWithTitle:@"No passcode set" message:@"Are you sure you want to continue without a passcode?" cancelButtonTitle:@"No" otherButtonTitles:[NSArray arrayWithObject:@"Yes"] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                switch (buttonIndex) {
                    case 1:
                        [self.navigationController popToRootViewControllerAnimated:YES];
                        break;
                        
                    default:
                        break;
                }
            }];
        }
    }
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, HEADER_HEIGHT)];
        UILabel *passLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, headerView.bounds.size.width - 20, headerView.bounds.size.height)];
        passLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
        passLabel.text = @"Setting a passcode is highly suggested, by setting one you're adding another layer of security to Orthros and allows protection to accessing the application. If you have a device with Touch ID, setting a passcode will allow you to unlock Orthros with your finger! If you wish to skip this step, just press finish."; // we should have this localized.
        //
        passLabel.adjustsFontSizeToFitWidth = YES;
        [passLabel setNumberOfLines:6];
        passLabel.textAlignment = NSTextAlignmentCenter;
        [headerView addSubview:passLabel];
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

@end
