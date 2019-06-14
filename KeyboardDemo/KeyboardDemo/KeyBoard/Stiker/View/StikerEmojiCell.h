//
//  StikerEmojiCell.h
//  Keyboard
//
//  Created by Veeco on 2019/5/23.
//  Copyright © 2019 Chance. All rights reserved.
//

#import <UIKit/UIKit.h>
@class StikerInfoModel;
@class StikerEmojiCell;

@protocol StikerEmojiCellDelegate <NSObject>

@optional

/**
 选择表情回调

 @param emojiCell 自身
 @param stiker 所选表情
 */
- (void)emojiCell:(nonnull __kindof StikerEmojiCell *)emojiCell didSelectStiker:(nonnull StikerInfoModel *)stiker;

@end

NS_ASSUME_NONNULL_BEGIN

@interface StikerEmojiCell : UICollectionViewCell

/** 单页表情数 */
@property (assign, nonatomic, readonly, class) NSUInteger countPerPage;
/** 表情 */
@property (nullable, nonatomic, copy) NSArray<StikerInfoModel *> *stikers;
/** 代理 */
@property (nullable, nonatomic, weak) NSObject<StikerEmojiCellDelegate> *delegate;

@end

NS_ASSUME_NONNULL_END
