#import <Foundation/Foundation.h>

@class HUBResizeAnimation;

@protocol HUBAnimationPerformer <NSObject>

- (void)performResizeAnimation:(HUBResizeAnimation *)animation;

@end
