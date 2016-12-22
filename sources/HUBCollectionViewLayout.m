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

#import "HUBCollectionViewLayout.h"

#import "HUBViewModelDiff.h"

NS_ASSUME_NONNULL_BEGIN

static inline void HUBCollectionViewLayoutForEachVerticalGroupInRect(CGRect rect, void(^block)(NSInteger)) {
    CGFloat const verticalGroupSize = 100;
    NSInteger const maxVerticalGroup = (NSInteger)(floor(CGRectGetMaxY(rect) / verticalGroupSize));
    NSInteger currentVerticalGroup = (NSInteger)(floor(CGRectGetMinY(rect) / verticalGroupSize));
    
    while (currentVerticalGroup <= maxVerticalGroup) {
        block(currentVerticalGroup);
        currentVerticalGroup++;
    }
}

@interface HUBCollectionViewLayout ()

@property (nonatomic, strong, readonly) NSDictionary<NSIndexPath *, UICollectionViewLayoutAttributes *> *layoutAttributes;
@property (nonatomic, assign, readonly) CGSize contentSize;
@property (nonatomic, strong, readonly) NSDictionary<NSNumber *, NSMutableSet<NSIndexPath *> *> *indexPathsByVerticalGroup;
@property (nonatomic, strong, nullable, readonly) UICollectionViewLayout *previousLayout;
@property (nonatomic, strong, nullable, readonly) HUBViewModelDiff *diff;

@end

@implementation HUBCollectionViewLayout

#pragma mark - Initializer

- (instancetype)initWithLayoutAttributes:(NSDictionary<NSIndexPath *, UICollectionViewLayoutAttributes *> *)layoutAttributes
                             contentSize:(CGSize)contentSize
                          previousLayout:(nullable UICollectionViewLayout *)previousLayout
                                    diff:(nullable HUBViewModelDiff *)diff
{
    self = [super init];
    
    if (self) {
        _layoutAttributes = [layoutAttributes copy];
        _contentSize = contentSize;
        _previousLayout = previousLayout;
        _diff = diff;
        
        NSMutableDictionary<NSNumber *, NSMutableSet<NSIndexPath *> *> * const indexPathsByVerticalGroup = [NSMutableDictionary new];
        
        for (NSIndexPath * const indexPath in layoutAttributes) {
            UICollectionViewLayoutAttributes * const layoutAttributesForIndexPath = layoutAttributes[indexPath];
            
            HUBCollectionViewLayoutForEachVerticalGroupInRect(layoutAttributesForIndexPath.frame, ^(NSInteger groupIndex) {
                NSNumber * const encodedGroupIndex = @(groupIndex);
                NSMutableSet<NSIndexPath *> *indexPathsInGroup = indexPathsByVerticalGroup[encodedGroupIndex];
                
                if (indexPathsInGroup == nil) {
                    indexPathsInGroup = [NSMutableSet new];
                    indexPathsByVerticalGroup[encodedGroupIndex] = indexPathsInGroup;
                }
                
                [indexPathsInGroup addObject:indexPath];
            });
        }
        
        _indexPathsByVerticalGroup = indexPathsByVerticalGroup;
    }
    
    return self;
}

#pragma mark - UICollectionViewLayout

- (nullable NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray<UICollectionViewLayoutAttributes *> * const layoutAttributes = [NSMutableArray new];
    
    HUBCollectionViewLayoutForEachVerticalGroupInRect(rect, ^(NSInteger groupIndex) {
        for (NSIndexPath * const indexPath in self.indexPathsByVerticalGroup[@(groupIndex)]) {
            UICollectionViewLayoutAttributes * const layoutAttributesForIndexPath = [self layoutAttributesForItemAtIndexPath:indexPath];
            
            if (layoutAttributesForIndexPath != nil) {
                [layoutAttributes addObject:layoutAttributesForIndexPath];
            }
        }
    });
    
    return layoutAttributes;
}

- (nullable UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.layoutAttributes[indexPath];
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return YES;
}

- (CGSize)collectionViewContentSize
{
    return self.contentSize;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset
{
    if (self.previousLayout == nil || self.diff == nil) {
        return proposedContentOffset;
    }
    
    CGPoint offset = self.collectionView.contentOffset;
    
    NSInteger topmostVisibleIndex = NSNotFound;
    
    for (NSIndexPath *indexPath in [self.collectionView indexPathsForVisibleItems]) {
        topmostVisibleIndex = MIN(topmostVisibleIndex, indexPath.item);
    }
    
    if (topmostVisibleIndex == NSNotFound) {
        topmostVisibleIndex = 0;
    }
    
    for (NSIndexPath *indexPath in self.diff.insertedBodyComponentIndexPaths) {
        if (indexPath.item < topmostVisibleIndex) {
            UICollectionViewLayoutAttributes * const attributes = self.layoutAttributes[indexPath];
            offset.y += CGRectGetHeight(attributes.frame);
        }
    }
    
    for (NSIndexPath *indexPath in self.diff.deletedBodyComponentIndexPaths) {
        if (indexPath.item <= topmostVisibleIndex) {
            UICollectionViewLayoutAttributes * const attributes = [self.previousLayout layoutAttributesForItemAtIndexPath:indexPath];
            offset.y -= CGRectGetHeight(attributes.frame);
        }
    }
    
    // Making sure the content offset doesn't go through the roof.
    CGFloat const minContentOffset = -self.collectionView.contentInset.top;
    offset.y = MAX(minContentOffset, offset.y);
    // ...or beyond the bottom.
    CGFloat maxContentOffset = MAX(self.contentSize.height + self.collectionView.contentInset.bottom - CGRectGetHeight(self.collectionView.frame), minContentOffset);
    offset.y = MIN(maxContentOffset, offset.y);
    
    return offset;
}

@end

NS_ASSUME_NONNULL_END
