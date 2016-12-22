#import "HUBCollectionViewLayoutFactory.h"

#import "HUBCollectionViewLayout.h"
#import "HUBIdentifier.h"
#import "HUBComponentWithChildren.h"
#import "HUBComponentRegistry.h"
#import "HUBComponentLayoutManager.h"
#import "HUBComponentModel.h"
#import "HUBViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface HUBCollectionViewLayoutFactory () <HUBComponentChildDelegate>

@property (nonatomic, strong, readonly) id<HUBComponentRegistry> componentRegistry;
@property (nonatomic, strong, readonly) id<HUBComponentLayoutManager> componentLayoutManager;
@property (nonatomic, strong, readonly) NSMutableDictionary<HUBIdentifier *, id<HUBComponent>> *componentCache;

@end

@implementation HUBCollectionViewLayoutFactory

- (instancetype)initWithComponentRegistry:(id<HUBComponentRegistry>)componentRegistry
                   componentLayoutManager:(id<HUBComponentLayoutManager>)componentLayoutManager
{
    NSParameterAssert(componentRegistry != nil);
    NSParameterAssert(componentLayoutManager != nil);
    
    self = [super init];
    
    if (self) {
        _componentRegistry = componentRegistry;
        _componentLayoutManager = componentLayoutManager;
    }
    
    return self;
}

- (UICollectionViewLayout *)createLayoutForCollectionViewWithSize:(CGSize)collectionViewSize
                                                        viewModel:(id<HUBViewModel>)viewModel
                                                             diff:(nullable HUBViewModelDiff *)diff
                                                   previousLayout:(nullable UICollectionViewLayout *)previousLayout
                                                  addHeaderMargin:(BOOL)addHeaderMargin
{
    BOOL componentIsInTopRow = YES;
    NSMutableArray<id<HUBComponent>> * const componentsOnCurrentRow = [NSMutableArray new];
    CGFloat currentRowMaxY = 0;
    CGPoint currentPoint = CGPointZero;
    CGPoint firstComponentOnCurrentRowOrigin = CGPointZero;
    NSUInteger const allComponentsCount = viewModel.bodyComponentModels.count;
    CGFloat maxBottomRowComponentHeight = 0;
    CGFloat maxBottomRowHeightWithMargins = 0;
    NSMutableDictionary<NSIndexPath *, UICollectionViewLayoutAttributes *> * const allLayoutAttributes = [NSMutableDictionary new];
    
    for (NSUInteger componentIndex = 0; componentIndex < allComponentsCount; componentIndex++) {
        id<HUBComponentModel> const componentModel = viewModel.bodyComponentModels[componentIndex];
        id<HUBComponent> const component = [self componentForModel:componentModel];
        NSSet<HUBComponentLayoutTrait> * const componentLayoutTraits = component.layoutTraits;
        BOOL isLastComponent = (componentIndex == allComponentsCount - 1);
        
        CGRect componentViewFrame = [self defaultViewFrameForComponent:component
                                                                 model:componentModel
                                                          currentPoint:currentPoint
                                                    collectionViewSize:collectionViewSize];
        
        UIEdgeInsets margins = [self defaultMarginsForComponent:component
                                                     isInTopRow:componentIsInTopRow
                                         componentsOnCurrentRow:componentsOnCurrentRow
                                             collectionViewSize:collectionViewSize
                                                      viewModel:viewModel
                                                addHeaderMargin:addHeaderMargin];
        
        componentViewFrame.origin.x = currentPoint.x + margins.left;
        
        BOOL couldFitOnTheRow = CGRectGetMaxX(componentViewFrame) + margins.right <= collectionViewSize.width;
        
        if (couldFitOnTheRow == NO) {
            [self updateLayoutAttributesIfNeeded:allLayoutAttributes
                                   forComponents:componentsOnCurrentRow
                              lastComponentIndex:(NSInteger)componentIndex - 1
                                 firstComponentX:firstComponentOnCurrentRowOrigin.x
                                  lastComponentX:currentPoint.x
                                        rowWidth:collectionViewSize.width];
            
            if (componentsOnCurrentRow.count > 0) {
                margins.top = 0;
                
                for (id<HUBComponent> const verticallyPrecedingComponent in componentsOnCurrentRow) {
                    CGFloat const marginToComponent = [self.componentLayoutManager verticalMarginForComponentWithLayoutTraits:componentLayoutTraits
                                                                                               precedingComponentLayoutTraits:verticallyPrecedingComponent.layoutTraits];
                    
                    if (marginToComponent > margins.top) {
                        margins.top = marginToComponent;
                    }
                }
            }
            
            componentViewFrame.origin.x = [self.componentLayoutManager marginBetweenComponentWithLayoutTraits:componentLayoutTraits
                                                                                               andContentEdge:HUBComponentLayoutContentEdgeLeft];
            
            componentViewFrame.origin.y = currentRowMaxY + margins.top;
            componentIsInTopRow = NO;
            [componentsOnCurrentRow removeAllObjects];
            currentPoint.y = CGRectGetMinY(componentViewFrame);
            currentRowMaxY = CGRectGetMaxY(componentViewFrame) + margins.bottom;
        } else {
            componentViewFrame.origin.y = currentPoint.y + margins.top;
        }
        
        componentViewFrame = [self horizontallyAdjustComponentViewFrame:componentViewFrame
                                                  forCollectionViewSize:collectionViewSize
                                                                margins:margins];
        
        currentPoint.x = CGRectGetMaxX(componentViewFrame);
        currentRowMaxY = MAX(currentRowMaxY, CGRectGetMaxY(componentViewFrame));
        
        NSIndexPath * const indexPath = [NSIndexPath indexPathForItem:(NSInteger)componentIndex inSection:0];
        UICollectionViewLayoutAttributes * const layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        layoutAttributes.frame = componentViewFrame;
        allLayoutAttributes[indexPath] = layoutAttributes;
        
        [componentsOnCurrentRow addObject:component];
        
        if (componentsOnCurrentRow.count == 1) {
            firstComponentOnCurrentRowOrigin = componentViewFrame.origin;
        }
        
        if (isLastComponent) {
            // We center components if needed when we go to a new row. If it is the last row we need to center it here
            [self updateLayoutAttributesIfNeeded:allLayoutAttributes
                                   forComponents:componentsOnCurrentRow
                              lastComponentIndex:(NSInteger)componentIndex
                                 firstComponentX:firstComponentOnCurrentRowOrigin.x
                                  lastComponentX:currentPoint.x
                                        rowWidth:collectionViewSize.width];
        }
    }
    
    CGSize const contentSize = [self contentSizeForContentHeight:currentRowMaxY
                                             bottomRowComponents:componentsOnCurrentRow
                                             minimumBottomMargin:maxBottomRowHeightWithMargins - maxBottomRowComponentHeight
                                              collectionViewSize:collectionViewSize];
    
    return [[HUBCollectionViewLayout alloc] initWithLayoutAttributes:allLayoutAttributes
                                                         contentSize:contentSize
                                                      previousLayout:previousLayout
                                                                diff:diff];
}

