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
    NSUserDefaults *defaults;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    defaults = [[NSUserDefaults alloc] initWithSuiteName:@"ninja.orthros.group.suite"];
    orthros = [[liborthros alloc] initWithUUID:[defaults objectForKey:@"UUID"]];
    
    // Do any additional setup after loading the view.
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

@end
