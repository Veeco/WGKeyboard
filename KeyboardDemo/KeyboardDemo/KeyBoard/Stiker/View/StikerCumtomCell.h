//
//  StikerCumtomCell.h
//  Keyboard
//
//  Created by Veeco on 2019/5/23.
//  Copyright © 2019 Chance. All rights reserved.
//

#import <UIKit/UIKit.h>
@class StikerInfoModel;
@class StikerCumtomCell;
@class WGKeyboard;

@protocol StikerCumtomCellDelegate <NSObject>

@optional

/**
 选择表情回调
 
 @param customCell 自身
 @param stiker 所选表情
 */
- (void)customCell:(nonnull __kindof StikerCumtomCell *)customCell didSelectStiker:(nonnull StikerInfoModel *)stiker;

@end

NS_ASSUME_NONNULL_BEGIN

@interface StikerCumtomCell : UICollectionViewCell

/** 单页表情数 */
@property (assign, nonatomic, readonly, class) NSUInteger countPerPage;
/** 表情 */
@property (nullable, nonatomic, copy) NSArray<StikerInfoModel *> *stikers;
/** 代理 */
@property (nullable, nonatomic, weak) NSObject<StikerCumtomCellDelegate> *delegate;
/** 键盘 */
@property (nullable, nonatomic, weak) WGKeyboard *keyboard;

/**
 程序失去焦点时调用
 */
- (void)willResignActive;

@end

NS_ASSUME_NONNULL_END
