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

#import <XCTest/XCTest.h>

#import "HUBCollectionViewMock.h"
#import "HUBComponentRegistryMock.h"
#import "HUBComponentLayoutManagerMock.h"
#import "HUBViewModelRenderer.h"
#import "HUBViewModelUtilities.h"
#import "HUBCollectionViewLayoutFactory.h"

/**
 *  We don't want these tests to be concerned with the inner workings of the batch update process, as this invokes
 *  a lot of collection view logic that over-complicates the test (e.g. checking that the items rendered before
 *  the batch update tallies with the number of items after the batch update).
 *
 *  To get around this, we override the insert, delete and reload methods to do nothing.
 */
@interface HUBCollectionViewMockWithoutBatchUpdates : HUBCollectionViewMock

@property (nonatomic, assign) NSUInteger reloadDataCount;
@property (nonatomic, strong, readonly) NSMutableArray<NSIndexPath *> *insertedItemIndexPaths;
@property (nonatomic, strong, readonly) NSMutableArray<NSIndexPath *> *deletedItemIndexPaths;
@property (nonatomic, strong, readonly) NSMutableArray<NSIndexPath *> *reloadedItemIndexPaths;

@end

@implementation HUBCollectionViewMockWithoutBatchUpdates

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout
{
    self = [super initWithFrame:frame collectionViewLayout:layout];
    
    if (self) {
        _insertedItemIndexPaths = [NSMutableArray new];
        _deletedItemIndexPaths = [NSMutableArray new];
        _reloadedItemIndexPaths = [NSMutableArray new];
    }
    
    return self;
}

- (void)reloadData
{
    self.reloadDataCount += 1;
}

- (void)insertItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
{
    [self.insertedItemIndexPaths addObjectsFromArray:indexPaths];
}

- (void)deleteItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
{
    [self.deletedItemIndexPaths addObjectsFromArray:indexPaths];
}

- (void)reloadItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
{
    [self.reloadedItemIndexPaths addObjectsFromArray:indexPaths];
}

@end

@interface HUBViewModelRendererTests : XCTestCase

@property (nonatomic, strong) HUBCollectionViewMockWithoutBatchUpdates *collectionView;
@property (nonatomic, strong) HUBViewModelRenderer *viewModelRenderer;

@end

@implementation HUBViewModelRendererTests

- (void)setUp
{
    [super setUp];

    self.collectionView = [[HUBCollectionViewMockWithoutBatchUpdates alloc] initWithFrame:CGRectZero
                                                                     collectionViewLayout:[UICollectionViewFlowLayout new]];
    
    id<HUBComponentRegistry> const componentRegistry = [HUBComponentRegistryMock new];
    id<HUBComponentLayoutManager> const componentLayoutManager = [HUBComponentLayoutManagerMock new];
    HUBCollectionViewLayoutFactory * const collectionViewLayoutFactory = [[HUBCollectionViewLayoutFactory alloc] initWithComponentRegistry:componentRegistry
                                                                                                                    componentLayoutManager:componentLayoutManager];
    
    self.viewModelRenderer = [[HUBViewModelRenderer alloc] initWithCollectionViewLayoutFactory:collectionViewLayoutFactory];
}

- (void)tearDown
{
    self.collectionView = nil;
    self.viewModelRenderer = nil;

    [super tearDown];
}

- (void)testTwoSubsequentRenders
{
    NSArray<id<HUBComponentModel>> * const firstComponents = @[
        [HUBViewModelUtilities createComponentModelWithIdentifier:@"component-1" customData:nil],
    ];
    id<HUBViewModel> const firstViewModel = [HUBViewModelUtilities createViewModelWithIdentifier:@"Test" components:firstComponents];

    NSArray<id<HUBComponentModel>> * const secondComponents = @[
        [HUBViewModelUtilities createComponentModelWithIdentifier:@"component-2" customData:nil],
    ];
    id<HUBViewModel> const secondViewModel = [HUBViewModelUtilities createViewModelWithIdentifier:@"Test2" components:secondComponents];

    __weak XCTestExpectation * const expectation = [self expectationWithDescription:@"Waiting for render"];

    [self.viewModelRenderer renderViewModel:firstViewModel inCollectionView:self.collectionView usingBatchUpdates:YES animated:YES addHeaderMargin:YES completion:^{
        // On the first render, we expect the collection view to be reloaded
        XCTAssertEqual(self.collectionView.reloadDataCount, 1u);
        XCTAssertEqualObjects(self.collectionView.insertedItemIndexPaths, @[]);
        XCTAssertEqualObjects(self.collectionView.deletedItemIndexPaths, @[]);
        XCTAssertEqualObjects(self.collectionView.reloadedItemIndexPaths, @[]);
        
        [self.viewModelRenderer renderViewModel:secondViewModel inCollectionView:self.collectionView usingBatchUpdates:YES animated:YES addHeaderMargin:YES completion:^{
            XCTAssertEqual(self.collectionView.reloadDataCount, 1u);
            XCTAssertEqualObjects(self.collectionView.insertedItemIndexPaths, @[[NSIndexPath indexPathForItem:0 inSection:0]]);
            XCTAssertEqualObjects(self.collectionView.deletedItemIndexPaths, @[[NSIndexPath indexPathForItem:0 inSection:0]]);
            XCTAssertEqualObjects(self.collectionView.reloadedItemIndexPaths, @[]);
            
            [expectation fulfill];
        }];
    }];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

@end
