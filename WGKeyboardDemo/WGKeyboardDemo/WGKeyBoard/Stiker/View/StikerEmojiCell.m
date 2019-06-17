//
//  StikerEmojiCell.m
//  Keyboard
//
//  Created by Veeco on 2019/5/23.
//  Copyright © 2019 Chance. All rights reserved.
//

#import "StikerEmojiCell.h"
#import "WGKeyboardHeader.h"
#import "StikerInfoModel.h"

@interface StikerEmojiCell ()

{
    /** 元素组 */
    NSArray<UILabel *> *_items;
}

@end

// 行列数
static const int kRowCount = 3;
static const int kColCount = 8;

@implementation StikerEmojiCell

#pragma mark - <Getter & Setter>

+ (NSUInteger)countPerPage {
    
    return kRowCount * kColCount;
}

- (void)setStikers:(NSArray<StikerInfoModel *> *)stikers {
    _stikers = stikers;
    
    if (stikers.count > kRowCount * kColCount) {
        
        return;
    }
    [_items enumerateObjectsUsingBlock:^(UILabel * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
       
        item.text = @"";
    }];
    [stikers enumerateObjectsUsingBlock:^(StikerInfoModel * _Nonnull stiker, NSUInteger idx, BOOL * _Nonnull stop) {
       
        if (stiker.stikerType == StikerTypeEmoji && stiker.stikerTitle.length) {
            
            self->_items[idx].text = stiker.stikerTitle;
        }
    }];
}

#pragma mark - <System>

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        // 初始化UI
        [self initUI];
    }
    return self;
}

#pragma mark - <Normal>

/**
 初始化UI
 */
- (void)initUI {
    
    NSMutableArray *arrM = @[].mutableCopy;
    for (int i = 0; i < kRowCount * kColCount; i++) {
        
        const CGFloat itemWH = 50;
        const CGFloat marginTB = (self.height - itemWH * kRowCount) / (kRowCount + 1);
        const CGFloat marginLR = 15;
        const CGFloat paddingLR = (self.width - marginLR * 2 - itemWH * kColCount) / (kColCount - 1);
        
        UILabel *item = [UILabel new];
        [self.contentView addSubview:item];
        [arrM addObject:item];
        item.size = CGSizeMake(itemWH, itemWH);
        item.x = marginLR + (itemWH + paddingLR) * (i % kColCount);
        item.y = marginTB + (itemWH + marginTB) * (i / kColCount);
        item.textAlignment = NSTextAlignmentCenter;
        item.font = FONT_SIZE(30);
        item.userInteractionEnabled = YES;
        [item addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapItem:)]];
    }
    _items = arrM;
}

/**
 监听元素点击

 @param tap 手势
 */
- (void)didTapItem:(nonnull UITapGestureRecognizer *)tap {
    
    UILabel *item = (UILabel *)tap.view;
    if ([item isKindOfClass:UILabel.class]) {
        
        NSInteger index = [_items indexOfObject:item];
        StikerInfoModel *stiker = _stikers[index];
        
        if ([self.delegate respondsToSelector:@selector(emojiCell:didSelectStiker:)]) {
            [self.delegate emojiCell:self didSelectStiker:stiker];
        }
    }
}

@end
