//
//  StikerCumtomCell.m
//  Keyboard
//
//  Created by Veeco on 2019/5/23.
//  Copyright © 2019 Chance. All rights reserved.
//

#import "StikerCumtomCell.h"
#import "StikerInfoModel.h"
#import "UIImageView+WebCache.h"
#import "WGKeyboard.h"
#import "OLImageView.h"
#import "OLImageView+PCExtension.h"
#import "Masonry.h"

@interface StikerCumtomCell ()

{
    /** 元素组 */
    NSArray<UIView *> *_items;
    /** 选中遮罩 */
    UIView *_mask;
    /** 正在展示预览的元素 */
    UIView *_pringItem;
    /** 预览主体 */
    OLImageView *_preBody;
    /** 预览描述 */
    UILabel *_preDes;
}

/** 预览图 */
@property (nullable, nonatomic, strong) UIImageView *preView;

@end

// 行列数
static const int kRowCount = 2;
static const int kColCount = 4;
// tag
static const NSInteger kIconTag = 1;
static const NSInteger kTitleTag = 2;

@implementation StikerCumtomCell

#pragma mark - <Getter & Setter>

- (UIImageView *)preView {
    if (!_preView) {
        
        UIImageView *preView = [UIImageView new];
        [self.keyboard addSubview:preView];
        self.preView = preView;
        preView.size = CGSizeMake(161.5f, 188.5f);
        
        const CGFloat wh = preView.width / 3 * 2;
        OLImageView *preBody = [OLImageView new];
        [preView addSubview:preBody];
        _preBody = preBody;
        preBody.size = CGSizeMake(wh, wh);
        preBody.centerX = preView.width / 2;
        preBody.centerY = (preView.height - 25) / 2;
        preBody.contentMode = UIViewContentModeScaleAspectFit;
        
        UILabel *preDes = [UILabel new];
        [preView addSubview:preDes];
        _preDes = preDes;
        preDes.textColor = [UIColor.blackColor colorWithAlphaComponent:0.5f];
        [preDes mas_makeConstraints:^(MASConstraintMaker *make) {
           
            make.bottom.mas_equalTo(-25);
            make.centerX.mas_equalTo(0);
            make.width.mas_lessThanOrEqualTo(preView.width);
        }];
    }
    return _preView;
}

+ (NSUInteger)countPerPage {
    
    return kRowCount * kColCount;
}

- (void)setStikers:(NSArray<StikerInfoModel *> *)stikers {
    _stikers = stikers;
    
    if (stikers.count > kRowCount * kColCount) {
        
        return;
    }
    _mask.alpha = 0;
    _pringItem = nil;
    _preView.hidden = YES;
    
    [_items enumerateObjectsUsingBlock:^(UIView * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
       
        item.hidden = YES;
    }];
    [stikers enumerateObjectsUsingBlock:^(StikerInfoModel * _Nonnull stiker, NSUInteger idx, BOOL * _Nonnull stop) {
        
        UIView *item = self->_items[idx];
        UIImageView *icon = [item viewWithTag:kIconTag];
        UILabel *title = [item viewWithTag:kTitleTag];
        
        if ([icon isKindOfClass:UIImageView.class] && [title isKindOfClass:UILabel.class]) {
            
            if (stiker.stikerType == StikerTypeAdd && stiker.stikerTitle.length) {
                
                icon.contentMode = UIViewContentModeCenter;
                icon.image = [UIImage imageNamed:stiker.stikerTitle];
                title.text = @"";
                item.hidden = NO;
            }
            else if (stiker.stikerType == StikerTypeCustom) {
                
                icon.contentMode = UIViewContentModeScaleAspectFit;
                [icon sd_setImageWithURL:[NSURL URLWithString:stiker.stikerCover]];
                title.text = stiker.stikerTitle;
                item.hidden = NO;
            }
            if (!item.hidden) {
                
                if (title.text.length) {
                    
                    icon.y = 0;
                }
                else {
                    
                    icon.centerY = item.height / 2;
                }
            }
        }
    }];
}

#pragma mark - <System>

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        // 初始化UI
        [self initUI];
        
        [self.contentView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPressSelf:)]];
    }
    return self;
}

#pragma mark - <Normal>

/**
 程序失去焦点时调用
 */
- (void)willResignActive {
    
    [self cancelPreview];
}

/**
 取消预览
 */
- (void)cancelPreview {
    
    [self setItem:_pringItem select:NO];
    _pringItem = nil;
    _preView.hidden = YES;
}

/**
 监听长按手势
 
 @param longPress 手势
 */
