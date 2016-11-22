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

#import <UIKit/UIKit.h>
#import "HUBHeaderMacros.h"

@protocol HUBComponentModel;

NS_ASSUME_NONNULL_BEGIN

@interface HUBResizeAnimation : NSObject <NSCopying>

@property (nonatomic, assign, readonly) NSTimeInterval duration;
@property (nonatomic, strong, readonly) dispatch_block_t animationBlock;
@property (nonatomic, strong, readonly) NSDictionary<NSString *, NSValue *> *targetComponentViewSizes;

+ (instancetype)animationForComponentModel:(id<HUBComponentModel>)componentModel
                            targetViewSize:(CGSize)targetViewSize
                                  duration:(NSTimeInterval)duration
                            animationBlock:(nullable dispatch_block_t)animationBlock;

- (instancetype)initWithDuration:(NSTimeInterval)duration HUB_DESIGNATED_INITIALIZER;

- (void)addTargetViewSize:(CGSize)targetViewSize
        forComponentModel:(id<HUBComponentModel>)componentModel;

- (void)addAnimationBlock:(dispatch_block_t)animationBlock;

@end

NS_ASSUME_NONNULL_END
