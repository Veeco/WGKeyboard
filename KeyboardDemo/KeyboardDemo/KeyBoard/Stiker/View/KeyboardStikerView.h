//
//  KeyboardStikerView.h
//  Keyboard
//
//  Created by Veeco on 2019/4/11.
//  Copyright © 2019 Chance. All rights reserved.
//

#import <UIKit/UIKit.h>
@class KeyboardStikerView;
@class StikerPackageModel;
@class StikerInfoModel;
@class WGKeyboard;

@protocol KeyboardStikerViewDataSource <NSObject>

@optional

/**
 获取表情包

 @param stikerView 自身
 @return 表情包
 */
- (nullable NSArray<StikerPackageModel *> *)stikerPackagesInStikerView:(nonnull __kindof KeyboardStikerView *)stikerView;

@end

@protocol KeyboardStikerViewDelegate <NSObject>

@optional

/**
 选择表情回调
 
 @param stikerView 自身
 @param stiker 所选表情
 */
- (void)stikerView:(nonnull __kindof KeyboardStikerView *)stikerView didSelectStiker:(nonnull StikerInfoModel *)stiker;

/**
 点击发送时回调
 
 @param stikerView 自身
 */
- (void)didTapSendWithStikerView:(nonnull __kindof KeyboardStikerView *)stikerView;

@end

NS_ASSUME_NONNULL_BEGIN

@interface KeyboardStikerView : UIView

/** 代理 */
@property (nullable, nonatomic, weak) NSObject<KeyboardStikerViewDataSource> *dataSource;
/** 代理 */
@property (nullable, nonatomic, weak) NSObject<KeyboardStikerViewDelegate> *delegate;
/** 键盘 */
@property (nullable, nonatomic, weak) WGKeyboard *keyboard;

/**
 实例化

 @return 自身
 */
+ (instancetype)stikerView;

/**
 刷新
 */
- (void)reloadData;

@end

NS_ASSUME_NONNULL_END
