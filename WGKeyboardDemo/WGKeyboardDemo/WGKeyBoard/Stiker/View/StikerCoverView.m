//
//  StikerCoverView.m
//  Keyboard
//
//  Created by Veeco on 2019/5/23.
//  Copyright © 2019 Chance. All rights reserved.
//

#import "StikerCoverView.h"
#import "StikerPackageModel.h"
#import "UIImageView+WebCache.h"
#import "WGKeyboardHeader.h"

@interface StikerCoverView ()

{
    /** 表情包 */
    NSArray<StikerPackageModel *> *_stikerPackages;
    /** SV */
    UIScrollView *_SV;
    /** 元素组 */
    NSArray<UIView *> *_items;
    /** 发送按钮 */
    UILabel *_send;
}

@end

@implementation StikerCoverView

#pragma mark - <Getter & Setter>

- (void)setCurrentIndex:(NSInteger)currentIndex {
    
    [self updateItem:_items[self.currentIndex] selected:NO];
    [self updateItem:_items[currentIndex] selected:YES];
    
    _currentIndex = currentIndex;
    
    [UIView animateWithDuration:0.13f animations:^{
        
        [self setSendHide:self->_stikerPackages[currentIndex].stikerPackageType != StikerPackageTypeEmoji];
    }];
    
    // 可视范围
    const CGFloat beginX = _SV.contentOffset.x;
    const CGFloat endX = beginX + _SV.width - _SV.contentInset.right;
    UIView *currentItem = _items[currentIndex];
    
    if (currentItem.x < beginX) {
        
        [_SV setContentOffset:CGPointMake(currentItem.x, 0) animated:YES];
    }
    else if (CGRectGetMaxX(currentItem.frame) > endX) {
        
        [_SV setContentOffset:CGPointMake(CGRectGetMaxX(currentItem.frame) + _SV.contentInset.right - _SV.width, 0) animated:YES];
    }
}

#pragma mark - <Normal>

/**
 初始化UI
 */
- (void)initUI {
    
    UIScrollView *SV = [[UIScrollView alloc] initWithFrame:self.bounds];
    [self addSubview:SV];
    _SV = SV;
    SV.showsHorizontalScrollIndicator = NO;
    UIEdgeInsets insets = SV.contentInset;
    insets.right = 50;
    SV.contentInset = insets;
    
    NSMutableArray *arrM = @[].mutableCopy;
    [_stikerPackages enumerateObjectsUsingBlock:^(StikerPackageModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        UIView *item = [UIView new];
        [SV addSubview:item];
        item.tag = idx;
        item.size = CGSizeMake(50, SV.height);
        item.x = item.width * idx;
        [item addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapItem:)]];
        [arrM addObject:item];
        
        UIView *line = [UIView new];
        [item addSubview:line];
        line.width = 0.5f;
        line.height = item.height - 10;
        line.x = item.width - line.width;
        line.centerY = item.height / 2;
        line.backgroundColor = [UIColor.lightGrayColor colorWithAlphaComponent:0.3f];
        
        UIImageView *icon = [UIImageView new];
        [item addSubview:icon];
        icon.width = line.x;
        icon.height = item.height;
        icon.contentMode = UIViewContentModeScaleAspectFit;
        if (obj.localCover) {
            
            icon.image = obj.localCover;
        }
        else if (obj.netCover.length) {
            
            [icon sd_setImageWithURL:[NSURL URLWithString:obj.netCover]];
        }
        
        if (idx == 0) {
            
            [self updateItem:item selected:YES];
        }
        
        if (idx == self->_stikerPackages.count - 1) {
            
            SV.contentSize = CGSizeMake(CGRectGetMaxX(item.frame), 0);
        }
    }];
    _items = arrM;
    
    // 发送按钮
    UILabel *send = [UILabel new];
    [self addSubview:send];
    _send = send;
    send.size = CGSizeMake(SV.contentInset.right, self.height);
    [self setSendHide:_stikerPackages.firstObject.stikerPackageType != StikerPackageTypeEmoji];
    send.text = @"发送";
    send.font = BOLD_SIZE(14);
    send.textAlignment = NSTextAlignmentCenter;
    send.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.03f];
    send.userInteractionEnabled = YES;
    [send addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapSend)]];
    
    UIView *line = [UIView new];
    [send addSubview:line];
    line.width = 0.5f;
    line.height = send.height;
    line.backgroundColor = UIColor.lightGrayColor;
}

/**
 监听发送点击
 */
- (void)didTapSend {
    
    if ([self.delegate respondsToSelector:@selector(didTapSendWithCoverView:)]) {
        [self.delegate didTapSendWithCoverView:self];
    }
}

/**
 设置发送按钮

 @param hide 是否隐藏
 */
- (void)setSendHide:(BOOL)hide {
    
    _send.x = hide ? self.width : self.width - _send.width;
}

/**
 更新元素选中状态

 @param item 元素
 @param selected 是否选中
 */
- (void)updateItem:(nonnull UIView *)item selected:(BOOL)selected {
    
    item.backgroundColor = selected ? [UIColor.lightGrayColor colorWithAlphaComponent:0.3f] : UIColor.clearColor;
}

/**
 监听元素点击

 @param tap 手势
 */
- (void)didTapItem:(nonnull UITapGestureRecognizer *)tap {
    
    NSInteger index = tap.view.tag;
    
    if (index == self.currentIndex) {
        
        return;
    }
    self.currentIndex = index;
    
    if ([self.delegate respondsToSelector:@selector(currentIndexDidChangeWithCoverView:)]) {
        [self.delegate currentIndexDidChangeWithCoverView:self];
    }
}

/**
 实例化
 
 @param stikerPackages 表情包
 @return 实例
 */
- (instancetype)initWithStikerPackages:(nonnull NSArray<StikerPackageModel *> *)stikerPackages {
    if (self = [super initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, KeyboardStikerCoverViewHeight)]) {
        
        _stikerPackages = stikerPackages;
        
        // 初始化UI
        [self initUI];
    }
    return self;
}

@end
