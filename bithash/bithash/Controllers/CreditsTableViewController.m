//
//  CreditsTableViewController.m
//  Orthros
//
//  Created by haifisch on 7/23/15.
//  Copyright (c) 2015 Haifisch. All rights reserved.
//

#import "CreditsTableViewController.h"

@interface CreditsTableViewController ()

@end

@implementation CreditsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Credits";
    
    self.tableView.backgroundColor = [UIColor colorWithRed:33/255.0f green:33/255.0f blue:33/255.0f alpha:1];
    [self.tableView setSeparatorColor:[UIColor colorWithRed:33/255.0f green:33/255.0f blue:33/255.0f alpha:1]];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [cell setBackgroundColor:[UIColor colorWithRed:72/255.0f green:72/255.0f blue:72/255.0f alpha:1]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
