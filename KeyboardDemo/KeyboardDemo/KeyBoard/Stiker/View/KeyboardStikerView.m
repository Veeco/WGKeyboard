//
//  KeyboardStikerView.m
//  Keyboard
//
//  Created by Veeco on 2019/4/11.
//  Copyright © 2019 Chance. All rights reserved.
//

#import "KeyboardStikerView.h"
#import "WGKeyboardHeader.h"
#import "StikerCoverView.h"
#import "StikerPackageModel.h"
#import "StikerEmojiCell.h"
#import "StikerCumtomCell.h"
#import "KeyboardPageControl.h"

@interface KeyboardStikerView () <StikerCoverViewDelegate, UICollectionViewDataSource, KeyboardPageControlDelegate, UICollectionViewDelegate, StikerEmojiCellDelegate, StikerCumtomCellDelegate>

{
    /** 表情包 */
    NSArray<StikerPackageModel *> *_stikerPackages;
    /** 封面条 */
    StikerCoverView *_cover;
    /** 当前表情包下标 */
    NSInteger _currentIndexStikerPackage;
    /** 表情大容器 */
    UICollectionView *_CV;
    /** 页码数据 */
    NSArray<NSMutableDictionary *> *_pageInfo;
    /** 表情分页数据 */
    NSArray<NSArray<NSArray<StikerInfoModel *> *> *> *_stikers;
    /** 页码指示器 */
    KeyboardPageControl *_pageControl;
    /** 上一次的偏移量 */
    NSInteger _CVOffsetIndex;
}

@end

// 表情页码key
static NSString *const kCurrentPageKey = @"kCurrentPageKey";
static NSString *const kTotalPageKey = @"kTotalPageKey";

@implementation KeyboardStikerView

#pragma mark - <Getter & Setter>

- (void)setDataSource:(NSObject<KeyboardStikerViewDataSource> *)dataSource {
    _dataSource = dataSource;
    
    [self reloadData];
}

#pragma mark - <System>

