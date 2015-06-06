//
//  UIDeselectableSegmentedControl.m
//  Thundershot
//
//  Created by гык-sse2 on 05.08.13.
//
//

#import "UIDeselectableSegmentedControl.h"
#import "UIView+LayerShot.h"
#import "UIButtonRight.h"



@implementation UIDeselectableSegmentedControl
@synthesize theButton;


- (void) setSelectedSegmentIndex:(NSInteger)toValue {
    if (toValue != UISegmentedControlNoSegment) { // show toValue
        [super removeAllSegments];
        [self insertSegmentWithTitle:[self.titleStrings objectAtIndex:toValue] andImage:self.image atIndex:0 animated:NO];
        [self sizeToFit];
        [super setSelectedSegmentIndex:0];
        self.selectedSegmentNumber = toValue;
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
        
        [super setSelectedSegmentIndex:UISegmentedControlNoSegment];
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
        [super setSelectedSegmentIndex:UISegmentedControlNoSegment];
        self.selectedSegmentNumber = UISegmentedControlNoSegment;
    }

    //[self sizeToFit];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}
/*
- (NSInteger)getSelectedSegmentNumber {
    if (self.selectedSegmentIndex == UISegmentedControlNoSegment)
        return UISegmentedControlNoSegment;
    NSString* s = [self titleForSegmentAtIndex:self.selectedSegmentIndex];
    for (NSInteger i = 0; i < self.titleStrings.count; ++i)
        if ([s isEqualToString:[self.titleStrings objectAtIndex:i]])
            return i;
    return UISegmentedControlNoSegment;
}
*/
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    self.current = self.selectedSegmentIndex;//[super valueForKey:@"_selectedSegment"];
    [super touchesBegan:touches withEvent:event];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    if (self.current == self.selectedSegmentIndex) { // было ничего не выбрано и стало тоже???
        [self setSelectedSegmentIndex:UISegmentedControlNoSegment];
    }
    else {
        [self setSelectedSegmentIndex:self.selectedSegmentIndex];
    }
}

- (void) setTitles:(NSString*)first, ... NS_REQUIRES_NIL_TERMINATION {
    if (!self.theButton)
        self.theButton = [self.right ? [UIButtonRight alloc] : [UIButton alloc] init];
    
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
    NSMutableAttributedString* attributedTitle = [[NSMutableAttributedString alloc] initWithString:(title ?: @"")]; // ух ты, разве так можно?
    [attributedTitle addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, [title length])];
    [attributedTitle addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"Helvetica" size:11.0f] range:NSMakeRange(0, [title length])];
    
    [self.theButton setAttributedTitle:attributedTitle forState:UIControlStateNormal];
    //[self.theButton setTitle:title forState:UIControlStateNormal];
    [self.theButton setImage:image forState:UIControlStateNormal];
    [self.theButton sizeToFit];
    
    
    
    [self insertSegmentWithImage:[self.theButton imageFromLayer] atIndex:index animated:animated];
    //[self insertSegmentWithTitle:title atIndex:index animated:animated];
}

/*- (void) setImagesAndTitles:(id)firstImage, ... NS_REQUIRES_NIL_TERMINATION {
    if (!self.theButton)
        self.theButton = [[UIButton alloc] init];
    id firstTitle = nil;
    NSUInteger i = 0;
    self.titleStrings = [[NSMutableArray alloc] init];
    va_list args;
    va_start(args, firstImage);
    for (id arg = firstImage; arg != nil; arg = va_arg(args, id), ++i) {
        [self.titleStrings addObject:arg];
        if (i == 1)
            firstTitle = arg;
    }
    [self removeAllSegments];
    self.apportionsSegmentWidthsByContent = YES;
    
    
    [self insertSegmentWithTitle:firstTitle andImage:firstImage atIndex:0 animated:NO];
    [self setSelectedSegmentIndex:0];
    [self sizeToFit];
    va_end(args);
}*/

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
