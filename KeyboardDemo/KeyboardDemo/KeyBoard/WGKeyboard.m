//
//  WGKeyboard.m
//  Keyboard
//
//  Created by Veeco on 2019/3/26.
//  Copyright © 2019 Chance. All rights reserved.
//

#import "WGKeyboard.h"
#import "KeyboardStikerView.h"
#import "WGVoiceManager.h"
#import "NSTimer+WGExtension.h"
#import "Masonry.h"
#import "WGKeyboardHeader.h"
#import "UUIDHelper.h"
#import "WGTextView.h"

// 输入状态
typedef NS_ENUM(NSUInteger, InputStatus) {
    InputStatusUnknow, // 未知
    InputStatusText, // 文字
    InputStatusStiker, // 表情
    InputStatusMore, // 更多
    InputStatusVoice // 语音
};

@interface WGKeyboard () <UITextViewDelegate, WGVoiceManagerDelegate, KeyboardMoreViewDelegate, KeyboardStikerViewDataSource, KeyboardStikerViewDelegate, WGTextViewDelegate>

{
    /** 键盘类型 */
    KeyboardType _keyboardType;
    /** 当前输入状态 */
    InputStatus _currentInputStatus;
    /** 即将进入的输入状态 */
    InputStatus _willInputStatus;
    /** 顶部工具栏 */
    UIView *_topToolBar;
    /** 语音按钮 */
    UIButton *_voiceBtn;
    /** 表情按钮 */
    UIButton *_stikerBtn;
    /** 更多按钮 */
    UIButton *_moreBtn;
    /** 输入框容器 */
    UIView *_TVView;
    /** 输入框 */
    WGTextView *_TV;
    /** 当前输入框容量高度 */
    CGFloat _TVContentH;
    /** 系统键盘属性 */
    BOOL _sysKeyboardUp;
    CGFloat _sysKeyboardY;
    /** 语音输入框 */
    UIView *_voiceInput;
    /** 表情 */
    KeyboardStikerView *_stikerView;
    /** 更多 */
    KeyboardMoreView *_moreView;
    /** 录音按钮 */
    UILabel *_voiceDes;
    
    // 录音
    
    /** 是否正在录音 */
    BOOL _recording;
    /** 是否即将取消录音 */
    BOOL _willCancelRecord;
    /** 倒计时 */
    int _countDown;
    /** 是否最后10秒 */
    BOOL _lastTen;
    /** 倒数 */
    UILabel *_countDownLabel;
}

/** 当前光标位置 */
@property (assign, nonatomic) NSUInteger currentCursor;
/** 录音状态 */
@property (nullable, nonatomic, weak) UIImageView *recordStatus;
/** 录音者 */
@property (nullable, nonatomic, weak) WGVoiceManager *voiceManager;
/** 倒数者 */
@property (nullable, nonatomic, strong) NSTimer *timer;

@end

// 顶部工具条原始高度
static const CGFloat kTopToolBarOriHeight = 56;
// 容量 key
static NSString *const kContentSizeKey = @"contentSize";
// 键盘动画时长
static const NSTimeInterval kKeyboardAniDua = 0.25f;
// 倒计时最大秒数
static const NSInteger kCountDownMax = 60;
// 按钮描述
static NSString *const kNormalDes = @"按住 说话";
static NSString *const kFinishDes = @"松开 完成";
static NSString *const kCancelDes = @"松开 取消";

@implementation WGKeyboard

#pragma mark - <Getter & Setter>

- (void)setTextContent:(NSString *)textContent {
    _textContent = textContent;
    
    _TV.text = textContent;
}

- (void)setPlaceholder:(NSString *)placeholder {
    _placeholder = placeholder.copy;
    
    const NSInteger placeTag = 1;
    UILabel *label = [_TV viewWithTag:placeTag];
    if (label && [label isKindOfClass:UILabel.class]) {
        
        [label removeFromSuperview];
    }
    label = [UILabel new];
    [_TV addSubview:label];
    label.tag = placeTag;
    label.text = placeholder;
    label.numberOfLines = 0;
    label.font = _TV.font;
    label.textColor = UIColorMakeFromRGB(0xb2b2b2);
    [label sizeToFit];
    [_TV setValue:label forKey:@"_placeholderLabel"];
}

