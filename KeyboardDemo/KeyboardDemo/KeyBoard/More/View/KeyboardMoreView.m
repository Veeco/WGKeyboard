//
//  KeyboardMoreView.m
//  Keyboard
//
//  Created by Veeco on 2019/4/12.
//  Copyright © 2019 Chance. All rights reserved.
//

#import "KeyboardMoreView.h"
#import "WGKeyboardHeader.h"
#import "KeyboardPageControl.h"

@interface KeyboardMoreView () <KeyboardPageControlDelegate, UIScrollViewDelegate>

{
    /** SV */
    UIScrollView *_SV;
    /** 页码指示 */
    KeyboardPageControl *_pageControl;
}

@end

@implementation KeyboardMoreView

#pragma mark - <System>

- (instancetype)initWithFrame:(CGRect)frame {
    frame.size = CGSizeMake(SCREEN_WIDTH, KeyboardMoreViewHeight);
    if (self = [super initWithFrame:frame]) {
        
        // 初始化UI
        [self initUI];
    }
    return self;
}

#pragma mark - <Normal>

/**
 实例化
 
 @return 自身
 */
+ (instancetype)moreView {
    
    return [[self alloc] initWithFrame:CGRectZero];
}

/**
 初始化UI
 */
- (void)initUI {
    
    UIView *topLine = [UIView new];
    [self addSubview:topLine];
    topLine.width = self.width;
    topLine.height = 0.5f;
    topLine.backgroundColor = [UIColorMakeFromRGB(0x999999) colorWithAlphaComponent:0.3f];
    
    UIScrollView *SV = [UIScrollView new];
    [self addSubview:SV];
    _SV = SV;
    SV.size = self.size;
    SV.pagingEnabled = YES;
    SV.showsHorizontalScrollIndicator = NO;
    SV.delegate = self;
    
    const int totalCount = 3;
    const int colCount = 4;
    const int rowCount = 2;
    const int countPerPage = colCount * rowCount;
    const int pageCount = ceil((double)totalCount / countPerPage);
    const CGFloat itemW = 58;
    const CGFloat itemH = 80;
    const CGFloat marginLR = (self.width - itemW * colCount) / (colCount + 1);
    const CGFloat marginTB = 16;
    
    for (int i = 0; i < totalCount; i++) {
        
        const int currentPage = i / countPerPage;
        
        UIView *item = [UIView new];
        [SV addSubview:item];
        item.size = CGSizeMake(itemW, itemH);
        [item addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapItem:)]];
        item.x = marginLR + (item.width + marginLR) * (i % colCount) + SV.width * currentPage;
        item.y = marginTB + (item.height + marginTB) * (i / colCount) - (item.height + marginTB) * rowCount * currentPage;
        
        UIImageView *icon = [UIImageView new];
        [item addSubview:icon];
        icon.size = CGSizeMake(item.width, item.width);
        icon.backgroundColor = UIColor.whiteColor;
        icon.layer.cornerRadius = 8;
        icon.layer.masksToBounds = YES;
        icon.contentMode = UIViewContentModeCenter;
        icon.layer.borderWidth = 1;
        icon.layer.borderColor = UIColorMakeFromRGB(0x999999).CGColor;
        
        UILabel *des = [UILabel new];
        [item addSubview:des];
        des.font = FONT_SIZE(12);
        des.textColor = UIColorMakeFromRGB(0x444444);
        
        if (i == 0) {
        
            item.tag = MoreItemTypeAlbum;
            icon.image = [UIImage imageNamed:@"message_icon_photo"];
            des.text = @"照片";
        }
        else if (i == 1) {

            item.tag = MoreItemTypeCamera;
            icon.image = [UIImage imageNamed:@"message_icon_photograph"];
            des.text = @"拍摄";
        }
        else if (i == 2) {

            item.tag = MoreItemTypeLocation;
            icon.image = [UIImage imageNamed:@"message_icon_place"];
            des.text = @"位置";
        }
        
        [des sizeToFit];
        des.centerX = item.width / 2;
        des.y = item.height - des.height;
    }
    
    SV.contentSize = CGSizeMake(SV.width * pageCount, 0);
    if (pageCount > 1) {
        
        KeyboardPageControl *pageControl = [[KeyboardPageControl alloc] initWithPageCount:pageCount currentPage:0];
        [self addSubview:pageControl];
        _pageControl = pageControl;
        pageControl.y = KeyboardMoreViewPageControlY;
        pageControl.delegate = self;
    }
}

/**
 监听元素点击

 @param tap 手势
 */
- (void)didTapItem:(nonnull UITapGestureRecognizer *)tap {
    
    if ([self.delegate respondsToSelector:@selector(moreView:didSelectItemWithType:)]) {
        MoreItemType type = tap.view.tag;
        [self.delegate moreView:self didSelectItemWithType:type];
    }
}

/**
 更新页码显示
 */
- (void)updatePageControl {

    NSInteger page = _SV.contentOffset.x / _SV.width;
    _pageControl.currentPage = page;
}

#pragma mark - <WGKeyboardPageControlDelegate>

/**
 当前页发生变化时回调
 
 @param pageControl 自身
 */
- (void)currentPageDidChangeWithPageControl:(nonnull __kindof KeyboardPageControl *)pageControl {
    
    [_SV setContentOffset:CGPointMake(_SV.width * pageControl.currentPage, 0) animated:YES];
}

#pragma mark - <UIScrollViewDelegate>

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    
    if (!decelerate) {
        
        [self updatePageControl];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
    [self updatePageControl];
}

@end
