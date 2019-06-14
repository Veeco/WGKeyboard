//
//  WGKeyboard.h
//  Keyboard
//
//  Created by Veeco on 2019/3/26.
//  Copyright © 2019 Chance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KeyboardMoreView.h"
#import "StikerPackageModel.h"
@class WGKeyboard;

@protocol WGKeyboardDataSource <NSObject>

@optional

/**
 获取表情包
 
 @param keyboard 自身
 @return 表情包
 */
- (nullable NSArray<StikerPackageModel *> *)stikerPackagesInKeyboard:(nonnull __kindof WGKeyboard *)keyboard;

@end

@protocol WGKeyboardDelegate <NSObject>

@optional

/**
 选择自定义表情回调
 
 @param keyboard 自身
 @param customStiker 所选自定义表情
 */
- (void)keyboard:(nonnull __kindof WGKeyboard *)keyboard didSelectCustomStiker:(nonnull StikerInfoModel *)customStiker;

/**
 点击添加表情回调
 
 @param keyboard 自身
 */
- (void)didSelectAddStikerWithKeyboard:(nonnull __kindof WGKeyboard *)keyboard;

/**
 发送按钮点击回调

 @param keyboard 自身
 @param content 内容
 */
- (void)keyboard:(nonnull __kindof WGKeyboard *)keyboard didClickSendWithContent:(nonnull NSString *)content;

/**
 录音开始回调

 @param keyboard 自身
 */
- (void)audioRecordDidStartWithKeyboard:(nonnull __kindof WGKeyboard *)keyboard;

/**
 录音完成回调
 
 @param keyboard 自身
 @param path 音频文件路径
 @param duration 时长
 */
- (void)keyboard:(nonnull __kindof WGKeyboard *)keyboard audioRecordDidFinishWithPath:(nonnull NSString *)path duration:(NSTimeInterval)duration;

/**
 录音取消回调
 
 @param keyboard 自身
 */
- (void)audioRecordDidCancelWithKeyboard:(nonnull __kindof WGKeyboard *)keyboard;

/**
 选择更多元素回调
 
 @param keyboard 自身
 @param type 更多元素类型
 */
- (void)keyboard:(nonnull __kindof WGKeyboard *)keyboard didSelectMoreItemWithType:(MoreItemType)type;

/**
 监听内容为空时删除键点击
 
 @param keyBoard 自身
 */
- (void)didDeleteBackwardWhenAvoidWithKeyBoard:(nonnull __kindof WGKeyboard *)keyBoard;

@end

// 类型
typedef NS_ENUM(NSUInteger, KeyboardType) {
    KeyboardTypeChat, // 聊天
    KeyboardTypeComment, // 评论
};

NS_ASSUME_NONNULL_BEGIN

@interface WGKeyboard : UIView

/** 关联TB */
@property (nullable, nonatomic, weak) UITableView *assoTB;
/** 数据源 */
@property (nullable, nonatomic, weak) NSObject<WGKeyboardDataSource> *dataSource;
/** 代理 */
@property (nullable, nonatomic, weak) NSObject<WGKeyboardDelegate> *delegate;
/** 是否是否处于弹起状态 */
@property (assign, nonatomic, readonly) BOOL keyboardUp;
/** 默认高度 */
@property (class, assign, nonatomic, readonly) CGFloat defaultHeight;
/** 录音文件根目录 */
@property (nullable, nonatomic, copy) NSString *recordRootPath;
/** 占位 */
@property (nullable, nonatomic, copy) NSString *placeholder;
/** 输入中文字 */
@property (nullable, nonatomic, copy) NSString *textContent;

/**
 初始化

 @param type 类型
 @return 实例
 */
+ (nonnull instancetype)keyboardWithType:(KeyboardType)type;

/**
 收起键盘
 */
- (void)keyboardGetDown;

/**
 刷新表情数据
 */
- (void)reloadStikerData;

/**
 成为第一响应者
 */
- (void)becomeFirstResponder;

@end

NS_ASSUME_NONNULL_END
