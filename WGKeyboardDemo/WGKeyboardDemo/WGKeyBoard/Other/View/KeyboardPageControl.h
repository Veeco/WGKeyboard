//
//  KeyboardPageControl.h
//  Keyboard
//
//  Created by Veeco on 2019/5/17.
//  Copyright © 2019 Chance. All rights reserved.
//

#import <UIKit/UIKit.h>
@class KeyboardPageControl;

@protocol KeyboardPageControlDelegate <NSObject>

@optional

/**
 当前页发生变化时回调

 @param pageControl 自身
 */
- (void)currentPageDidChangeWithPageControl:(nonnull __kindof KeyboardPageControl *)pageControl;

@end

NS_ASSUME_NONNULL_BEGIN

@interface KeyboardPageControl : UIView

/**
 实例化
 
 @param pageCount 总页数
 @param currentPage 当前页
 @return 实例
 */
- (instancetype)initWithPageCount:(NSInteger)pageCount currentPage:(NSInteger)currentPage;

/** 当前页 */
@property (assign, nonatomic) NSInteger currentPage;
/** 代理 */
@property (nullable, nonatomic, weak) NSObject<KeyboardPageControlDelegate> *delegate;

@end

NS_ASSUME_NONNULL_END
