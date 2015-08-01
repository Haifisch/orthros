//
//  MyQRViewController.m
//  Orthros
//
//  Created by Haifisch on 5/18/15.
//  Copyright (c) 2015 Haifisch. All rights reserved.
//

#import "MyQRViewController.h"
#import "DeviceIdentifiers.h"
#import "UIImage+ResizeAdditions.h"

@interface MyQRViewController () {
    DeviceIdentifiers *identify;
}

@property (strong, nonatomic) IBOutlet UIImageView *qrImage;
@end

@implementation MyQRViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.backgroundColor = [UIColor colorWithRed:33/255.0f green:33/255.0f blue:33/255.0f alpha:1];
    [self.tableView setSeparatorColor:[UIColor colorWithRed:33/255.0f green:33/255.0f blue:33/255.0f alpha:1]];
    
    identify = [[DeviceIdentifiers alloc] init];
    self.title = @"My QR";
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [filter setDefaults];
    NSData *data = [[identify UUID] dataUsingEncoding:NSUTF8StringEncoding];
    [filter setValue:data forKey:@"inputMessage"];
    CIImage *outputImage = [filter outputImage];
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [context createCGImage:outputImage
                                       fromRect:[outputImage extent]];
    UIImage *image = [[UIImage imageWithCGImage:cgImage
                                         scale:1.
                                   orientation:UIImageOrientationUp] resizedImage:CGSizeMake(300, 300) interpolationQuality:kCGInterpolationNone];
    self.qrImage.image = image;
    CGImageRelease(cgImage);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIImage *)resizeImage:(UIImage *)image
             withQuality:(CGInterpolationQuality)quality
                    rate:(CGFloat)rate
{
    UIImage *resized = nil;
    CGFloat width = image.size.width * rate;
    CGFloat height = image.size.height * rate;
    
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, quality);
    [image drawInRect:CGRectMake(0, 0, width, height)];
    resized = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resized;
}

- (IBAction)finishup:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}
@end
