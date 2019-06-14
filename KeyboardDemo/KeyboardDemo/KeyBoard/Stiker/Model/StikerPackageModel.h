//
//  StikerPackageModel.h
//  Keyboard
//
//  Created by Veeco on 2019/5/23.
//  Copyright © 2019 Chance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StikerInfoModel.h"

// 表情包类型
typedef NS_ENUM(NSUInteger, StikerPackageType) {
    /** Emoji */
    StikerPackageTypeEmoji = 1,
    /** 收藏 */
    StikerPackageTypeColl,
    /** 官方 */
    StikerPackageTypeOffi,
};

NS_ASSUME_NONNULL_BEGIN

@interface StikerPackageModel : NSObject

/** 表情包类型 */
@property (assign, nonatomic) StikerPackageType stikerPackageType;
/** 本地封面 */
@property (nullable, nonatomic, strong) UIImage *localCover;
/** 网络封面 */
@property (nullable, nonatomic, copy) NSString *netCover;
/** 表情组 */
@property (nullable, nonatomic, copy) NSArray<StikerInfoModel *> *stikers;

@end

NS_ASSUME_NONNULL_END
