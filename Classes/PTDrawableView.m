//
//  PTDrawableView.m
//  Thundershot
//
//  Created by гык-sse2 on 14.09.14.
//
//

#import "PTDrawableView.h"

@implementation PTDrawableView


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    [super drawRect:rect];
    NSLog(@"called");
    CGContextRef ctx = UIGraphicsGetCurrentContext(); //get the graphics context
    CGContextSetRGBStrokeColor(ctx, 1.0, 0, 0, 1); //there are two relevant color states, "Stroke" -- used in Stroke drawing functions and "Fill" - used in fill drawing functions
    //now we build a "path"
    //you can either directly build it on the context or build a path object, here I build it on the context
    CGContextMoveToPoint(ctx, 0, 0);
    //add a line from 0,0 to the point 100,100
    CGContextAddLineToPoint( ctx, 100,100);
    //"stroke" the path
    CGContextStrokePath(ctx);
}


@end
