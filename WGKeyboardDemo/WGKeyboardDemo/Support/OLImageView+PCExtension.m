//
//  OLImageView+PCExtension.m
//  PuChi
//
//  Created by Veeco on 2019/5/5.
//  Copyright © 2019 Chance. All rights reserved.
//

#import "OLImageView+PCExtension.h"
#import <objc/runtime.h>
#import "SDImageHelper.h"
#import "OLImage.h"
#import "Masonry.h"

// 防重用标记的key
static const char deReuseKey;
// 菊花key
static const char chrysanthemumKey;

@implementation OLImageView (PCExtension)

#pragma mark - <Lazy>

- (UIActivityIndicatorView *)chrysanthemum {
    
    UIActivityIndicatorView *chrysanthemum = objc_getAssociatedObject(self, &chrysanthemumKey);
    if (!chrysanthemum) {
        
        chrysanthemum = [UIActivityIndicatorView new];
        [self addSubview:chrysanthemum];
        chrysanthemum.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        [chrysanthemum mas_makeConstraints:^(MASConstraintMaker *make) {
            
            make.top.left.bottom.right.mas_equalTo(0);
        }];
        objc_setAssociatedObject(self, &chrysanthemumKey, chrysanthemum, OBJC_ASSOCIATION_RETAIN);
    }
    return chrysanthemum;
}

#pragma mark - <Normal>

/**
 从网络加载gif
 
 @param url gif的url
 */
- (void)pc_setGifWithUrl:(nonnull NSURL *)url {
    
    // 0. 清除旧gif
    self.image = nil;
    
    // 1. 缓存url
    objc_setAssociatedObject(self, &deReuseKey, url.absoluteString, OBJC_ASSOCIATION_COPY);
    
    // 2. 菊花开转
    [[self chrysanthemum] startAnimating];
    
    // 3. 获取图片后 -> 过滤 -> 停止菊花 -> 加载gif
    __weak typeof(self) weakSelf = self;
    [SDImageHelper imageDataFromDiskCacheWithUrl:url finishHandle:^(NSData * _Nonnull data, NSURL * _Nonnull url) {
        __strong typeof(self) strongSelf = weakSelf;
        
        if (data.length && url.absoluteString.length) {
            
            NSString *ID = objc_getAssociatedObject(self, &deReuseKey);
            if ([ID isEqualToString:url.absoluteString]) {
                
                [[self chrysanthemum] stopAnimating];
                [strongSelf setGifWithData:data url:url];
            }
        }
    }];
}

/**
 加载gif
 
 @param data gif的数据
 @param url 图片url
 */
- (void)setGifWithData:(nonnull NSData *)data url:(nonnull NSURL *)url {
        
    OLImage *gifImage = (OLImage *)[OLImage imageWithData:data];
    self.image = gifImage;
}

@end