- (WGVoiceManager *)voiceManager {
    if (!_voiceManager) {
        
        self.voiceManager = [WGVoiceManager manager];
    }
    return _voiceManager;
}

- (NSUInteger)currentCursor {
    
    return _TV.selectedRange.location;
}

- (void)setCurrentCursor:(NSUInteger)currentCursor {
    
    NSRange range = _TV.selectedRange;
    range.location = currentCursor;
    _TV.selectedRange = range;
}

- (void)setDataSource:(NSObject<WGKeyboardDataSource> *)dataSource {
    _dataSource = dataSource;
    
    [_stikerView reloadData];
}

#pragma mark - <Lazy>

- (NSTimer *)timer {
    if (!_timer) {
        
        WEAK(self)
        NSTimer *timer = [NSTimer wg_weakTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
            STRONG(self)
            
            self->_countDown--;
            if (self->_countDown == 0) {
                
                timer.fireDate = [NSDate distantFuture];
                
                // 强制完成录音
                [self recordDidFinish];
            }
            else if (self->_countDown <= 10) {
                
                self->_lastTen = YES;
                
                if (!self->_willCancelRecord) {
                    
                    // 更新UI
                    [self updateLastTenUI];
                }
                else {
                    
                    self->_countDownLabel.hidden = YES;
                }
            }
        }];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        self.timer = timer;
    }
    return _timer;
}

- (UIImageView *)recordStatus {
    if (!_recordStatus) {
        
        UIImageView *recordStatus = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, DELEGATE_WINDOW.width, DELEGATE_WINDOW.height - self.class.defaultHeight)];
        [DELEGATE_WINDOW addSubview:recordStatus];
        self.recordStatus = recordStatus;
        recordStatus.contentMode = UIViewContentModeCenter;
        recordStatus.userInteractionEnabled = YES;
        
        UILabel *countDownLabel = [UILabel new];
        [recordStatus addSubview:countDownLabel];
        _countDownLabel = countDownLabel;
        countDownLabel.font = BOLD_SIZE(50);
        countDownLabel.textColor = [UIColor whiteColor];
        countDownLabel.hidden = YES;
        [countDownLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            
            make.centerX.mas_equalTo(0);
            make.centerY.mas_equalTo(-10);
        }];
    }
    return _recordStatus;
}

#pragma mark - <Getter && Setter>

+ (CGFloat)defaultHeight {
    
    return 49 + BOTTOM_SAFE_MARGIN;
}

- (BOOL)keyboardUp {
    
    return !((_currentInputStatus == InputStatusText && !_sysKeyboardUp) || _currentInputStatus == InputStatusVoice);
}

- (void)setAssoTB:(UITableView *)assoTB {
    _assoTB = assoTB;
    
    [self updateAssoTBUIWithScrollToBottom:NO];
}

#pragma mark - <System>

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    
    if (point.y > 0) {
        
        return YES;
    }
    [self keyboardGetDown];
    return [super pointInside:point withEvent:event];
}

- (void)dealloc {
    
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [_TV removeObserver:self forKeyPath:kContentSizeKey];
    [WGVoiceManager removeDelegate:self];
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    
    [_timer invalidate];
    _timer = nil;
    [self.recordStatus removeFromSuperview];
    self.recordStatus = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if ([keyPath isEqualToString:kContentSizeKey]) {
        
        CGFloat height = [change[@"new"] CGSizeValue].height;
        if (height > _TVContentH) {
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                [self->_TV setContentOffset:CGPointMake(0, height - self->_TV.height) animated:YES];
            });
        }
        _TVContentH = height;
        
        const CGFloat maxH = 100;
        
        if (height > maxH) {
            
            height = maxH;
        }
        [UIView animateWithDuration:0.25f animations:^{
            
            [self updateSelfUIWithTVHeight:height];
        }];
    }
}

#pragma mark - <Normal>

/**
 成为第一响应者
 */
- (void)becomeFirstResponder {
    
    [_TV becomeFirstResponder];
}

/**
 监听程序失去焦点
 */
- (void)willResignActive {
    
    [self recordDidCancel];
}

/**
 取消录音的处理
 */
- (void)recordDidCancel {
    
    if (!_recording) {
        
        return;
    }
    LOG(@"取消录音")
    
    _voiceDes.text = kNormalDes;
    _recording = NO;
    _willCancelRecord = NO;
    self.timer.fireDate = [NSDate distantFuture];
    _recordStatus.hidden = YES;
    
    [self.voiceManager recordCancel];
    
    if ([self.delegate respondsToSelector:@selector(audioRecordDidCancelWithKeyboard:)]) {
        [self.delegate audioRecordDidCancelWithKeyboard:self];
    }
}

