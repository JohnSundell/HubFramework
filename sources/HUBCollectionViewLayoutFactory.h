#import <UIKit/UIKit.h>
#import "HUBHeaderMacros.h"

@protocol HUBComponentRegistry;
@protocol HUBComponentLayoutManager;
@protocol HUBViewModel;
@class HUBViewModelDiff;

NS_ASSUME_NONNULL_BEGIN

@interface HUBCollectionViewLayoutFactory : NSObject

- (instancetype)initWithComponentRegistry:(id<HUBComponentRegistry>)componentRegistry
                   componentLayoutManager:(id<HUBComponentLayoutManager>)componentLayoutManager HUB_DESIGNATED_INITIALIZER;

- (UICollectionViewLayout *)createLayoutForCollectionViewWithSize:(CGSize)collectionViewSize
                                                        viewModel:(id<HUBViewModel>)viewModel
                                                             diff:(nullable HUBViewModelDiff *)diff
                                                   previousLayout:(nullable UICollectionViewLayout *)previousLayout
                                                  addHeaderMargin:(BOOL)addHeaderMargin;

@end

NS_ASSUME_NONNULL_END
