//
//  ViewController.m
//  Orthros - Mac
//
//  Created by haifisch on 7/6/15.
//  Copyright (c) 2015 Haifisch. All rights reserved.
//

#import "ViewController.h"
#import "liborthros.h"
@implementation ViewController {
    liborthros *orthros;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    orthros = [[liborthros alloc] initWithUUID:[[NSUserDefaults standardUserDefaults] objectForKey:@"UUID"]];
    
    // Do any additional setup after loading the view.
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

@end