/**
 更新最后10秒UI
 */
- (void)updateLastTenUI {
    
    self.recordStatus.image = [UIImage imageNamed:@"chat_voice_input_avoid"];
    _countDownLabel.hidden = NO;
    _countDownLabel.text = [NSString stringWithFormat:@"%d", _countDown];
}

/**
 结束录音
 */
- (void)recordDidFinish {
    
    if (!_recording) {
        
        return;
    }
    LOG(@"完成录音")
    
    _voiceDes.text = kNormalDes;
    _recording = NO;
    _willCancelRecord = NO;
    self.timer.fireDate = [NSDate distantFuture];
    
    // 录音提示
    _recordStatus.hidden = YES;
    
    [self.voiceManager recordStop];
}

/**
 即将取消录音
 */
- (void)recordWillCancel {
    
    if (_willCancelRecord || !_recording) {
        
        return;
    }
    LOG(@"即将取消录音")
    
    _voiceDes.text = kCancelDes;
    _willCancelRecord = YES;
    self.recordStatus.image = [UIImage imageNamed:@"chat_voice_input_cancel"];
    _countDownLabel.hidden = YES;
}

/**
 开始录音
 */
- (void)recordDidBegin {
    
    if (_recording || self.recordRootPath.length == 0) {
        
        return;
    }
    LOG(@"开始录音")
    
    _voiceDes.text = kFinishDes;
    _recording = YES;
    _countDown = kCountDownMax + 1;
    _lastTen = NO;
    self.timer.fireDate = [NSDate date];
    _willCancelRecord = NO;
    
    // 录音提示
    self.recordStatus.hidden = NO;
    self.recordStatus.image = [UIImage imageNamed:@"chat_voice_input_0"];
    _countDownLabel.hidden = YES;
    
    NSString *path = [[self.recordRootPath stringByAppendingPathComponent:[[UUIDHelper getRandomUUID] stringByAppendingString:[NSString stringWithFormat:@"%.0f", [NSDate date].timeIntervalSince1970 * 1000]]] stringByAppendingString:@".aac"];
    [self.voiceManager recordStartWithPath:path];
    
    if ([self.delegate respondsToSelector:@selector(audioRecordDidStartWithKeyboard:)]) {
        [self.delegate audioRecordDidStartWithKeyboard:self];
    }
}

/**
 继续录音
 */
- (void)recordGoon {
    
    if (!_willCancelRecord) {
        
        return;
    }
    LOG(@"继续录音")
    
    _voiceDes.text = kFinishDes;
    _willCancelRecord = NO;
    
    if (_lastTen) {
     
        [self updateLastTenUI];
    }
    else {
        
        self.recordStatus.image = [UIImage imageNamed:@"chat_voice_input_0"];
        _countDownLabel.hidden = YES;
    }
}

/**
 更新关联TBUI
 
 @param scrollToBottom 是否滚动到底部
 */
- (void)updateAssoTBUIWithScrollToBottom:(BOOL)scrollToBottom {
    
    if (!self.assoTB) {
        
        return;
    }
    self.assoTB.height = self.y - self.assoTB.y;
    
    if (scrollToBottom) {
        
        [self.assoTB setContentOffset:CGPointMake(0, self.assoTB.contentSize.height - self.assoTB.height) animated:NO];
    }
}

/**
 更新键盘UI(主要用于内容行数变化时更新)
 
 @param TVHeight 输入框高度
 */
- (void)updateSelfUIWithTVHeight:(CGFloat)TVHeight {
    
    _TVView.height = TVHeight;
    _TV.height = _TVView.height;
    [self updateSelfUIWithScrollToBottom:YES];
}

/**
 更新键盘UI
 @param scrollToBottom 是否滚动到底部
 */
