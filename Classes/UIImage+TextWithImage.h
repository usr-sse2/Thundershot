//
//  UIImage+UIImage_TextWithImage.h
//  Thundershot
//
//  Created by гык-sse2 on 27.06.15.
//
//

#import <UIKit/UIKit.h>

@interface UIImage (TextWithImage)
+ (UIImage*) imageFromText:(NSString*)title;
+ (UIImage*) imageFromText:(NSString *)title andImage:(UIImage *)image andRight:(BOOL)right;
@end
