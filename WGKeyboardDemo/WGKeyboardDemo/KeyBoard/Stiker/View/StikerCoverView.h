//
//  StikerCoverView.h
//  Keyboard
//
//  Created by Veeco on 2019/5/23.
//  Copyright © 2019 Chance. All rights reserved.
//

#import <UIKit/UIKit.h>
@class StikerPackageModel;
@class StikerCoverView;

@protocol StikerCoverViewDelegate <NSObject>

@optional

/**
 当前下标发生变化时回调
 
 @param coverView 自身
 */
- (void)currentIndexDidChangeWithCoverView:(nonnull __kindof StikerCoverView *)coverView;

/**
 点击发送时回调
 
 @param coverView 自身
 */
- (void)didTapSendWithCoverView:(nonnull __kindof StikerCoverView *)coverView;

@end

NS_ASSUME_NONNULL_BEGIN

@interface StikerCoverView : UIView

/** 当前下标 */
@property (assign, nonatomic) NSInteger currentIndex;
/** 代理 */
@property (nullable, nonatomic, weak) NSObject<StikerCoverViewDelegate> *delegate;

/**
 实例化

 @param stikerPackages 表情包
 @return 实例
 */
- (instancetype)initWithStikerPackages:(nonnull NSArray<StikerPackageModel *> *)stikerPackages;

@end

NS_ASSUME_NONNULL_END
