//
//  UUIDHelper.m
//  PuChi
//
//  Created by Veeco on 2017/11/14.
//  Copyright © 2017年 Chance. All rights reserved.
//

#import "UUIDHelper.h"

// UUID Key
static NSString *const kUUIDKey = @"kUUIDKey";

@implementation UUIDHelper

/**
 获取UUID
 
 @return UUID
 */
+ (nonnull NSString *)getRandomUUID {
    
    // 生成一个UUID
    CFUUIDRef UUIDRef = CFUUIDCreate(kCFAllocatorDefault);
    NSString *UUID = (NSString *)CFBridgingRelease(CFUUIDCreateString (kCFAllocatorDefault, UUIDRef));
    UUID = UUID.lowercaseString;
    
    return UUID;
}

@end
