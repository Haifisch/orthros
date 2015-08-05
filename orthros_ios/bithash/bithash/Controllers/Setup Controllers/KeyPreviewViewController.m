//
//  KeyPreviewViewController.m
//  bithash
//
//  Created by Haifisch on 2/15/15.
//  Copyright (c) 2015 Haifisch. All rights reserved.
//

#import "KeyPreviewViewController.h"
#import "JNKeychain.h"
#import "Common.h"

@interface KeyPreviewViewController ()
@property (strong, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (strong, nonatomic) IBOutlet UITextView *keyView;

@end

@implementation KeyPreviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Public Key", @"Private Key", nil]];
    self.segmentedControl.selectedSegmentIndex = 0;
    [self.segmentedControl addTarget:self action:@selector(segmentedValueChanged:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = self.segmentedControl;
    [self segmentedValueChanged:self.segmentedControl];
    
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)segmentedValueChanged:(id)sender {
    UISegmentedControl *segControl = (UISegmentedControl *)sender;
    if (segControl.selectedSegmentIndex == 0) {
        self.keyView.text = [JNKeychain loadValueForKey:PUB_KEY];
    }else {
        self.keyView.text = [JNKeychain loadValueForKey:PRIV_KEY];
    }
}

- (IBAction)exitPreview:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
