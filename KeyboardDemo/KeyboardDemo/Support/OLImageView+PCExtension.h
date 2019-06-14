//
//  OLImageView+PCExtension.h
//  PuChi
//
//  Created by Veeco on 2019/5/5.
//  Copyright © 2019 Chance. All rights reserved.
//

#import "OLImageView.h"

NS_ASSUME_NONNULL_BEGIN

@interface OLImageView (PCExtension)

/**
 从网络加载gif
 
 @param url gif的url
 */
- (void)pc_setGifWithUrl:(nonnull NSURL *)url;

@end

NS_ASSUME_NONNULL_END