- (void)updateSelfUIWithScrollToBottom:(BOOL)scrollToBottom {
    
    UIView *target = nil;
    
    if (_TVView.hidden == NO) {
        
        target = _TVView;
    }
    else if (_voiceInput.hidden == NO) {
        
        target = _voiceInput;
    }
    if (!target) {
        
        return;
    }
    _topToolBar.height = CGRectGetMaxY(target.frame) + _TVView.y;
    _stikerBtn.y = _topToolBar.height - (kTopToolBarOriHeight - _stikerBtn.height) / 2 - _stikerBtn.height;
    _voiceBtn.centerY = _stikerBtn.centerY;
    _moreBtn.centerY = _stikerBtn.centerY;
    _stikerView.y = CGRectGetMaxY(_topToolBar.frame);
    _moreView.y = _stikerView.y;
    self.height = CGRectGetMaxY(_topToolBar.frame) + BOTTOM_SAFE_MARGIN;
    self.y = [self getSelfY];
    [self updateAssoTBUIWithScrollToBottom:scrollToBottom];
}

/**
 初始化

 @param type 类型
 @return 实例
 */
- (instancetype)initWithType:(KeyboardType)type {
    
    if (self = [self initWithFrame:CGRectZero]) {
        
        // 默认属性
        _sysKeyboardY = SCREEN_HEIGHT;
        
        // 本体
        _keyboardType = type;
        _currentInputStatus = InputStatusText;
        self.width = SCREEN_WIDTH;
        self.backgroundColor = UIColor.whiteColor;
        
        UIView *topLine = [UIView new];
        [self addSubview:topLine];
        topLine.width = self.width;
        topLine.height = 0.5f;
        topLine.backgroundColor = UIColorMakeFromRGB(0xd8d8d8);
        
        // 工具栏
        UIView *topToolBar = [UIView new];
        [self addSubview:topToolBar];
        _topToolBar = topToolBar;
        topToolBar.y = CGRectGetMaxY(topLine.frame);
        topToolBar.width = self.width;
        
        const CGFloat wh = 32;
        CGFloat rightBegin = topToolBar.width;
        CGFloat leftBegin = 0;
        if (type == KeyboardTypeChat) {
            
            // 语音按钮
            UIButton *voiceBtn = [UIButton new];
            [topToolBar addSubview:voiceBtn];
            _voiceBtn = voiceBtn;
            voiceBtn.adjustsImageWhenHighlighted = NO;
            voiceBtn.size = CGSizeMake(wh, wh);
            [voiceBtn setBackgroundImage:[UIImage imageNamed:@"message_icon_voice"] forState:UIControlStateNormal];
            [voiceBtn setBackgroundImage:[UIImage imageNamed:@"message_icon_keybord"] forState:UIControlStateSelected];
            voiceBtn.x = 10;
            [voiceBtn addTarget:self action:@selector(didClickVoiceBtn) forControlEvents:UIControlEventTouchUpInside];
            
            leftBegin = CGRectGetMaxX(voiceBtn.frame);
            
            // 更多按钮
            UIButton *moreBtn = [UIButton new];
            [topToolBar addSubview:moreBtn];
            _moreBtn = moreBtn;
            moreBtn.adjustsImageWhenHighlighted = NO;
            moreBtn.size = CGSizeMake(wh, wh);
            [moreBtn setBackgroundImage:[UIImage imageNamed:@"message_icon_more"] forState:UIControlStateNormal];
            moreBtn.x = rightBegin - 10 - moreBtn.width;
            [moreBtn addTarget:self action:@selector(didClickMoreBtn) forControlEvents:UIControlEventTouchUpInside];
            
            rightBegin = moreBtn.x;
        }
        
        // 表情按钮
        UIButton *stikerBtn = [UIButton new];
        [topToolBar addSubview:stikerBtn];
        _stikerBtn = stikerBtn;
        stikerBtn.adjustsImageWhenHighlighted = NO;
        stikerBtn.size = CGSizeMake(wh, wh);
        [stikerBtn setBackgroundImage:[UIImage imageNamed:@"message_icon_emoji"] forState:UIControlStateNormal];
        [stikerBtn setBackgroundImage:[UIImage imageNamed:@"message_icon_keybord"] forState:UIControlStateSelected];
        stikerBtn.x = rightBegin - 10 - stikerBtn.width;
        [stikerBtn addTarget:self action:@selector(didClickStikerBtn) forControlEvents:UIControlEventTouchUpInside];
        
        // 输入框
        UIView *TVView = [UIView new];
        [topToolBar addSubview:TVView];
        _TVView = TVView;
        TVView.backgroundColor = UIColorMakeFromRGB(0xf2f4f7);
        TVView.x = leftBegin + 15;
        TVView.width = stikerBtn.x - 15 - TVView.x;
        TVView.layer.cornerRadius = 8;
        const CGFloat TVOriH = 40;
        TVView.y = (kTopToolBarOriHeight - TVOriH) / 2;
        
        WGTextView *TV = [WGTextView new];
        [TVView addSubview:TV];
        _TV = TV;
        TV.backgroundColor = UIColor.clearColor;
        TV.x = 15;
        TV.width = TVView.width - TV.x * 2;
        TV.font = FONT_SIZE(16);
        TV.tintColor = UIColor.blackColor;
        const CGFloat padding = (TVOriH - [@"" sizeWithAttributes:@{NSFontAttributeName : TV.font}].height) / 2;
        TV.textContainerInset = UIEdgeInsetsMake(padding, 0, padding, 0);
        TV.textContainer.lineFragmentPadding = 0;
        TV.returnKeyType = UIReturnKeySend;
        TV.delegate = self;
        TV.wgDelegate = self;
        
        // 语音输入框
        UIView *voiceInput = [UIView new];
        [topToolBar addSubview:voiceInput];
        _voiceInput = voiceInput;
        [voiceInput addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPressVoiceInput:)]];
        voiceInput.hidden = YES;
        voiceInput.frame = TVView.frame;
        voiceInput.height = TVOriH;
        voiceInput.layer.cornerRadius = TVView.layer.cornerRadius;
        voiceInput.layer.borderColor = UIColorMakeFromRGB(0xd8d8d8).CGColor;
        voiceInput.layer.borderWidth = 0.5f;
        UILabel *voiceDes = [UILabel new];
        [voiceInput addSubview:voiceDes];
        _voiceDes = voiceDes;
        voiceDes.text = kNormalDes;
        voiceDes.font = BOLD_SIZE(15);
        [voiceDes mas_makeConstraints:^(MASConstraintMaker *make) {
           
            make.center.mas_equalTo(0);
        }];
        
        // 表情
        KeyboardStikerView *stikerView = [KeyboardStikerView stikerView];
        [self addSubview:stikerView];
        _stikerView = stikerView;
        stikerView.alpha = 0;
        stikerView.dataSource = self;
        stikerView.delegate = self;
        stikerView.keyboard = self;
        stikerView.backgroundColor = UIColor.whiteColor;
        
        // 更多
        KeyboardMoreView *moreView = [KeyboardMoreView moreView];
        [self addSubview:moreView];
        _moreView = moreView;
        moreView.alpha = 0;
        moreView.delegate = self;
        moreView.backgroundColor = UIColor.whiteColor;
        
        [self updateSelfUIWithTVHeight:TVOriH];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyBoardWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
        [_TV addObserver:self forKeyPath:kContentSizeKey options:NSKeyValueObservingOptionNew context:nil];
        [WGVoiceManager addDelegate:self];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(willResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    }
    return self;
}

