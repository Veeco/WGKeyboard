//
//  SDImageHelper.m
//  PuChi
//
//  Created by Veeco on 11/12/2017.
//  Copyright © 2017 Chance. All rights reserved.
//

#import "SDImageHelper.h"
#import "SDWebImageManager.h"

@implementation SDImageHelper

/**
 获取SD缓存图片数据
 先从硬盘中查找, 如有直接回调, 无则下载保存到硬盘后再回调
 
 @param url 图片的url
 @param finishHandle 获取后的回调
 */
+ (void)imageDataFromDiskCacheWithUrl:(nonnull NSURL *)url finishHandle:(void (^ _Nonnull)(NSData * _Nonnull data, NSURL * _Nonnull url))finishHandle {
    
    NSData *data = [self imageDataFromDiskCacheWithUrl:url];
    
    if (data) {
        
        finishHandle(data, url);
    }
    else {
        
        [self imageDataToDiskCacheWithUrl:url finishHandle:finishHandle];
    }
}

/**
 获取SD缓存图片数据
 先从硬盘中查找, 如有直接回调, 无则下载保存到硬盘后再回调
 
 @param url 图片的url
 @param finishHandle 获取后的回调
 */
+ (void)imagePathFromDiskCacheWithUrl:(nonnull NSURL *)url finishHandle:(void (^ _Nonnull)(NSString * _Nonnull path, NSURL * _Nonnull url))finishHandle {
    
    NSString *path = [self imagePathFromDiskCacheWithUrl:url];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        
        finishHandle(path, url);
    }
    else {
        
        [self imagePathToDiskCacheWithUrl:url finishHandle:finishHandle];
    }
}

/**
 获取硬盘中的图片数据
 
 @param url 图片的url
 @return 图片数据
 */
+ (nullable NSData *)imageDataFromDiskCacheWithUrl:(nonnull NSURL *)url {
    
    NSString *path = [[[SDWebImageManager sharedManager] imageCache] defaultCachePathForKey:url.absoluteString];
    
    return [NSData dataWithContentsOfFile:path];
}

/**
 获取硬盘中的图片数据
 
 @param url 图片的url
 @return 图片数据
 */
+ (nullable NSString *)imagePathFromDiskCacheWithUrl:(nonnull NSURL *)url {
    
    return [[[SDWebImageManager sharedManager] imageCache] defaultCachePathForKey:url.absoluteString];
}

/**
 下载并缓存进硬盘
 
 @param url 图片的url
 @param finishHandle 下载缓存完成后的回调
 */
+ (void)imageDataToDiskCacheWithUrl:(nonnull NSURL *)url finishHandle:(void (^ _Nonnull)(NSData * _Nonnull data, NSURL * _Nonnull url))finishHandle {
    
    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:url options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        
        finishHandle(data, url);
        
        [[SDWebImageManager sharedManager].imageCache storeImage:image imageData:data forKey:url.absoluteString toDisk:YES completion:nil];
    }];
}

/**
 下载并缓存进硬盘
 
 @param url 图片的url
 @param finishHandle 下载缓存完成后的回调
 */
+ (void)imagePathToDiskCacheWithUrl:(nonnull NSURL *)url finishHandle:(void (^ _Nonnull)(NSString * _Nonnull path, NSURL * _Nonnull url))finishHandle {
    
    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:url options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        
        [[SDWebImageManager sharedManager].imageCache storeImage:image imageData:data forKey:url.absoluteString toDisk:YES completion:^{
            
            finishHandle([self imagePathFromDiskCacheWithUrl:url], url);
        }];
    }];
}

/**
 获取SD缓存图片
 
 @param url 图片的url
 @return SD缓存图片
 */
+ (nullable UIImage *)getImageFromDiskCacheWithUrl:(nonnull NSURL *)url {
    
    return [UIImage imageWithData:[self imageDataFromDiskCacheWithUrl:url]];
}

@end
