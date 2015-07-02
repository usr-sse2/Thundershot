//
//  UIView+LayerShot.h
//
//  Created by Jens Kreiensiek on 29.06.12.
//  Copyright (c) 2012 SoButz. All rights reserved.
//
#import <UIKit/UIKit.h>

@interface UIView (LayerShot)
- (UIImage *)imageFromLayer;
- (UIImage *)imageFromLayerWithTransform: (CGAffineTransform) transform;
@end