- (instancetype)initWithFrame:(CGRect)frame {
    frame.size = CGSizeMake(SCREEN_WIDTH, KeyboardStikerViewHeight);
    if (self = [super initWithFrame:frame]) {
        
        // 初始化UI
        [self initUI];
        
        // 刷新
        [self reloadData];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(willResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

#pragma mark - <Normal>

/**
 监听程序失焦
 */
- (void)willResignActive {
    
    NSInteger page = [_pageInfo[_currentIndexStikerPackage][kCurrentPageKey] integerValue];
    StikerCumtomCell *cell = (StikerCumtomCell *)[_CV cellForItemAtIndexPath:[NSIndexPath indexPathForItem:page inSection:_currentIndexStikerPackage]];
    if ([cell isKindOfClass:StikerCumtomCell.class]) {
        
        [cell willResignActive];
    }
}

/**
 实例化
 
 @return 自身
 */
+ (instancetype)stikerView {
    
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
}

/**
 刷新
 */
- (void)reloadData {
    
    // 清空
    [_cover removeFromSuperview];
    _cover = nil;
    _stikerPackages = nil;
    _currentIndexStikerPackage = 0;
    [_CV removeFromSuperview];
    _CV = nil;
    _pageInfo = nil;
    _stikers = nil;
    [_pageControl removeFromSuperview];
    _pageControl = nil;
    _CVOffsetIndex = 0;
    
    if ([self.dataSource respondsToSelector:@selector(stikerPackagesInStikerView:)]) {
        _stikerPackages = [self.dataSource stikerPackagesInStikerView:self];
    }
    if (_stikerPackages.count == 0) {
        
        return;
    }
    
    NSMutableArray<NSMutableDictionary *> *pageInfoArrM = @[].mutableCopy;
    NSMutableArray<NSArray<NSArray<StikerInfoModel *> *> *> *stikerPackageArrM = @[].mutableCopy;
    [_stikerPackages enumerateObjectsUsingBlock:^(StikerPackageModel * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
        
        // 页码数据
        NSMutableDictionary *dic = @{}.mutableCopy;
        dic[kCurrentPageKey] = @0;
        
        if (model.stikerPackageType == StikerPackageTypeEmoji) {
            
            dic[kTotalPageKey] = @(ceil((double)model.stikers.count / StikerEmojiCell.countPerPage));
        }
        else if (model.stikerPackageType == StikerPackageTypeColl || model.stikerPackageType == StikerPackageTypeOffi) {
            
            dic[kTotalPageKey] = @(ceil((double)model.stikers.count / StikerCumtomCell.countPerPage));
        }
        [pageInfoArrM addObject:dic];
        
        // 表情分页
        NSMutableArray<NSArray<StikerInfoModel *> *> *stikerPageArrM = @[].mutableCopy;
        NSInteger countPerPage = 0;
        if (model.stikerPackageType == StikerPackageTypeEmoji) {
            
            countPerPage = StikerEmojiCell.countPerPage;
        }
        else if (model.stikerPackageType == StikerPackageTypeColl || model.stikerPackageType == StikerPackageTypeOffi) {
            
            countPerPage = StikerCumtomCell.countPerPage;
        }
        if (countPerPage) {
            
            __block NSMutableArray<StikerInfoModel *> *stikerArrM = @[].mutableCopy;
            
            [model.stikers enumerateObjectsUsingBlock:^(StikerInfoModel * _Nonnull stiker, NSUInteger idx, BOOL * _Nonnull stop) {
               
                __block BOOL otherPage = NO;
                
                if (idx % countPerPage == 0) {
                    
                    otherPage = YES;
                }
                
                if (otherPage) {
                    
                    stikerArrM = @[].mutableCopy;
                }
                [stikerArrM addObject:stiker];
                
                if (![stikerPageArrM containsObject:stikerArrM]) {
                    
                    [stikerPageArrM addObject:stikerArrM];
                }
            }];
        }
        [stikerPackageArrM addObject:stikerPageArrM];
    }];
    _pageInfo = pageInfoArrM;
    _stikers = stikerPackageArrM;
    
    // 底部封面条
    StikerCoverView *cover = [[StikerCoverView alloc] initWithStikerPackages:_stikerPackages];
    [self addSubview:cover];
    _cover = cover;
    cover.y = StikerCoverViewY;
    cover.delegate = self;
    
    // 表情主体
    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.itemSize = CGSizeMake(self.width, StikerContentViewHeight);
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    UICollectionView *CV = [[UICollectionView alloc] initWithFrame:(CGRect){CGPointZero, layout.itemSize} collectionViewLayout:layout];
    [self addSubview:CV];
    _CV = CV;
    CV.backgroundColor = UIColor.whiteColor;
    CV.pagingEnabled = YES;
    CV.showsHorizontalScrollIndicator = NO;
    [CV registerClass:StikerEmojiCell.class forCellWithReuseIdentifier:NSStringFromClass(StikerEmojiCell.class)];
    [CV registerClass:StikerCumtomCell.class forCellWithReuseIdentifier:NSStringFromClass(StikerCumtomCell.class)];
    [CV registerClass:UICollectionViewCell.class forCellWithReuseIdentifier:NSStringFromClass(UICollectionViewCell.class)];
    CV.dataSource = self;
    CV.delegate = self;
    
    // 更新页码指示
    [self updatePageControl];
}

/**
 滚动后处理
 */
- (void)handleDidScroll {
    
    NSInteger index = [self getCVCurrentPageIndex];
    
    if (_CVOffsetIndex == index) {
        
        return;
    }
    _CVOffsetIndex = index;
    
    // 更新页码指示
    [self updatePageControl];
}

/**
 获取CV当前页码

 @return CV当前页码
 */
- (NSInteger)getCVCurrentPageIndex {
    
    NSInteger index = _CV.contentOffset.x / _CV.width;
    NSInteger other = (NSInteger)_CV.contentOffset.x % (NSInteger)_CV.width;
    if (other > _CV.width / 2) {
        
        index++;
    }
    return index;
}

/**
 更新页码指示
 */
- (void)updatePageControl {
    
    // 对旧的页码展示作处理
    if (_pageControl) {
        
        __block BOOL isNewPageControl = NO;
        NSInteger offsetIndex = [self getCVCurrentPageIndex];
        __block NSInteger pages = 0;
        [_pageInfo enumerateObjectsUsingBlock:^(NSMutableDictionary * _Nonnull dic, NSUInteger idx, BOOL * _Nonnull stop) {
           
            pages += [dic[kTotalPageKey] integerValue];
            if (offsetIndex < pages) {
                
                isNewPageControl = idx != self->_currentIndexStikerPackage;
                self->_currentIndexStikerPackage = idx;
                
                *stop = YES;
            }
        }];
        
        if (isNewPageControl) {
            
            [_pageControl removeFromSuperview];
            _pageControl = nil;
            
            _cover.currentIndex = self->_currentIndexStikerPackage;
        }
    }
    
    // 更新当前页信息
    NSInteger offsetIndex = [self getCVCurrentPageIndex];
    __block NSInteger pages = 0;
    [_pageInfo enumerateObjectsUsingBlock:^(NSMutableDictionary * _Nonnull dic, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSInteger tempPages = pages + [dic[kTotalPageKey] integerValue];
        if (offsetIndex < tempPages) {
            
            NSInteger currentIndex = offsetIndex - pages;
            self->_pageInfo[self->_currentIndexStikerPackage][kCurrentPageKey] = @(currentIndex);
            
            *stop = YES;
        }
        pages = tempPages;
    }];
    
    NSInteger currentPage = [_pageInfo[_currentIndexStikerPackage][kCurrentPageKey] integerValue];
    
    // 创建
    if (!_pageControl) {
        
        NSInteger totalPage = [_pageInfo[_currentIndexStikerPackage][kTotalPageKey] integerValue];
        if (totalPage) {
            
            KeyboardPageControl *pageControl = [[KeyboardPageControl alloc] initWithPageCount:totalPage currentPage:currentPage];
            [self addSubview:pageControl];
            _pageControl = pageControl;
            pageControl.y = CGRectGetMaxY(_CV.frame);
            pageControl.delegate = self;
        }
    }
    else {
        
        // 更新当前页展示
        _pageControl.currentPage = currentPage;
    }
}

/**
 表情回调
 
 @param stiker 所选表情
 */
- (void)stikerCallbackWithStiker:(nonnull StikerInfoModel *)stiker {
    
    if ([self.delegate respondsToSelector:@selector(stikerView:didSelectStiker:)]) {
        [self.delegate stikerView:self didSelectStiker:stiker];
    }
}

#pragma mark - <StikerCoverViewDelegate>

/**
 当前下标发生变化时回调
 
 @param coverView 自身
 */
- (void)currentIndexDidChangeWithCoverView:(nonnull __kindof StikerCoverView *)coverView {
    
    _currentIndexStikerPackage = coverView.currentIndex;
    
    __block NSInteger pages = 0;
    [_pageInfo enumerateObjectsUsingBlock:^(NSMutableDictionary * _Nonnull dic, NSUInteger idx, BOOL * _Nonnull stop) {
       
        if (idx == self->_currentIndexStikerPackage) {
            
            NSInteger offset = pages + [dic[kCurrentPageKey] integerValue];
            self->_CV.contentOffset = CGPointMake(self->_CV.width * offset, 0);
            self->_CVOffsetIndex = [self getCVCurrentPageIndex];
            
            [self->_pageControl removeFromSuperview];
            self->_pageControl = nil;
            
            [self updatePageControl];
            
            *stop = YES;
        }
        pages += [dic[kTotalPageKey] integerValue];
    }];
}

/**
 点击发送时回调
 
 @param coverView 自身
 */
- (void)didTapSendWithCoverView:(nonnull __kindof StikerCoverView *)coverView {
    
    if ([self.delegate respondsToSelector:@selector(didTapSendWithStikerView:)]) {
        [self.delegate didTapSendWithStikerView:self];
    }
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    
    return _stikers.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return _stikers[section].count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSArray<StikerInfoModel *> *stikers = _stikers[indexPath.section][indexPath.item];
    UICollectionViewCell *cell = nil;
    if (stikers.firstObject.stikerType == StikerTypeEmoji) {
        
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(StikerEmojiCell.class) forIndexPath:indexPath];
        if ([cell isKindOfClass:StikerEmojiCell.class]) {
            
            StikerEmojiCell *emojiCell = (StikerEmojiCell *)cell;
            emojiCell.stikers = stikers;
            emojiCell.delegate = self;
        }
    }
    else if (stikers.firstObject.stikerType == StikerTypeCustom || stikers.firstObject.stikerType == StikerTypeAdd) {
        
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(StikerCumtomCell.class) forIndexPath:indexPath];
        if ([cell isKindOfClass:StikerCumtomCell.class]) {
            
            StikerCumtomCell *customCell = (StikerCumtomCell *)cell;
            customCell.stikers = stikers;
            customCell.delegate = self;
            customCell.keyboard = self.keyboard;
        }
    }
    else {
        
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(UICollectionViewCell.class) forIndexPath:indexPath];
    }
    return cell;
}

