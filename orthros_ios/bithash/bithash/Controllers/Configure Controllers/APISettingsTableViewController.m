//
//  APISettingsTableViewController.m
//  Orthros
//
//  Created by haifisch on 7/28/15.
//  Copyright (c) 2015 Haifisch. All rights reserved.
//

#import "APISettingsTableViewController.h"
#import "JNKeychain.h"
#import "liborthros.h"
#import "Common.h"
#import "DeviceIdentifiers.h"

struct API_TYPE {
    int type;
};
@interface APISettingsTableViewController () {
    NSUserDefaults *defaults;
    struct API_TYPE API_CONF;
    liborthros *orthros;
    DeviceIdentifiers *identify;
}
@property (strong, nonatomic) IBOutlet UITextField *endpointURLTxtBox;

@end

@implementation APISettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    defaults = [[NSUserDefaults alloc] initWithSuiteName:@"ninja.orthros.group.suite"];
    if ([JNKeychain loadValueForKey:@"api_endpoint"]) {
        orthros = [[liborthros alloc] initWithAPIAddress:[JNKeychain loadValueForKey:@"api_endpoint"] withUUID:[identify UUID]];
    } else {
        orthros = [[liborthros alloc] initWithUUID:[identify UUID]];
        [orthros setAPIAdress:@"https://api.orthros.ninja"];
    }
    [self setTitle:@"API Settings"];
    self.tableView.backgroundColor = [UIColor colorWithRed:33/255.0f green:33/255.0f blue:33/255.0f alpha:1];
    [self.tableView setSeparatorColor:[UIColor colorWithRed:33/255.0f green:33/255.0f blue:33/255.0f alpha:1]];
    self.endpointURLTxtBox.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"API Endpoint URL" attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
    if ([JNKeychain loadValueForKey:@"api_endpoint"]) {
        self.endpointURLTxtBox.text = [JNKeychain loadValueForKey:@"api_endpoint"];
    }
    API_CONF.type = (int)[defaults integerForKey:@"api_type"];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillDisappear:(BOOL)animated {
    [self saveCurrentConfig];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)saveCurrentConfig {
    [JNKeychain saveValue:self.endpointURLTxtBox.text forKey:@"api_endpoint"];
    [orthros setAPIAdress:self.endpointURLTxtBox.text];
    [defaults setInteger:API_CONF.type forKey:@"api_type"];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 1:
            self.endpointURLTxtBox.text = @"https://localhost:4590/";
            API_CONF.type = 1;
            break;
        case 2:
            self.endpointURLTxtBox.text = @"https://development.orthros.ninja/";
            API_CONF.type = 2;
            break;
        case 3:
            self.endpointURLTxtBox.text = @"";
            API_CONF.type = 3;
            break;
        case 4:
            self.endpointURLTxtBox.text = @"https://api.orthros.ninja";
            API_CONF.type = 4;
            break;
        default:
            break;
    }
    [self saveCurrentConfig];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