- (void)didLongPressSelf:(nonnull UILongPressGestureRecognizer *)longPress {
    
    if (longPress.state == UIGestureRecognizerStateBegan || longPress.state == UIGestureRecognizerStateChanged) {
        
        CGPoint p = [longPress locationInView:longPress.view];
        
        __block BOOL outside = YES;
        [_items enumerateObjectsUsingBlock:^(UIView * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if (idx < self->_stikers.count) {
                
                StikerInfoModel *stiker = self->_stikers[idx];
                if (CGRectContainsPoint(item.frame, p) && stiker.stikerType != StikerTypeAdd) {
                    
                    [self showPreWithItem:item stiker:stiker];
                    outside = NO;
                    
                    *stop = YES;
                }
            }
        }];
        if (outside) {
            
            [self cancelPreview];
        }
    }
    else if (longPress.state == UIGestureRecognizerStateEnded) {
        
        [self cancelPreview];
    }
}

/**
 展示预览

 @param item 元素
 @param stiker 表情
 */
- (void)showPreWithItem:(nonnull UIView *)item stiker:(nonnull StikerInfoModel *)stiker {
    
    if (_pringItem == item) {
        
        return;
    }
    _pringItem = item;
    
    [self setItem:item select:YES];
    
    UIView *tempView = [UIView new];
    tempView.size = self.preView.size;
    tempView.y = item.y - self.preView.height;
    const CGFloat margin = 15;
    
    NSInteger index = [_items indexOfObject:item];
    if (index % kColCount == 0) { // 左框
        
        self.preView.image = [UIImage imageNamed:@"stiker_box_L"];
        tempView.x = margin;
    }
    else if (index % kColCount == kColCount - 1) { // 右框
        
        self.preView.image = [UIImage imageNamed:@"stiker_box_R"];
        tempView.x = self.contentView.width - margin - tempView.width;
    }
    else { // 中框
        
        self.preView.image = [UIImage imageNamed:@"stiker_box"];
        tempView.centerX = item.centerX;
    }
    CGRect preFrame = [self.keyboard convertRect:tempView.frame fromView:self.contentView];
    self.preView.frame = preFrame;
    self.preView.hidden = NO;
    [_preBody pc_setGifWithUrl:[NSURL URLWithString:stiker.stiker]];
    _preDes.text = stiker.stikerTitle;
}

/**
 初始化UI
 */
- (void)initUI {
    
    NSMutableArray *arrM = @[].mutableCopy;
    for (int i = 0; i < kRowCount * kColCount; i++) {
        
        const CGFloat itemW = 55;
        const CGFloat itemH = 70;
        const CGFloat marginTB = (self.height - itemH * kRowCount) / (kRowCount + 1);
        const CGFloat marginLR = 30;
        const CGFloat paddingLR = (self.width - marginLR * 2 - itemW * kColCount) / (kColCount - 1);
        
        UIView *item = [UIView new];
        [self.contentView addSubview:item];
        [arrM addObject:item];
        item.size = CGSizeMake(itemW, itemH);
        item.x = marginLR + (itemW + paddingLR) * (i % kColCount);
        item.y = marginTB + (itemH + marginTB) * (i / kColCount);
        [item addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapItem:)]];
        
        UIImageView *icon = [UIImageView new];
        [item addSubview:icon];
        icon.tag = kIconTag;
        icon.size = CGSizeMake(item.width, item.width);
        
        // 选中遮罩
        UIView *mask = [UIView new];
        [self.contentView addSubview:mask];
        _mask = mask;
        mask.backgroundColor = UIColor.lightGrayColor;
        mask.alpha = 0;
        mask.layer.cornerRadius = 3;
        
        UILabel *title = [UILabel new];
        [item addSubview:title];
        title.tag = kTitleTag;
        title.y = CGRectGetMaxY(icon.frame);
        title.size = CGSizeMake(item.width, item.height - title.y);
        title.textColor = [UIColor.blackColor colorWithAlphaComponent:0.5f];
        title.textAlignment = NSTextAlignmentCenter;
        title.font = FONT_SIZE(12);
    }
    _items = arrM;
}

/**
 设置元素选中状态

 @param item 元素
 @param select 是否选中
 */
- (void)setItem:(nonnull UIView *)item select:(BOOL)select {
    
    UIImageView *icon = [item viewWithTag:kIconTag];
    if ([icon isKindOfClass:UIImageView.class]) {
        
        CGRect maskFrame = [self.contentView convertRect:icon.frame fromView:icon.superview];
        _mask.frame = maskFrame;
        [UIView animateWithDuration:0.1f animations:^{
           
            self->_mask.alpha = select ? 0.3f : 0;
        }];
    }
}

/**
 监听元素点击
 
 @param tap 手势
 */
- (void)didTapItem:(nonnull UITapGestureRecognizer *)tap {
    
    UIView *item = tap.view;
    
    [self setItem:item select:YES];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [self setItem:item select:NO];
    });
    
    NSInteger index = [_items indexOfObject:item];
    StikerInfoModel *stiker = _stikers[index];
    
    if ([self.delegate respondsToSelector:@selector(customCell:didSelectStiker:)]) {
        [self.delegate customCell:self didSelectStiker:stiker];
    }
}

@end