#pragma mark - HUBComponentChildDelegate

- (id<HUBComponent>)component:(id<HUBComponentWithChildren>)component childComponentForModel:(id<HUBComponentModel>)childComponentModel
{
    return [self componentForModel:childComponentModel];
}

- (void)component:(id<HUBComponentWithChildren>)component willDisplayChildAtIndex:(NSUInteger)childIndex view:(UIView *)childView
{
    // No-op
}

- (void)component:(id<HUBComponentWithChildren>)component didStopDisplayingChildAtIndex:(NSUInteger)childIndex view:(UIView *)childView
{
    // No-op
}

- (void)component:(id<HUBComponentWithChildren>)component
childWithCustomViewSelectedAtIndex:(NSUInteger)childIndex
       customData:(nullable NSDictionary<NSString *, id> *)customData
{
    // No-op
}

#pragma mark - Private utilities

- (id<HUBComponent>)componentForModel:(id<HUBComponentModel>)model
{
    id<HUBComponent> const cachedComponent = self.componentCache[model.componentIdentifier];
    
    if (cachedComponent != nil) {
        return cachedComponent;
    }
    
    id<HUBComponent> const newComponent = [self.componentRegistry createComponentForModel:model];
    self.componentCache[model.componentIdentifier] = newComponent;
    
    if ([newComponent conformsToProtocol:@protocol(HUBComponentWithChildren)]) {
        ((id<HUBComponentWithChildren>)newComponent).childDelegate = self;
    }
    
    return newComponent;
}

