//
//  UIDeselectableSegmentedControl.m
//  Thundershot
//
//  Created by гык-sse2 on 05.08.13.
//
//

#import "UIDeselectableSegmentedControl.h"
#import "UIImage+TextWithImage.h"
#import "UIButtonRight.h"

@interface UIDeselectableSegmentedControl ()

@property (nonatomic) NSInteger current;
@property (strong, nonatomic) NSMutableArray* titleStrings;
@property (nonatomic) NSInteger selectedSegmentNumber;
@property (nonatomic) CGRect maxFrame;

@end

@implementation UIDeselectableSegmentedControl


- (NSInteger) selectedSegmentIndex {
	return self.selectedSegmentNumber; // а не Index
}

- (void) setSelectedSegmentIndex:(NSInteger)toValue {
	if (toValue != UISegmentedControlNoSegment) { // show toValue
        [super removeAllSegments];
        [self insertSegmentWithTitle:[self.titleStrings objectAtIndex:toValue] andImage:self.image atIndex:0 animated:NO];
        [self sizeToFit];
		super.selectedSegmentIndex = 0;
        self.selectedSegmentNumber = toValue;
		[self sendActionsForControlEvents:UIControlEventValueChanged];
    }
    else if (!self.right) { // show all
        //[super setTitle:[self.titleStrings objectAtIndex:0] forSegmentAtIndex:0];
        [super removeAllSegments];
        self.frame = self.maxFrame;
        [self insertSegmentWithTitle:[self.titleStrings objectAtIndex:0] andImage:self.image atIndex:0 animated:NO];
        
        for (NSInteger i = 1; i < self.titleStrings.count; ++i) {
            [self insertSegmentWithTitle:[self.titleStrings objectAtIndex:i] andImage:nil atIndex:i animated:NO];
            [self sizeToFit];
        }
        
		super.selectedSegmentIndex = UISegmentedControlNoSegment;
        self.selectedSegmentNumber = UISegmentedControlNoSegment;
    }
    else { // show all
        //[super setTitle:[self.titleStrings objectAtIndex:0] forSegmentAtIndex:0];
        [super removeAllSegments];
        self.frame = self.maxFrame;
        [self insertSegmentWithTitle:[self.titleStrings objectAtIndex:self.titleStrings.count-1] andImage:self.image atIndex:0 animated:NO];
        
        for (NSInteger i = self.titleStrings.count-2; i >= 0; --i) {
            [self insertSegmentWithTitle:[self.titleStrings objectAtIndex:i] andImage:nil atIndex:0 animated:NO];
            [self sizeToFit];
        }
		
		super.selectedSegmentIndex= UISegmentedControlNoSegment;
        self.selectedSegmentNumber = UISegmentedControlNoSegment;
    }
	[self setNeedsLayout];
	[self layoutIfNeeded];
	[self setNeedsUpdateConstraints];
	
    //[self sizeToFit];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    self.current = super.selectedSegmentIndex;
    [super touchesBegan:touches withEvent:event];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    if (self.current == super.selectedSegmentIndex) // было ничего не выбрано и стало тоже???
		self.selectedSegmentIndex = UISegmentedControlNoSegment;
    else
        self.selectedSegmentIndex = super.selectedSegmentIndex;
}

- (void) setTitles:(NSString*)first, ... NS_REQUIRES_NIL_TERMINATION {
    self.titleStrings = [[NSMutableArray alloc] init];
    va_list args;
    va_start(args, first);
    for (NSString *arg = first; arg != nil; arg = va_arg(args, NSString*)) {
        [self.titleStrings addObject:arg];
    }

    // Measurement
    [super removeAllSegments];
    for (NSInteger i = 0; i < self.titleStrings.count; ++i) {
        [self insertSegmentWithTitle:[self.titleStrings objectAtIndex:i] andImage:nil atIndex:i animated:NO];
    }
    [self sizeToFit];
    self.maxFrame = self.frame;
    // End of measurement
    
    [self removeAllSegments];
    self.apportionsSegmentWidthsByContent = YES;
    [self insertSegmentWithTitle:first andImage:self.image atIndex:0 animated:NO];
    [self setSelectedSegmentIndex:0];
    [self sizeToFit];
    va_end(args);
}

-(void)insertSegmentWithTitle:(NSString*)title andImage:(UIImage*)image atIndex:(NSUInteger)index animated:(BOOL)animated {
	[self insertSegmentWithImage:[UIImage imageFromText:title andImage:image andRight:self.right] atIndex:index animated:animated];
}

@end
