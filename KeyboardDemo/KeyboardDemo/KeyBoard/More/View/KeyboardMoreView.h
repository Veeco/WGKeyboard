//
//  KeyboardMoreView.h
//  Keyboard
//
//  Created by Veeco on 2019/4/12.
//  Copyright © 2019 Chance. All rights reserved.
//

#import <UIKit/UIKit.h>
@class KeyboardMoreView;

// 更多元素类型
typedef NS_ENUM(NSUInteger, MoreItemType) {
    /** 相册 */
    MoreItemTypeAlbum = 1,
    /** 拍摄 */
    MoreItemTypeCamera,
    /** 位置 */
    MoreItemTypeLocation,
};

@protocol KeyboardMoreViewDelegate <NSObject>

@optional

/**
 选择元素回调

 @param moreView 自身
 @param type 元素类型
 */
- (void)moreView:(nonnull __kindof KeyboardMoreView *)moreView didSelectItemWithType:(MoreItemType)type;

@end

NS_ASSUME_NONNULL_BEGIN

@interface KeyboardMoreView : UIView

/**
 实例化
 
 @return 自身
 */
+ (instancetype)moreView;

/** 代理 */
@property (nullable, nonatomic, weak) NSObject<KeyboardMoreViewDelegate> *delegate;

@end

NS_ASSUME_NONNULL_END
