#import <UIKit/UIKit.h>
#import "ThundershotAVController.h"

@interface ThundershotAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    IBOutlet ThundershotAVController *avController;
}

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) IBOutlet ThundershotAVController *avController;
@end

