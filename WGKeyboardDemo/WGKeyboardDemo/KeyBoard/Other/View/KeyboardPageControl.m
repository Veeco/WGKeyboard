//
//  KeyboardPageControl.m
//  Keyboard
//
//  Created by Veeco on 2019/5/17.
//  Copyright © 2019 Chance. All rights reserved.
//

#import "KeyboardPageControl.h"
#import "WGKeyboardHeader.h"

@interface KeyboardPageControl ()

{
    /** 总页数 */
    NSInteger _pageCount;
    /** 是否已超过最大页数量(超过时将显示一条线, 而非多圆点) */
    BOOL _overPages;
    
    // 直线显示
    
    /** 直线 */
    UIView *_line;
    /** 圆点 */
    UIView *_dot;
    
    // 圆点组显示
    
    /** 圆点数组 */
    NSArray<UIView *> *_dots;
}

@end

// 圆点宽高
static const CGFloat kDotWH = 7;
static const CGFloat kDotMargin = 12;

@implementation KeyboardPageControl

#pragma mark - <Getter & Setter>

- (void)setCurrentPage:(NSInteger)currentPage {
    
    if (_currentPage == currentPage || currentPage < 0 || currentPage >= _pageCount) {
        
        return;
    }
    NSInteger oriIndex = _currentPage;
    _currentPage = currentPage;
    
    [UIView animateWithDuration:0.15f animations:^{
        
        if (self->_overPages) {
            
            const CGFloat per = self->_line.width / (self->_pageCount - 1);
            self->_dot.centerX = per * currentPage;
        }
        else {
            
            self->_dots[oriIndex].backgroundColor = [self getDotColorWithSelect:NO];
            self->_dots[currentPage].backgroundColor = [self getDotColorWithSelect:YES];
        }
    }];
}

#pragma mark - <System>

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    
    const CGFloat offset = 10;
    
    if (point.y > -offset && point.y < self.height + offset) {
        
        return YES;
    }
    return [super pointInside:point withEvent:event];
}

#pragma mark - <Normal>

/**
 实例化
 
 @param pageCount 总页数
 @param currentPage 当前页
 @return 实例
 */
- (instancetype)initWithPageCount:(NSInteger)pageCount currentPage:(NSInteger)currentPage {
    if (self = [super initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, KeyboardPageControlHeight)]) {
        
        if (pageCount > 1) {
            
            _pageCount = pageCount;
            _currentPage = currentPage;
            
            [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapSelf:)]];
            [self addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPanSelf:)]];
            
            // 初始化UI
            [self initUI];
            
            // 设置默认页
            [self initDefaultPage];
        }
    }
    return self;
}

/**
 设置默认页
 */
- (void)initDefaultPage {
    
    if (_overPages) {
        
        UIView *dot = [self createDot];
        [_line addSubview:dot];
        _dot = dot;
        dot.backgroundColor = [self getDotColorWithSelect:YES];
        dot.centerY = _line.height / 2;
    }
    else {
        
        _dots[self.currentPage].backgroundColor = [self getDotColorWithSelect:YES];
    }
}

/**
 初始化UI
 */
- (void)initUI {
    
    // 判断是否超过最大页码数
    const CGFloat dotsW = kDotWH * _pageCount + kDotMargin * (_pageCount - 1);
    const CGFloat beginX = (self.width - dotsW) / 2;
    if (beginX < kDotMargin) {

        _overPages = YES;
    }
    NSMutableArray *arrM = @[].mutableCopy;
    // 超过最大页码数 -> 直线显示
    if (_overPages) {
        
        UIView *line = [UIView new];
        [self addSubview:line];
        _line = line;
        line.x = kDotMargin + kDotWH / 2;
        line.width = self.width - line.x * 2;
        line.height = 0.5f;
        line.centerY = self.height / 2;
        line.backgroundColor = UIColor.lightGrayColor;
    }
    // 未超过最大页码数 -> 圆点组显示
    else {
        
        for (int i = 0; i < _pageCount; i++) {
            
            UIView *dot = [self createDot];
            [self addSubview:dot];
            [arrM addObject:dot];
            
            dot.x = beginX + (kDotMargin + dot.width) * i;
            dot.centerY = self.height / 2;
        }
    }
    _dots = arrM;
}

/**
 创建小圆点

 @return 小圆点
 */
- (nonnull UIView *)createDot {
    
    UIView *dot = [UIView new];
    dot.size = CGSizeMake(kDotWH, kDotWH);
    dot.backgroundColor = [self getDotColorWithSelect:NO];
    dot.layer.cornerRadius = dot.height / 2;
    dot.layer.masksToBounds = YES;
    
    return dot;
}

/**
 获取圆点颜色

 @param select 是否选中状态
 @return 圆点颜色
 */
- (nonnull UIColor *)getDotColorWithSelect:(BOOL)select {
    
    return select ? UIColor.blackColor : UIColor.lightGrayColor;
}

/**
 处理手势

 @param gesture 手势
 */
- (void)handleGesture:(nonnull UIGestureRecognizer *)gesture {
    
    if (_overPages) {
        
        const CGFloat x = [self convertPoint:[gesture locationInView:self] toView:_line].x;
        const CGFloat per = self->_line.width / (self->_pageCount - 1);
        const CGFloat beginX = -per / 2;
        
        for (int i = 0; i < self->_pageCount; i++) {
            
            const CGFloat maxX = beginX + per * (i + 1);
            
            if (x < maxX) {
                
                [self handleCallbackWithPage:i];
                
                break;
            }
        }
    }
    else {
        
        const CGFloat x = [gesture locationInView:self].x;
        if (x < _dots.firstObject.x - kDotMargin / 2 || x > CGRectGetMaxX(_dots.lastObject.frame) + kDotMargin / 2) {
            
            return;
        }
        [_dots enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if (x > obj.x - kDotMargin / 2 && x < CGRectGetMaxX(obj.frame) + kDotMargin / 2) {
                
                [self handleCallbackWithPage:idx];
                
                *stop = YES;
            }
        }];
    }
}

/**
 处理回调

 @param page 目标页码
 */
- (void)handleCallbackWithPage:(NSInteger)page {
    
    if (page == self.currentPage) {
        
        return;
    }
    self.currentPage = page;
    
    if ([self.delegate respondsToSelector:@selector(currentPageDidChangeWithPageControl:)]) {
        [self.delegate currentPageDidChangeWithPageControl:self];
    }
}

/**
 监听自身点击

 @param tap 手势
 */
- (void)didTapSelf:(nonnull UITapGestureRecognizer *)tap {
    
    [self handleGesture:tap];
}

/**
 监听自身拖曳

 @param pan 手势
 */
- (void)didPanSelf:(nonnull UIPanGestureRecognizer *)pan {
    
    [self handleGesture:pan];
}

@end
