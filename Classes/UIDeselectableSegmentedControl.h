//
//  UIDeselectableSegmentedControl.h
//  Thundershot
//
//  Created by гык-sse2 on 05.08.13.
//
//

#import <UIKit/UIKit.h>

@interface UIDeselectableSegmentedControl : UISegmentedControl

@property (nonatomic) BOOL right;
@property (strong, nonatomic) UIImage* image;

- (void) setTitles:(NSString*)first, ... NS_REQUIRES_NIL_TERMINATION;

@end