/**
 监听更多按钮点击
 */
- (void)didClickMoreBtn {
    
    if (_willInputStatus || _recording) {
        
        return;
    }
    // 重置
    _voiceBtn.selected = NO;
    _TVView.hidden = NO;
    _voiceInput.hidden = YES;
    _stikerBtn.selected = NO;
    
    _moreBtn.selected = !_moreBtn.isSelected;
    
    if (_moreBtn.isSelected) {
        
        _willInputStatus = InputStatusMore;
        
        if (_currentInputStatus == InputStatusText) {
            
            if (_sysKeyboardUp) {
                
                [DELEGATE_WINDOW endEditing:YES];
            }
            else {
                
                [self changeToStatus:_willInputStatus animaDur:kKeyboardAniDua];
            }
        }
        else {
            
            [self changeToStatus:_willInputStatus animaDur:kKeyboardAniDua];
        }
    }
    else {
        
        _willInputStatus = InputStatusText;
        [_TV becomeFirstResponder];
    }
}

/**
 监听表情按钮点击
 */
- (void)didClickStikerBtn {
    
    if (_willInputStatus || _recording) {
        
        return;
    }
    // 重置
    _voiceBtn.selected = NO;
    _TVView.hidden = NO;
    _voiceInput.hidden = YES;
    _moreBtn.selected = NO;
    
    _stikerBtn.selected = !_stikerBtn.isSelected;
    
    if (_stikerBtn.isSelected) {
        
        _willInputStatus = InputStatusStiker;
        
        if (_currentInputStatus == InputStatusText) {
            
            if (_sysKeyboardUp) {
                
                [DELEGATE_WINDOW endEditing:YES];
            }
            else {
                
                [self changeToStatus:_willInputStatus animaDur:kKeyboardAniDua];
            }
        }
        else {
            
            [self changeToStatus:_willInputStatus animaDur:kKeyboardAniDua];
        }
    }
    else {
        
        _willInputStatus = InputStatusText;
        [_TV becomeFirstResponder];
    }
}