- (UIEdgeInsets)defaultMarginsForComponent:(id<HUBComponent>)component
                                isInTopRow:(BOOL)componentIsInTopRow
                    componentsOnCurrentRow:(NSArray<id<HUBComponent>> *)componentsOnCurrentRow
                        collectionViewSize:(CGSize)collectionViewSize
                                 viewModel:(id<HUBViewModel>)viewModel
                           addHeaderMargin:(BOOL)addHeaderMargin
{
    NSSet<HUBComponentLayoutTrait> * const componentLayoutTraits = component.layoutTraits;
    UIEdgeInsets margins = UIEdgeInsetsZero;
    
    if (componentIsInTopRow) {
        id<HUBComponentModel> const headerComponentModel = viewModel.headerComponentModel;
        
        if (headerComponentModel != nil) {
            if (addHeaderMargin) {
                id<HUBComponent> const headerComponent = [self componentForModel:headerComponentModel];
                CGSize headerSize = [headerComponent preferredViewSizeForDisplayingModel:headerComponentModel containerViewSize:collectionViewSize];
                margins.top = headerSize.height + [self.componentLayoutManager verticalMarginBetweenComponentWithLayoutTraits:componentLayoutTraits
                                                                                           andHeaderComponentWithLayoutTraits:headerComponent.layoutTraits];
            }
        } else {
            margins.top = [self.componentLayoutManager marginBetweenComponentWithLayoutTraits:componentLayoutTraits
                                                                               andContentEdge:HUBComponentLayoutContentEdgeTop];
        }
    }
    
    if (componentsOnCurrentRow.count == 0) {
        margins.left = [self.componentLayoutManager marginBetweenComponentWithLayoutTraits:componentLayoutTraits
                                                                            andContentEdge:HUBComponentLayoutContentEdgeLeft];
    } else {
        id<HUBComponent> const precedingComponent = [componentsOnCurrentRow lastObject];
        margins.left = [self.componentLayoutManager horizontalMarginForComponentWithLayoutTraits:componentLayoutTraits
                                                                  precedingComponentLayoutTraits:precedingComponent.layoutTraits];
    }
    
    margins.right = [self.componentLayoutManager marginBetweenComponentWithLayoutTraits:componentLayoutTraits
                                                                         andContentEdge:HUBComponentLayoutContentEdgeRight];
    
    return margins;
}

- (CGRect)defaultViewFrameForComponent:(id<HUBComponent>)component
                                 model:(id<HUBComponentModel>)componentModel
                          currentPoint:(CGPoint)currentPoint
                    collectionViewSize:(CGSize)collectionViewSize
{
    CGRect componentViewFrame = CGRectZero;
    componentViewFrame.size = [component preferredViewSizeForDisplayingModel:componentModel containerViewSize:collectionViewSize];
    componentViewFrame.size.width = MIN(CGRectGetWidth(componentViewFrame), collectionViewSize.width);
    return componentViewFrame;
}

- (CGRect)horizontallyAdjustComponentViewFrame:(CGRect)componentViewFrame forCollectionViewSize:(CGSize)collectionViewSize margins:(UIEdgeInsets)margins
{
    CGFloat const horizontalOverflow = CGRectGetMaxX(componentViewFrame) + margins.right - collectionViewSize.width;
    
    if (horizontalOverflow > 0) {
        componentViewFrame.size.width -= horizontalOverflow;
    }
    
    return componentViewFrame;
}

- (CGSize)contentSizeForContentHeight:(CGFloat)contentHeight
                  bottomRowComponents:(NSArray<id<HUBComponent>> *)bottomRowComponents
                  minimumBottomMargin:(CGFloat)minimumBottomMargin
                   collectionViewSize:(CGSize)collectionViewSize
{
    CGFloat viewBottomMargin = 0;
    
    for (id<HUBComponent> const component in bottomRowComponents) {
        CGFloat const componentBottomMargin = [self.componentLayoutManager marginBetweenComponentWithLayoutTraits:component.layoutTraits
                                                                                                   andContentEdge:HUBComponentLayoutContentEdgeBottom];
        
        viewBottomMargin = MAX(viewBottomMargin, componentBottomMargin);
    }
    
    contentHeight += MAX(viewBottomMargin, minimumBottomMargin);
    
    return CGSizeMake(collectionViewSize.width, contentHeight);
}

- (void)updateLayoutAttributesIfNeeded:(NSMutableDictionary<NSIndexPath *, UICollectionViewLayoutAttributes *> *)allLayoutAttribtues
                         forComponents:(NSArray<id<HUBComponent>> *)components
                    lastComponentIndex:(NSInteger)lastComponentIndex
                       firstComponentX:(CGFloat)firstComponentX
                        lastComponentX:(CGFloat)lastComponentX
                              rowWidth:(CGFloat)rowWidth
{
    if (lastComponentIndex == 0) {
        return;
    }
    
    NSArray<NSSet<HUBComponentLayoutTrait> *> * const layoutTraits = [components valueForKey:NSStringFromSelector(@selector(layoutTraits))];
    
    CGFloat const adjustment = [self.componentLayoutManager horizontalOffsetForComponentsWithLayoutTraits:layoutTraits
                                                                    firstComponentLeadingHorizontalOffset:firstComponentX
                                                                    lastComponentTrailingHorizontalOffset:rowWidth - lastComponentX];
    
    if (adjustment == 0.0) {
        return;
    }
    
    NSUInteger const indexOfFirstComponentOnTheRow = (NSUInteger)lastComponentIndex - components.count + 1;
    
    for (NSUInteger index = indexOfFirstComponentOnTheRow; index <= (NSUInteger)lastComponentIndex; index++) {
        NSIndexPath * const indexPath = [NSIndexPath indexPathForItem:(NSInteger)index inSection:0];
        UICollectionViewLayoutAttributes * const layoutAttributes = allLayoutAttribtues[indexPath];
        layoutAttributes.frame = CGRectOffset(layoutAttributes.frame, adjustment, 0);
    }
}

@end

NS_ASSUME_NONNULL_END
