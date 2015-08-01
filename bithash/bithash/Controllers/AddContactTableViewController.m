//
//  AddContactTableViewController.m
//  bithash
//
//  Created by Haifisch on 4/14/15.
//  Copyright (c) 2015 Haifisch. All rights reserved.
//

#import "AddContactTableViewController.h"
#import "KVNProgress.h"
#import "ScanQRViewController.h"
@interface AddContactTableViewController () <AddContactDelegate> {
    NSUserDefaults *defaults;
}
@property (strong, nonatomic) IBOutlet UITextField *recievingID;
@property (strong, nonatomic) IBOutlet UITextField *contactName;
@end

@implementation AddContactTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    defaults = [[NSUserDefaults alloc] initWithSuiteName:@"ninja.orthros.group.suite"];
    self.tableView.backgroundColor = [UIColor colorWithRed:33/255.0f green:33/255.0f blue:33/255.0f alpha:1];
    [self.tableView setSeparatorColor:[UIColor colorWithRed:33/255.0f green:33/255.0f blue:33/255.0f alpha:1]];
    self.recievingID.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Orthros ID" attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
    self.contactName.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Contact Name" attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];

    if (self.isFromMessage) {
        [self.recievingID setEnabled:NO];
        [self.recievingID setText:self.recieving_id];
        [self.contactName becomeFirstResponder];
    } else {
        [self.recievingID becomeFirstResponder];
    }
    self.title = @"Add to contacts";
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addToContacts:)];
    [self.navigationItem setRightBarButtonItem:addButton];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (IBAction)addToContacts:(id)sender {
    if (!([self.contactName.text length] > 0 || [self.recievingID.text length] > 0)) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Oops!" message:@"Looks like you've missed a field, check the fields and try again." preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        NSMutableArray *currentContacts = [[defaults objectForKey:@"contacts"] mutableCopy];
        if (!currentContacts) { // make a new one if it doesn't exist.
            currentContacts = [[NSMutableArray alloc] init];
        }
        [currentContacts addObject:[[NSDictionary alloc] initWithObjects:[[NSArray alloc] initWithObjects:self.contactName.text, nil] forKeys:[[NSArray alloc] initWithObjects:self.recievingID.text, nil]]];
        [defaults setObject:currentContacts forKey:@"contacts"];
        [defaults synchronize];
        [KVNProgress showSuccessWithStatus:@"Added to contacts!" completion:^{
            [self.navigationController popToRootViewControllerAnimated:YES];
        }];
    }
}

- (void)updateID:(NSString*)new_id {
    self.recievingID.text = new_id;
    [self.contactName becomeFirstResponder];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"scanQR"]) {
        ScanQRViewController *controller= [segue destinationViewController];
        controller.delegate = self;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
