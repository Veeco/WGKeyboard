//
//  WGVoiceManager.h
//
//  Created by Veeco on 2017/3/2.
//

#import <Foundation/Foundation.h>
@class WGVoiceManager;

@protocol WGVoiceManagerDelegate <NSObject>

@optional

/**
 * 代理方法1 监听录音音量改变
 * 参数 manager 本单例
 * 参数 volumn 音量值 (0 ~ 120 可将有效值看为 80 ~ 110)
 */
- (void)manager:(nonnull __kindof WGVoiceManager *)manager gotVolume:(float)volume;

/**
 * 代理方法2 监听录音完成
 * 参数 manager 本单例
 * 参数 duration 时长
 * 返回 path 音频文件路径
 */
- (void)manager:(nonnull __kindof WGVoiceManager *)manager didRecordWithPath:(nonnull NSString *)path duration:(NSTimeInterval)duration;

/**
 * 代理方法3 监听播放完成
 * 参数 manager 本单例
 */
- (void)didPlayFinishWithManager:(nonnull __kindof WGVoiceManager *)manager;

@end

@interface WGVoiceManager : NSObject

/**
 添加代理
 
 @param delegate 代理
 */
+ (void)addDelegate:(nonnull NSObject<WGVoiceManagerDelegate> *)delegate;

/**
 移除代理
 
 @param delegate 代理
 */
+ (void)removeDelegate:(nonnull NSObject<WGVoiceManagerDelegate> *)delegate;

/**
 * 获取单例
 */
+ (nonnull __kindof WGVoiceManager *)manager;

/**
 *  开始录音
 
 @pramr path 存放路径
 */
- (void)recordStartWithPath:(nonnull NSString *)path;

/**
 *  停止录音
 */
- (void)recordStop;

/**
 *  取消录音
 */
- (void)recordCancel;

/**
 * 播放语音
 * 参数 path 音频文件路径
 * 返回 是否播放成功
 */
- (BOOL)playWithPath:(nonnull NSString *)path;

/**
 停止播放
 */
- (void)stopPlay;

/**
 * 检查播放状态
 * 返回 是否正在播放
 */
- (BOOL)isPlaying;

/**
 * 检查录音状态
 * 返回 是否正在录音
 */
- (BOOL)isRecording;

@end