/**
 监听语音按钮点击
 */
- (void)didClickVoiceBtn {
    
    if (_willInputStatus || _recording) {
        
        return;
    }
    // 重置
    _stikerBtn.selected = NO;
    _moreBtn.selected = NO;
    
    _voiceBtn.selected = !_voiceBtn.isSelected;
    
    if (_voiceBtn.isSelected) {
        
        _TVView.hidden = YES;
        _voiceInput.hidden = NO;
        
        _willInputStatus = InputStatusVoice;
        
        if (_currentInputStatus == InputStatusText) {
            
            if (_sysKeyboardUp) {
                
                [DELEGATE_WINDOW endEditing:YES];
            }
            else {
                
                [self changeToStatus:_willInputStatus animaDur:0];
            }
        }
        else {
            
            [self changeToStatus:_willInputStatus animaDur:kKeyboardAniDua];
        }
    }
    else {
        
        _TVView.hidden = NO;
        _voiceInput.hidden = YES;
        
        _willInputStatus = InputStatusText;
        [_TV becomeFirstResponder];
    }
}

/**
 监听语音输入长按
 
 @param longPress 长按手势
 */
- (void)didLongPressVoiceInput:(UILongPressGestureRecognizer *)longPress {
    
    BOOL inside = [longPress.view pointInside:[longPress locationInView:longPress.view] withEvent:nil];
    
    if (longPress.state == UIGestureRecognizerStateBegan) {
        
        [self recordDidBegin];
    }
    else if (longPress.state == UIGestureRecognizerStateChanged) {
        
        if (inside) {
            
            [self recordGoon];
        }
        else {
            
            [self recordWillCancel];
        }
    }
    else if (longPress.state == UIGestureRecognizerStateEnded) {
     
        if (inside) {
            
            [self recordDidFinish];
        }
        else {
            
            [self recordDidCancel];
        }
    }
}

/**
 初始化
 
 @param type 类型
 @return 实例
 */
+ (nonnull instancetype)keyboardWithType:(KeyboardType)type {
    
    return [[self alloc] initWithType:type];
}

/**
 获取自身Y值

 @return 自身Y值
 */
- (CGFloat)getSelfY {
    
    if (_willInputStatus == InputStatusText) {
        
        return _sysKeyboardUp ? _sysKeyboardY - self.height + BOTTOM_SAFE_MARGIN : _sysKeyboardY - self.height;
    }
    if (_willInputStatus == InputStatusVoice) {
        
        return _sysKeyboardY - self.height;
    }
    if (_willInputStatus == InputStatusStiker) {
        
        return SCREEN_HEIGHT - KeyboardStikerViewHeight - self.height + BOTTOM_SAFE_MARGIN;
    }
    if (_willInputStatus == InputStatusMore) {
        
        return SCREEN_HEIGHT - KeyboardMoreViewHeight - self.height + BOTTOM_SAFE_MARGIN;
    }
    return _sysKeyboardUp ? _sysKeyboardY - self.height + BOTTOM_SAFE_MARGIN : _sysKeyboardY - self.height;
}

/**
 转换状态

 @param status 目标状态
 @param animaDur 转换动画时长
 */
