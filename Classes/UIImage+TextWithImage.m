//
//  UIImage+UIImage_TextWithImage.m
//  Thundershot
//
//  Created by гык-sse2 on 27.06.15.
//
//

#import "UIImage+TextWithImage.h"
#import "UIView+LayerShot.h"
#import "UIButtonRight.h"

@implementation UIImage (TextWithImage)

static UIButton *leftButton = nil;
static UIButton *rightButton = nil;

+ (UIImage*) imageFromText:(NSString*)title {
	if (!leftButton)
		leftButton = [[UIButton alloc] init];
	
	NSMutableAttributedString* attributedTitle = [[NSMutableAttributedString alloc] initWithString:title];
	[attributedTitle addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, [title length])];
	[attributedTitle addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"Helvetica" size:11.0f] range:NSMakeRange(0, [title length])];
	[leftButton setImage:nil forState:UIControlStateNormal];
	[leftButton setAttributedTitle:attributedTitle forState:UIControlStateNormal];
	[leftButton sizeToFit];
	return [leftButton imageFromLayer];
}

+ (UIImage*) imageFromText:(NSString *)title andImage:(UIImage *)image andRight:(BOOL)right {
	if (!leftButton)
		leftButton = [[UIButton alloc] init];
	if (!rightButton)
		rightButton = [[UIButtonRight alloc] init];
	
	UIButton* button = right ? rightButton : leftButton;
	
	NSMutableAttributedString* attributedTitle = [[NSMutableAttributedString alloc] initWithString:(title ?: @"")]; // ух ты, разве так можно?
	[attributedTitle addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, [title length])];
	[attributedTitle addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"Helvetica" size:11.0f] range:NSMakeRange(0, [title length])];
	
	[button setAttributedTitle:attributedTitle forState:UIControlStateNormal];
	[button setImage:image forState:UIControlStateNormal];
	[button sizeToFit];
	return [button imageFromLayer];
}

@end
