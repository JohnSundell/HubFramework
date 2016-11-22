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

#import "HUBResizeAnimation.h"

#import "HUBComponentModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface HUBResizeAnimation ()

@property (nonatomic, strong, readonly) NSMutableArray<dispatch_block_t> *animationBlocks;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, NSValue *> *mutableTargetComponentViewSizes;

@end

@implementation HUBResizeAnimation

#pragma mark - Class constructor

+ (instancetype)animationForComponentModel:(id<HUBComponentModel>)componentModel
                            targetViewSize:(CGSize)targetViewSize
                                  duration:(NSTimeInterval)duration
                            animationBlock:(nullable dispatch_block_t)animationBlock
{
    HUBResizeAnimation * const animation = [[self alloc] initWithDuration:duration];
    [animation addTargetViewSize:targetViewSize forComponentModel:componentModel];
    
    if (animationBlock != nil) {
        dispatch_block_t const nonNilAnimationBlock = animationBlock;
        [animation addAnimationBlock:nonNilAnimationBlock];
    }
    
    return animation;
}

#pragma mark - Initializer

- (instancetype)initWithDuration:(NSTimeInterval)duration
{
    self = [super init];
    
    if (self != nil) {
        _duration = duration;
        _animationBlocks = [NSMutableArray new];
        _mutableTargetComponentViewSizes = [NSMutableDictionary new];
    }
    
    return self;
}

#pragma mark - API

- (dispatch_block_t)animationBlock
{
    return ^{
        for (dispatch_block_t const block in self.animationBlocks) {
            block();
        }
    };
}

- (NSDictionary<NSString *, NSValue *> *)targetComponentViewSizes
{
    return [self.mutableTargetComponentViewSizes copy];
}

- (void)addTargetViewSize:(CGSize)targetSize forComponentModel:(id<HUBComponentModel>)componentModel
{
    NSValue * const sizeValue = [NSValue valueWithCGSize:targetSize];
    self.mutableTargetComponentViewSizes[componentModel.identifier] = sizeValue;
}

- (void)addAnimationBlock:(dispatch_block_t)animationBlock
{
    [self.animationBlocks addObject:[animationBlock copy]];
}

#pragma mark - NSCopying

- (id)copyWithZone:(nullable NSZone *)zone
{
    HUBResizeAnimation * const copy = [[HUBResizeAnimation alloc] initWithDuration:self.duration];
    [copy.animationBlocks addObjectsFromArray:self.animationBlocks];
    [copy.mutableTargetComponentViewSizes addEntriesFromDictionary:self.mutableTargetComponentViewSizes];
    return copy;
}

@end

NS_ASSUME_NONNULL_END