- (void)changeToStatus:(InputStatus)status animaDur:(NSTimeInterval)animaDur {
    
    InputStatus currentStatus = _currentInputStatus;
    BOOL up = _sysKeyboardUp;
    
    if (status == InputStatusText) {
        
        CGFloat endY = [self getSelfY];
        
        [UIView animateWithDuration:animaDur animations:^{
            
            if (currentStatus == InputStatusText) {
             
                self.y = endY;
                [self updateAssoTBUIWithScrollToBottom:up];
            }
            else if (currentStatus == InputStatusVoice) {
                
                [self updateSelfUIWithScrollToBottom:YES];
            }
            else if (currentStatus == InputStatusStiker) {
             
                self->_stikerView.alpha = 0;
                self->_stikerBtn.selected = NO;
                [self updateSelfUIWithScrollToBottom:YES];
            }
            else if (currentStatus == InputStatusMore) {
                
                self->_moreView.alpha = 0;
                [self updateSelfUIWithScrollToBottom:YES];
            }
        } completion:^(BOOL finished) {
            
            self->_willInputStatus = InputStatusUnknow;
            self->_currentInputStatus = InputStatusText;
        }];
    }
    
    else if (status == InputStatusVoice) {
        
        [UIView animateWithDuration:animaDur animations:^{
            
            if (currentStatus == InputStatusText) {
                
                [self updateSelfUIWithScrollToBottom:up];
            }
            else if (currentStatus == InputStatusStiker) {
                
                self->_stikerView.alpha = 0;
                [self updateSelfUIWithScrollToBottom:NO];
            }
            else if (currentStatus == InputStatusMore) {
                
                self->_moreView.alpha = 0;
                [self updateSelfUIWithScrollToBottom:NO];
            }
        } completion:^(BOOL finished) {
            
            self->_willInputStatus = InputStatusUnknow;
            self->_currentInputStatus = InputStatusVoice;
        }];
    }
    
    else if (status == InputStatusStiker) {
        
        [UIView animateWithDuration:animaDur animations:^{
            
            self->_stikerView.alpha = 1;
            [self updateSelfUIWithScrollToBottom:YES];
            
            if (currentStatus == InputStatusMore) {
                
                self->_moreView.alpha = 0;
            }
        } completion:^(BOOL finished) {
            
            self->_willInputStatus = InputStatusUnknow;
            self->_currentInputStatus = InputStatusStiker;
        }];
    }
    
    else if (status == InputStatusMore) {
        
        [UIView animateWithDuration:animaDur animations:^{
            
            self->_moreView.alpha = 1;
            [self updateSelfUIWithScrollToBottom:YES];
            
            if (currentStatus == InputStatusStiker) {
                
                self->_stikerView.alpha = 0;
            }
        } completion:^(BOOL finished) {
            
            self->_willInputStatus = InputStatusUnknow;
            self->_currentInputStatus = InputStatusMore;
        }];
    }
}

/**
 监听键盘变化
 
 @param noti 通知
 */
- (void)keyBoardWillChange:(NSNotification *)noti {
    
    NSDictionary *userInfo = noti.userInfo;
    CGFloat endY = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].origin.y;
    NSTimeInterval time = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    const CGFloat offset = 5;
    _sysKeyboardUp = !((endY + offset) > SCREEN_HEIGHT && (endY - offset) < SCREEN_HEIGHT);
    _sysKeyboardY = endY;
    
    if (_willInputStatus) {
        
        [self changeToStatus:_willInputStatus animaDur:time];
    }
    else {
        
        _willInputStatus = InputStatusText;
        [self changeToStatus:_willInputStatus animaDur:time];
    }
}

/**
 收起键盘
 */
- (void)keyboardGetDown {
    
    if (_willInputStatus || !self.keyboardUp) {
        
        return;
    }
    // 重置
    _voiceBtn.selected = NO;
    _stikerBtn.selected = NO;
    _moreBtn.selected = NO;
    
    _willInputStatus = InputStatusText;
    
    if (_sysKeyboardUp) {
        
        [DELEGATE_WINDOW endEditing:YES];
    }
    else {
        
        [self changeToStatus:_willInputStatus animaDur:kKeyboardAniDua];
    }
}

/**
 刷新表情数据
 */
- (void)reloadStikerData {
    
    [_stikerView reloadData];
}

#pragma mark - <UITextViewDelegate>

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if ([text isEqualToString:@"\n"]) {
        
        if ([self.delegate respondsToSelector:@selector(keyboard:didClickSendWithContent:)]) {
            [self.delegate keyboard:self didClickSendWithContent:textView.text];
        }
        textView.text = nil;
        
        return NO;
    }
    return YES;
}

#pragma mark - <WGVoiceManagerDelegate>

/**
 * 代理方法1 监听录音音量改变
 * 参数 manager 本单例
 * 参数 volumn 音量值 (0 ~ 120 可将有效值看为 80 ~ 110)
 */
