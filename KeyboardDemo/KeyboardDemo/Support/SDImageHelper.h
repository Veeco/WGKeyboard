//
//  SDImageHelper.h
//  PuChi
//
//  Created by Veeco on 11/12/2017.
//  Copyright © 2017 Chance. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SDImageHelper : NSObject

/**
 获取SD缓存图片数据(旧)
 先从硬盘中查找, 如有直接回调, 无则下载保存到硬盘后再回调
 
 @param url 图片的url
 @param finishHandle 获取后的回调
 */
+ (void)imageDataFromDiskCacheWithUrl:(nonnull NSURL *)url finishHandle:(void (^ _Nonnull)(NSData * _Nonnull data, NSURL * _Nonnull url))finishHandle;

/**
 获取SD缓存图片数据
 先从硬盘中查找, 如有直接回调, 无则下载保存到硬盘后再回调
 
 @param url 图片的url
 @param finishHandle 获取后的回调
 */
+ (void)imagePathFromDiskCacheWithUrl:(nonnull NSURL *)url finishHandle:(void (^ _Nonnull)(NSString * _Nonnull path, NSURL * _Nonnull url))finishHandle;

/**
 获取SD缓存图片

 @param url 图片的url
 @return SD缓存图片
 */
+ (nullable UIImage *)getImageFromDiskCacheWithUrl:(nonnull NSURL *)url;

@end
