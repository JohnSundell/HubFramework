/*
 *  Copyright (c) 2016 Spotify AB.
 *
 *  Licensed to the Apache Software Foundation (ASF) under one
 *  or more contributor license agreements.  See the NOTICE file
 *  distributed with this work for additional information
 *  regarding copyright ownership.  The ASF licenses this file
 *  to you under the Apache License, Version 2.0 (the
 *  "License"); you may not use this file except in compliance
 *  with the License.  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */

#import "HUBViewModelRenderer.h"
#import "HUBViewModelDiff.h"
#import "HUBCollectionViewLayout.h"
#import "HUBResizeAnimation.h"

NS_ASSUME_NONNULL_BEGIN

@interface HUBViewModelRenderer ()

@property (nonatomic, strong, readonly) UICollectionView *collectionView;
@property (nonatomic, strong, readonly) HUBCollectionViewLayout *layout;
@property (nonatomic, strong, nullable) id<HUBViewModel> lastRenderedViewModel;

@end

@implementation HUBViewModelRenderer

#pragma mark - Initializer

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView
                                layout:(HUBCollectionViewLayout *)layout
{
    NSParameterAssert(collectionView != nil);
    NSParameterAssert(layout != nil);
    
    self = [super init];
    
    if (self != nil) {
        _collectionView = collectionView;
        _layout = layout;
    }
    
    return self;
}

#pragma mark - API

- (void)renderViewModel:(id<HUBViewModel>)viewModel
      usingBatchUpdates:(BOOL)usingBatchUpdates
               animated:(BOOL)animated
             completion:(void (^)(void))completionBlock
{
    HUBViewModelDiff *diff;
    
    if (self.lastRenderedViewModel != nil) {
        id<HUBViewModel> nonnullViewModel = self.lastRenderedViewModel;
        diff = [HUBViewModelDiff diffFromViewModel:nonnullViewModel toViewModel:viewModel];
    }
    
    if (!usingBatchUpdates || diff == nil) {
        [self.collectionView reloadData];
        
        [self.layout computeForCollectionViewSize:self.collectionView.frame.size viewModel:viewModel diff:diff];

        /* Below is a workaround for an issue caused by UICollectionView not asking for numberOfItemsInSection
           before viewDidAppear is called or instantly after a call to reloadData. If reloadData is called
           after viewDidAppear has been called, followed by a call to performBatchUpdates, UICollectionView will
           ask for the initial number of items right before the batch updates, and for the new count while inside
           the update block. This will often trigger an assertion if there are any insertions / deletions, as
           the data model has already changed before the update. Forcing a layoutSubviews however, manually
           triggers the numberOfItems call.
         */
        if (usingBatchUpdates && diff == nil) {
            [self.collectionView setNeedsLayout];
            [self.collectionView layoutIfNeeded];
        }
        completionBlock();
    } else {
        void (^updateBlock)() = ^{
            [self.collectionView performBatchUpdates:^{
                [self.collectionView insertItemsAtIndexPaths:diff.insertedBodyComponentIndexPaths];
                [self.collectionView deleteItemsAtIndexPaths:diff.deletedBodyComponentIndexPaths];
                [self.collectionView reloadItemsAtIndexPaths:diff.reloadedBodyComponentIndexPaths];
                
                [self.layout computeForCollectionViewSize:self.collectionView.frame.size viewModel:viewModel diff:diff];
            } completion:^(BOOL finished) {
                completionBlock();
            }];
        };
        
        if (animated) {
            updateBlock();
        } else {
            [UIView performWithoutAnimation:updateBlock];
        }
    }

    self.lastRenderedViewModel = viewModel;
}

#pragma mark - HUBAnimationPerformer

- (void)performResizeAnimation:(HUBResizeAnimation *)animation
{
    HUBCollectionViewLayout * const newLayout = [[HUBCollectionViewLayout alloc] initWithComponentRegistry:self.layout.componentRegistry
                                                                                    componentLayoutManager:self.layout.componentLayoutManager];
    
    NSDictionary<NSString *, NSValue *> * const componentViewSizes = animation.targetComponentViewSizes;
    
    for (NSString * const componentModelIdentifier in componentViewSizes) {
        CGSize const viewSize = componentViewSizes[componentModelIdentifier].CGSizeValue;
        [newLayout addViewSize:viewSize forComponentModelIdentifier:componentModelIdentifier];
    }
    
    id<HUBViewModel> const currentViewModel = self.lastRenderedViewModel;
    
    [newLayout computeForCollectionViewSize:self.collectionView.frame.size viewModel:currentViewModel diff:nil];
    
    [UIView animateWithDuration:animation.duration delay:0 options:UIViewAnimationOptionLayoutSubviews animations:^{
        self.collectionView.collectionViewLayout = newLayout;
        animation.animationBlock();
    } completion:^(BOOL finished) {
        
    }];
}

@end

NS_ASSUME_NONNULL_END