- (void)manager:(nonnull __kindof WGVoiceManager *)manager gotVolume:(float)volume {
    
    if (_willCancelRecord) return;
    
    if (_lastTen) {
        
        [self updateLastTenUI];
        
        return;
    }
    else {
        
        _countDownLabel.hidden = YES;
    }
    
    const float min = 80;
    const float max = 110;
    const int levels = 8;
    
    const float level = (max - min) / levels;
    
    for (int i = 0; i < levels; i++) {
        
        if (volume <= min + level * i) {
            
            self.recordStatus.image = [UIImage imageNamed:[NSString stringWithFormat:@"chat_voice_input_%d", i]];
            
            return;
        }
    }
    self.recordStatus.image = [UIImage imageNamed:[NSString stringWithFormat:@"chat_voice_input_8"]];
}

/**
 * 代理方法2 监听录音完成
 * 参数 manager 本单例
 * 参数 duration 时长
 * 返回 path 音频文件路径
 */
- (void)manager:(nonnull __kindof WGVoiceManager *)manager didRecordWithPath:(nonnull NSString *)path duration:(NSTimeInterval)duration {
    
    if ([self.delegate respondsToSelector:@selector(keyboard:audioRecordDidFinishWithPath:duration:)]) {
        [self.delegate keyboard:self audioRecordDidFinishWithPath:path duration:duration];
    }
}

#pragma mark - <KeyboardStikerViewDataSource>

/**
 获取表情包
 
 @param stikerView 自身
 @return 表情包
 */
- (nullable NSArray<StikerPackageModel *> *)stikerPackagesInStikerView:(nonnull __kindof KeyboardStikerView *)stikerView {
    
    if ([self.dataSource respondsToSelector:@selector(stikerPackagesInKeyboard:)]) {
        return [self.dataSource stikerPackagesInKeyboard:self];
    }
    return nil;
}

#pragma mark - <KeyboardStikerViewDelegate>

/**
 选择表情回调
 
 @param stikerView 自身
 @param stiker 所选表情
 */
- (void)stikerView:(nonnull __kindof KeyboardStikerView *)stikerView didSelectStiker:(nonnull StikerInfoModel *)stiker {
    
    if (stiker.stikerType == StikerTypeEmoji) {
        
        NSUInteger currentCursor = self.currentCursor;
        NSMutableString *strM = [NSMutableString stringWithString:_TV.text];
        [strM insertString:stiker.stikerTitle atIndex:currentCursor];
        _TV.text = strM;
        self.currentCursor = currentCursor + stiker.stikerTitle.length;
    }
    else if (stiker.stikerType == StikerTypeAdd) {
        
        if ([self.delegate respondsToSelector:@selector(didSelectAddStikerWithKeyboard:)]) {
            [self.delegate didSelectAddStikerWithKeyboard:self];
        }
    }
    else if (stiker.stikerType == StikerTypeCustom) {
        
        if ([self.delegate respondsToSelector:@selector(keyboard:didSelectCustomStiker:)]) {
            [self.delegate keyboard:self didSelectCustomStiker:stiker];
        }
    }
}

/**
 点击发送时回调
 
 @param stikerView 自身
 */
- (void)didTapSendWithStikerView:(nonnull __kindof KeyboardStikerView *)stikerView {
    
    [self textView:_TV shouldChangeTextInRange:NSMakeRange(self.currentCursor, 0) replacementText:@"\n"];
}

#pragma mark - <KeyboardMoreViewDelegate>

/**
 选择元素回调
 
 @param moreView 自身
 @param type 元素类型
 */
- (void)moreView:(nonnull __kindof KeyboardMoreView *)moreView didSelectItemWithType:(MoreItemType)type {
    
    if ([self.delegate respondsToSelector:@selector(keyboard:didSelectMoreItemWithType:)]) {
        [self.delegate keyboard:self didSelectMoreItemWithType:type];
    }
}

#pragma mark - <WGTextViewDelegate>

/**
 监听删除键点击
 
 @param textView 自身
 */
- (void)didDeleteBackwardWithTextView:(nonnull __kindof WGTextView *)textView {
    
    if (textView.text.length == 0 && [self.delegate respondsToSelector:@selector(didDeleteBackwardWhenAvoidWithKeyBoard:)]) {
        [self.delegate didDeleteBackwardWhenAvoidWithKeyBoard:self];
    }
}

@end
