//
//  StikerInfoModel.h
//  Keyboard
//
//  Created by Veeco on 2019/5/23.
//  Copyright © 2019 Chance. All rights reserved.
//

#import <Foundation/Foundation.h>

// 表情类型
typedef NS_ENUM(NSUInteger, StikerType) {
    /** Emoji */
    StikerTypeEmoji = 1,
    /** 自定义 */
    StikerTypeCustom,
    /** 加号 */
    StikerTypeAdd,
};

NS_ASSUME_NONNULL_BEGIN

@interface StikerInfoModel : NSObject

/** 表情类型 */
@property (assign, nonatomic) StikerType stikerType;
/** 表情标题 */
@property (nullable, nonatomic, copy) NSString *stikerTitle;
/** 表情封面 */
@property (nullable, nonatomic, copy) NSString *stikerCover;
/** 表情本体 */
@property (nullable, nonatomic, copy) NSString *stiker;
/** 表情宽 */
@property (assign, nonatomic) CGFloat stikerWidth;
/** 表情高 */
@property (assign, nonatomic) CGFloat stikerHeight;
/** 是否为官方表情 */
@property (assign, nonatomic) BOOL offiStiker;
/** 官方表情包ID */
@property (assign, nonatomic) NSInteger offiStikerPackageID;
/** 官方表情ID */
@property (assign, nonatomic) NSInteger offiStikerID;

@end

NS_ASSUME_NONNULL_END
