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
@interface AddContactTableViewController () <AddContactDelegate>
@property (strong, nonatomic) IBOutlet UITextField *recievingID;
@property (strong, nonatomic) IBOutlet UITextField *contactName;
@end

@implementation AddContactTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
    
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleDone target:self action:@selector(cancel:)];
    [self.navigationItem setLeftBarButtonItem:cancel];
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
    }
    NSMutableArray *currentContacts = [[[NSUserDefaults standardUserDefaults] objectForKey:@"contacts"] mutableCopy];
    if (!currentContacts) { // make a new one if it doesn't exist. 
        currentContacts = [[NSMutableArray alloc] init];
    }
    [currentContacts addObject:[[NSDictionary alloc] initWithObjects:[[NSArray alloc] initWithObjects:self.contactName.text, nil] forKeys:[[NSArray alloc] initWithObjects:self.recievingID.text, nil]]];
    [[NSUserDefaults standardUserDefaults] setObject:currentContacts forKey:@"contacts"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [KVNProgress showSuccessWithStatus:@"Added to contacts!" completion:^{
        [self.navigationController dismissViewControllerAnimated:YES completion:^{
            [KVNProgress dismiss];
        }];
    }];
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

- (IBAction)cancel:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end