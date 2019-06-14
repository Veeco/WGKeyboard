//
//  WGVoiceManager.m
//
//  Created by vs on 2017/3/2.
//

#import "WGVoiceManager.h"
#import <AVFoundation/AVFoundation.h>

@interface WGVoiceManager ()<AVAudioRecorderDelegate, AVAudioPlayerDelegate>

{
    /** 当前录音音频文件路径 */
    NSString *_currentRecordFilePath;
    /** 开始录音时间戳 */
    NSTimeInterval _recordStartTime;
}

/** 录音器 */
@property (nonatomic, strong) AVAudioRecorder *recorder;
/** 定时器 */
@property (nonatomic, strong) CADisplayLink *displayLink;
/** 播放器 */
@property (nonatomic, strong) AVAudioPlayer *player;
/** 代理 */
@property (nullable, nonatomic, strong) NSHashTable<NSObject<WGVoiceManagerDelegate> *> *delegates;

@end

@implementation WGVoiceManager

#pragma mark - <懒加载>

/**
 * 懒加载 定时器
 */
- (CADisplayLink *)displayLink {
    
    if (_displayLink == nil) {
        
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(meteringRecorder)];
    }
    return _displayLink;
}

- (NSHashTable *)delegates {
    if (!_delegates) {
        
        self.delegates = [NSHashTable weakObjectsHashTable];
    }
    return _delegates;
}

#pragma mark - <常规逻辑>

// 单例
static WGVoiceManager *_manager;

/**
 * 获取单例
 */
+ (nonnull __kindof WGVoiceManager *)manager {

    return [self allocWithZone:nil];
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        _manager = [[super allocWithZone:zone] init];
    });
    return _manager;
}

/**
 * 定时器调用
 */
- (void)meteringRecorder {

    // 刷新录音接收分贝
    [self.recorder updateMeters];
    
    // 平均分贝
    float volume = [self.recorder averagePowerForChannel:0] + 120;
    
    // 调用 代理方法1 监听录音音量改变
    for (id <WGVoiceManagerDelegate> obj in self.delegates.copy) {
        
        if ([obj respondsToSelector:@selector(manager:gotVolume:)]) {
            [obj manager:self gotVolume:volume];
        }
    }
}

/**
 添加代理
 
 @param delegate 代理
 */
+ (void)addDelegate:(nonnull NSObject<WGVoiceManagerDelegate> *)delegate {
    
    [[self manager].delegates addObject:delegate];
}

/**
 移除代理
 
 @param delegate 代理
 */
+ (void)removeDelegate:(nonnull NSObject<WGVoiceManagerDelegate> *)delegate {
    
    [[self manager].delegates removeObject:delegate];
}

/**
 *  开始录音
 
 @pramr path 存放路径
 */
- (void)recordStartWithPath:(nonnull NSString *)path {
    
    if (self.recorder.isRecording || path.length == 0) {
        
        return;
    }
    
    // 设置录音格式信息
    NSMutableDictionary *setting = [NSMutableDictionary dictionary];
    
    /*
     * settings 参数
     1. AVFormatIDKey
     2. AVNumberOfChannelsKey 通道数 通常为双声道 值2
     3. AVSampleRateKey 采样率 单位HZ 通常设置成44100 也就是44.1k,采样率必须要设为11025才能使转化成mp3格式后不会失真
     4. AVLinearPCMBitDepthKey 比特率 8 16 24 32
     5. AVEncoderAudioQualityKey 声音质量
     ① AVAudioQualityMin  = 0, 最小的质量
     ② AVAudioQualityLow  = 0x20, 比较低的质量
     ③ AVAudioQualityMedium = 0x40, 中间的质量
     ④ AVAudioQualityHigh  = 0x60,高的质量
     ⑤ AVAudioQualityMax  = 0x7F 最好的质量
     6. AVEncoderBitRateKey 音频编码的比特率 单位Kbps 传输的速率 一般设置128000 也就是128kbps
     */
    
    setting[@"AVFormatIDKey"] = @(kAudioFormatMPEG4AAC);
    setting[@"AVSampleRateKey"] = @11025.0;
    
    _currentRecordFilePath = path;
    
    // 初始化录音器
    AVAudioRecorder *recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL URLWithString:_currentRecordFilePath] settings:setting error:nil];
    self.recorder = recorder;
    
    // 设置代理
    recorder.delegate = self;
    
    // 允许监听录音分贝
    recorder.meteringEnabled = YES;
    
    // 准备录音
    if ([recorder prepareToRecord]) {
        
        // 设置声音处理方式为录音+听筒播放 占用声音通道
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        
        // 开始录音
        [recorder record];
        
        _recordStartTime = [NSDate date].timeIntervalSince1970;
        
        // 启动计时器
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
}

