//
//  WGTextView.h
//  Keyboard
//
//  Created by Veeco on 2019/6/6.
//  Copyright © 2019 Chance. All rights reserved.
//

#import <UIKit/UIKit.h>
@class WGTextView;

@protocol WGTextViewDelegate <NSObject>

@optional

/**
 监听删除键点击
 
 @param textView 自身
 */
- (void)didDeleteBackwardWithTextView:(nonnull __kindof WGTextView *)textView;

@end

NS_ASSUME_NONNULL_BEGIN

@interface WGTextView : UITextView

/** 代理 */
@property (nullable, nonatomic, weak) NSObject<WGTextViewDelegate> *wgDelegate;

@end

NS_ASSUME_NONNULL_END
