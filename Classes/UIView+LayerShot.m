//
//  UIView+LayerShot.m
//
//  Created by Jens Kreiensiek on 29.06.12.
//  Copyright (c) 2012 SoButz. All rights reserved.
//
#import "UIView+LayerShot.h"
#import <QuartzCore/QuartzCore.h>

@implementation UIView (LayerShot)

- (UIImage *)imageFromLayer
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end