/**
 *  停止录音
 */
- (void)recordStop {
    
    if (!self.recorder.isRecording) return;
    
    // 停止录音
    [self.recorder stop];
    //归还声音通道
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    // 停止计时器
    [self displayStop];
}

/**
 *  取消录音
 */
- (void)recordCancel {
    
    if (!self.recorder.isRecording) return;
    
    // 停止并删除录音
    [self.recorder stop];
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.recorder.url.path]) {
        [self.recorder deleteRecording];
    }
    _currentRecordFilePath = nil;
    //归还声音通道
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    // 停止计时器
    [self displayStop];
}

/**
 * 停止计时器
 */
- (void)displayStop {
    
    [self.displayLink invalidate];
    self.displayLink = nil;
}

/**
 * 检查录音状态
 * 返回 是否正在录音
 */
- (BOOL)isRecording {

    return self.recorder.isRecording;
}

/**
 * 播放语音
 * 参数 path 音频文件路径
 * 返回 是否播放成功
 */
- (BOOL)playWithPath:(nonnull NSString *)path {
    
    // 获取播放声音文件数据
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) return NO;
    
    if (self.isPlaying) {
        
        [self.player stop];
        [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    }
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:path] error:nil];
    self.player.delegate = self;
    self.player.volume = 1.0;
    
    if ([self.player prepareToPlay]) {
        
        // 设置声音处理方式为喇叭播放
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        
        return [self.player play];
    }
    return NO;
}

/**
 停止播放
 */
- (void)stopPlay {
    
    [self.player stop];
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
}

/**
 * 检查播放状态
 * 返回 是否正在播放
 */
- (BOOL)isPlaying {

    return self.player.isPlaying;
}

#pragma mark - <AVAudioRecorderDelegdte>

/**
 * 监听录音完成
 * 参数 recorder 录音器
 * 返回 flag 成功与否
 */
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    
    // 录音时长
    NSTimeInterval dua = [NSDate date].timeIntervalSince1970 - _recordStartTime;
    _recordStartTime = 0;
    
    // 调用 代理方法2 监听录音完成
    for (id <WGVoiceManagerDelegate> obj in self.delegates.copy) {
        
        if (flag && [obj respondsToSelector:@selector(manager:didRecordWithPath:duration:)] && [[NSFileManager defaultManager] fileExistsAtPath:_currentRecordFilePath]) {
            [obj manager:self didRecordWithPath:_currentRecordFilePath duration:dua];
        }
    }
    _currentRecordFilePath = nil;
}

#pragma mark - <AVAudioPlayerDelegdte>

/**
 * 监听播放完成
 * 参数 player 播放器
 * 返回 flag 成功与否
 */
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    
    if (!flag) return;
    
    // 调用 代理方法3 监听播放完成
    for (id <WGVoiceManagerDelegate> obj in self.delegates.copy) {
        
        if ([obj respondsToSelector:@selector(didPlayFinishWithManager:)]) {
            [obj didPlayFinishWithManager:self];
        }
    }
    //归还声音通道
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
}

@end