#pragma mark - <KeyboardPageControlDelegate>

/**
 当前页发生变化时回调
 
 @param pageControl 自身
 */
- (void)currentPageDidChangeWithPageControl:(nonnull __kindof KeyboardPageControl *)pageControl {
    
    __block NSInteger pages = 0;
    
    [_pageInfo enumerateObjectsUsingBlock:^(NSMutableDictionary * _Nonnull dic, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (idx == self->_currentIndexStikerPackage) {
            
            dic[kCurrentPageKey] = @(pageControl.currentPage);
            
            NSInteger offset = pages + pageControl.currentPage;
            self->_CV.contentOffset = CGPointMake(self->_CV.width * offset, 0);
            self->_CVOffsetIndex = [self getCVCurrentPageIndex];
            
            *stop = YES;
        }
        pages += [dic[kTotalPageKey] integerValue];
    }];
}

#pragma mark - <UIScrollViewDelegate>

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
        
    [self handleDidScroll];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
    [self handleDidScroll];
}

#pragma mark - <StikerEmojiCellDelegate>

/**
 选择表情回调
 
 @param emojiCell 自身
 @param stiker 所选表情
 */
- (void)emojiCell:(nonnull __kindof StikerEmojiCell *)emojiCell didSelectStiker:(nonnull StikerInfoModel *)stiker {
    
    [self stikerCallbackWithStiker:stiker];
}

#pragma mark - <StikerCumtomCellDelegate>

/**
 选择表情回调
 
 @param customCell 自身
 @param stiker 所选表情
 */
- (void)customCell:(nonnull __kindof StikerCumtomCell *)customCell didSelectStiker:(nonnull StikerInfoModel *)stiker {
    
    [self stikerCallbackWithStiker:stiker];
}

@end
