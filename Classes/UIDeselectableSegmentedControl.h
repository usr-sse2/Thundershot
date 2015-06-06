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
@property (nonatomic) NSInteger current;
@property (strong, nonatomic) NSMutableArray* titleStrings;
@property (strong, nonatomic) UIImage* image;
@property (nonatomic) NSInteger selectedSegmentNumber;
@property (nonatomic, strong) UIButton *theButton;
@property (nonatomic) CGRect maxFrame;

- (void) setTitles:(NSString*)first, ... NS_REQUIRES_NIL_TERMINATION;
//- (NSInteger)getSelectedSegmentNumber;


@end
