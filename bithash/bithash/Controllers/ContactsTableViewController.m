//
//  ContactsTableViewController.m
//  bithash
//
//  Created by Haifisch on 4/14/15.
//  Copyright (c) 2015 Haifisch. All rights reserved.
//

#import "ContactsTableViewController.h"
#import "ComposeTableViewController.h"

@interface ContactsTableViewController () {
    NSMutableArray *contactsArray;
}

@end

@implementation ContactsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Contacts";
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"contacts"]) {
        contactsArray = [[[NSUserDefaults standardUserDefaults] objectForKey:@"contacts"] mutableCopy];
    }
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(preformAddSegue:)];
    [add setTintColor:[UIColor purpleColor]];
    [self.navigationItem setRightBarButtonItem:add];
    
    UIBarButtonItem *myQR = [[UIBarButtonItem alloc] initWithTitle:@"My QR" style:UIBarButtonItemStylePlain target:self action:@selector(viewMyQR:)];
    [myQR setTintColor:[UIColor purpleColor]];
    [self.navigationItem setLeftBarButtonItem:myQR];
    
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updateTable];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)preformAddSegue:(id)sender {
    [self performSegueWithIdentifier:@"showAdd" sender:self];
}

- (IBAction)viewMyQR:(id)sender {
    [self performSegueWithIdentifier:@"ViewMyQR" sender:self];
}

- (void)updateTable {
    contactsArray = [[[NSUserDefaults standardUserDefaults] objectForKey:@"contacts"] mutableCopy];
    [self.tableView reloadData];
}

- (void)deleteContactNameForID:(NSString *)user_id {
    for (int count = 0; count < contactsArray.count; count++) {
        if ([[[contactsArray[count] allKeys] objectAtIndex:0] isEqualToString:user_id]) {
            [contactsArray removeObject:contactsArray[count]];
            [[NSUserDefaults standardUserDefaults] setObject:contactsArray forKey:@"contacts"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    [self updateTable];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath * indexPath = [self.tableView indexPathForCell:sender];
    if ([segue.identifier isEqualToString:@"messageFromContacts"]) {
        UINavigationController *nav = [segue destinationViewController];
        ComposeTableViewController *controller = (ComposeTableViewController *)nav.topViewController;
        controller.fromContactsOrURL = YES;
        controller.reply_id = [[contactsArray[indexPath.row] allKeys] objectAtIndex:0];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [contactsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"contactCell"];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.detailTextLabel.text = [contactsArray[indexPath.row] allKeys][0]; // UUID
    cell.textLabel.text = [contactsArray[indexPath.row] allValues][0]; // Name
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self deleteContactNameForID:[contactsArray[indexPath.row] allKeys][0]];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"messageFromContacts" sender:self];
}

@end
