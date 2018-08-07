//
//  MUIAudioNewPlayView.m
//  MUIAudioView
//
//  Created by admin on 2017/7/5.
//  Copyright © 2017年 ND. All rights reserved.
//

#import "MUIAudioNewPlayView.h"
#import "MUIAudioViewHelper.h"

#import <libextobjc/EXTScope.h>
#import <Masonry/Masonry.h>
#import <APFUIKit/APFUIKit.h>
#import <MUPFoundation/MUPFoundation.h>

#import "MUIAudioLoadProgressView.h"
#import "MUIAudioPlayManager.h"
#import "MUIAudioDefine.h"

typedef NS_ENUM(NSInteger, MUIAudioPlayState) {
    MUIAudioPlayState_Normal = 0, //正常态
    MUIAudioPlayState_Play,       //播放态
    MUIAudioPlayState_Pause,      //暂停
    MUIAudioPlayState_Download,   //下载
    MUIAudioPlayState_Faile       //下载失败
};

@interface MUIAudioNewPlayView ()
<MUIAudioPlayManagerDelegate>


@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) MUIAudioLoadProgressView *loadProgressView;

@property (nonatomic, assign) NSTimeInterval maxDuration;
@property (nonatomic, copy)   NSString *maxDurationString;
@property (nonatomic, assign) BOOL isLoadFail;

@property (nonatomic, strong) MUIAudioPlayManager *playService;

@property (nonatomic, assign) MUIAudioPlayState playState;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation MUIAudioNewPlayView

- (void)dealloc {
    
    self.playService = nil;
    self.dateFormatter = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)removeFromSuperview {
    
    [super removeFromSuperview];
    if (self.playState == MUIAudioPlayState_Download) {
        [self stopDownloadAudio];
    } else if (self.playState == MUIAudioPlayState_Play) {
        [self stopPlay];
    }
    
}

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundColor = [UIColor clearColor];
        [self initSubviews];
        self.playService = [MUIAudioPlayManager new];
        self.playService.delegate = self;
        
        self.playState = MUIAudioPlayState_Normal;
        [self.playButton setImage:[MUIAudioViewHelper imageNamed:@"social_view_video_start_normal"] forState:UIControlStateNormal];
        [self.playButton setImage:[MUIAudioViewHelper imageNamed:@"social_view_video_start_pressed"] forState:UIControlStateHighlighted];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleNotification_stopPlayAudio:)
                                                     name:kMUIAudioNotificationStopPlayAudio
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleNotification_stopDownloadAudio:)
                                                     name:kMUIAudioNotificationStopDownloadAudio
                                                   object:nil];
    }
    return self;
}

- (void)initSubviews {
    
    self.playButton = [UIButton new];
    [self.playButton setBackgroundColor:[MUIAudioViewHelper colorWithKey:@"mui_audio_play_bg_color"]];
    [self.playButton addTarget:self action:@selector(onClickPlayButton) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.playButton];
    [self.playButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self);
        make.centerY.equalTo(self);
        make.size.mas_equalTo(CGSizeMake(64, 64));
    }];
    
    self.durationLabel = [[UILabel alloc] init];
    self.durationLabel.textColor = [MUIAudioViewHelper colorWithKey:@"mui_audio_play_time_color"];
    self.durationLabel.font = [MUIAudioViewHelper fontWithKey:@"character_6"];
    [self addSubview:self.durationLabel];
    [self.durationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self);
        make.centerY.equalTo(self);
    }];
    
    self.waveView = [MUIAudioWaveView new];
    self.waveView.waveDirectionType = MUIAudioWaveDerectionType_LeftToRight;
    [self addSubview:self.waveView];
    [self.waveView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.playButton.mas_trailing).offset(12);
        make.centerY.equalTo(self);
        make.trailing.equalTo(self.durationLabel.mas_leading).offset(-18);
        make.height.mas_equalTo(64);
    }];
}

- (MUIAudioLoadProgressView *)loadProgressView {
    
    if (!_loadProgressView) {
        _loadProgressView = [[MUIAudioLoadProgressView alloc] init];
        [self.playButton addSubview:_loadProgressView];
        [_loadProgressView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.playButton);
        }];
    }
    return _loadProgressView;
}

- (UILabel *)downLoadFailTipLabel {
    
    if (!_downLoadFailTipLabel) {
        _downLoadFailTipLabel = [UILabel new];
        _downLoadFailTipLabel.backgroundColor = [UIColor clearColor];
        _downLoadFailTipLabel.textColor = [MUIAudioViewHelper colorWithKey:@"mui_audio_play_load_faile_tip_color"]; //e45249
        _downLoadFailTipLabel.font = [MUIAudioViewHelper fontWithKey:@"character_5"];
        _downLoadFailTipLabel.text = NSLocalizedString(@"MUIAudioNewPlayView_DownloadFail_Tip");
        [self addSubview:_downLoadFailTipLabel];
        [_downLoadFailTipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.playButton.mas_trailing).offset(23);
            make.centerY.equalTo(self);
            make.trailing.lessThanOrEqualTo(self);
        }];
    }
    return _downLoadFailTipLabel;
}

#pragma mark - set
- (void)setAudio:(MUIAudio *)audio {
    
    if ([audio isEqual:_audio]) {
        return;
    }
    _audio = audio;
    self.playService.audio = audio;
    self.maxDuration = self.audio.duration / 1000;
    self.maxDurationString = [self getTimeStringWithSec:self.maxDuration];
    self.durationLabel.text = [NSString stringWithFormat:@"00:00 / %@",self.maxDurationString];
}

- (void)setPlayState:(MUIAudioPlayState)playState {
    
    if (_playState == playState) {
        return;
    }
    _playState = playState;
    switch (playState) {
        case MUIAudioPlayState_Play:
        {
            self.waveView.hidden = NO;
            self.durationLabel.hidden = NO;
            if (_downLoadFailTipLabel) {
                _downLoadFailTipLabel.hidden = YES;
            }
            [self.playButton setImage:[MUIAudioViewHelper imageNamed:@"social_view_video_stop_normal"] forState:UIControlStateNormal];
            [self.playButton setImage:[MUIAudioViewHelper imageNamed:@"social_view_video_stop_pressed"] forState:UIControlStateHighlighted];
        }
            break;
        case MUIAudioPlayState_Pause:
        case MUIAudioPlayState_Normal:
        {
            self.waveView.hidden = NO;
            self.durationLabel.hidden = NO;
            if (_downLoadFailTipLabel) {
                _downLoadFailTipLabel.hidden = YES;
            }
            [self.playButton setImage:[MUIAudioViewHelper imageNamed:@"social_view_video_start_normal"] forState:UIControlStateNormal];
            [self.playButton setImage:[MUIAudioViewHelper imageNamed:@"social_view_video_start_pressed"] forState:UIControlStateHighlighted];
        }
            break;
        case MUIAudioPlayState_Faile:
        {
            self.waveView.hidden = YES;
            self.durationLabel.hidden = YES;
            self.downLoadFailTipLabel.hidden = NO;
            [self.playButton setImage:[MUIAudioViewHelper imageNamed:@"social_weibo_icon_loading_fail"] forState:UIControlStateNormal];
            [self.playButton setImage:nil forState:UIControlStateHighlighted];
        }
            break;
        case MUIAudioPlayState_Download:
        {
            self.waveView.hidden = NO;
            self.durationLabel.hidden = NO;
            if (_downLoadFailTipLabel) {
                _downLoadFailTipLabel.hidden = YES;
            }
            [self.playButton setImage:nil forState:UIControlStateNormal];
        }
            break;
    }
}


#pragma mark- 播放

- (void)onClickPlayButton {
    
    switch (self.playState) {
        case MUIAudioPlayState_Play:
        {
            [self pausePlay];
        }
            break;
        case MUIAudioPlayState_Pause:
        {
            [self restartPlay];
        }
            break;
        case MUIAudioPlayState_Normal:
        {
            [self startPlay];
        }
            break;
        case MUIAudioPlayState_Faile:
        {
            [self downloadAudio];
        }
            break;
        case MUIAudioPlayState_Download:
        {
            //停止下载状态
            [self stopDownloadAudio];
        }
            break;
    }
}

- (void)startPlay {
    
    if([[NSFileManager defaultManager] fileExistsAtPath:self.audio.filePath]) {
        
        self.durationLabel.text = [NSString stringWithFormat:@"00:00 / %@",self.maxDurationString];
        [self.playService beginPlay];
        
        self.playState = MUIAudioPlayState_Play;
        [self.waveView start];
        [self startTimer];
        
        if ([self.playDelegate respondsToSelector:@selector(muiAudioNewPlayViewStartPlay:)]) {
            [self.playDelegate muiAudioNewPlayViewStartPlay:self];
        }
    } else {
        [self downloadAudio];
    }
}

- (void)restartPlay {
    self.playState = MUIAudioPlayState_Play;
    if ([self.playDelegate respondsToSelector:@selector(muiAudioNewPlayViewReStartPlay:)]) {
        [self.playDelegate muiAudioNewPlayViewReStartPlay:self];
    }
    [self.playService rePlay];
    [self startTimer];
    [self.waveView start];
}

/**
 *  暂停播放
 */
- (void)pausePlay {
    
    [self stopTimer];
    self.playState = MUIAudioPlayState_Pause;
    if ([self.playDelegate respondsToSelector:@selector(muiAudioNewPlayViewPausePlay:)]) {
        [self.playDelegate muiAudioNewPlayViewPausePlay:self];
    }
    [self.waveView pause];
    [self.playService pause];
}

/**
 *  停止播放
 */
- (void)stopPlay {
    
    [self stopTimer];
    self.playState = MUIAudioPlayState_Normal;
    if ([self.playDelegate respondsToSelector:@selector(muiAudioNewPlayViewStopPlay:)]) {
        [self.playDelegate muiAudioNewPlayViewStopPlay:self];
    }
    
    [self.playService stop];
    [self.waveView pause];
    self.durationLabel.text = [NSString stringWithFormat:@"00:00 / %@",self.maxDurationString];
}

#pragma mark- 计时器

- (void)stopTimer {
    
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)startTimer {
    
    if (!self.timer) {
        self.timer = [NSTimer timerWithTimeInterval:0.05
                                             target:self
                                           selector:@selector(updateDuration)
                                           userInfo:nil
                                            repeats:YES];
        MUPLogDebug(@"---MUIAudioNewPlayView - cacheCurrentTime 开始");
        [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    }
}

- (void)updateDuration {
    
    self.durationLabel.text = [self.playService getDurationString];
}

#pragma mark- 下载音频
- (void)downloadAudio {
    
    if (![self.playService canAudioDownLoad]) {
        return;
    }
    
    self.playState = MUIAudioPlayState_Download;
    [self.playButton setImage:nil forState:UIControlStateNormal];
    [self.playButton setImage:nil forState:UIControlStateHighlighted];
    [self startLoadView];

    @weakify(self);
    [self.playService downloadAudioProgress:^(CGFloat progress) {
        self.loadProgressView.progress = progress;
    } callBackBlock:^(BOOL bSucceed, NSError *error) {
        @strongify(self)
        [self stopLoadView];
        if (bSucceed) {
            self.isLoadFail = NO;
            [self startPlay];
        } else {
            if (error) {
                self.isLoadFail = YES;
                self.playState = MUIAudioPlayState_Faile;
                if ([self.playDelegate respondsToSelector:@selector(muiAudioNewPlayViewDownLoadAudioFailure:)]) {
                    [self.playDelegate muiAudioNewPlayViewDownLoadAudioFailure:self];
                }
            }
        }
    }];
}

- (void)startLoadView {
    
    self.loadProgressView.progress = 0;
    [self.loadProgressView startAnimation];
    self.loadProgressView.hidden = NO;
}

- (void)stopLoadView {
    
    self.loadProgressView.hidden = YES;
    [self.loadProgressView stopAnimation];
    
    [self.playService stopDownLoad];
}

- (void)stopDownloadAudio {
    
    if (![self.playService canAudioDownLoad]) {
        
        [self.playService stopDownLoad];
        [self stopLoadView];
        self.playState = MUIAudioPlayState_Normal;
        
        if ([self.playDelegate respondsToSelector:@selector(muiAudioNewPlayViewStopDownLoadAudio:)]) {
            [self.playDelegate muiAudioNewPlayViewStopDownLoadAudio:self];
        }
    }
    
    if (self.isLoadFail) {
        self.isLoadFail = NO;
    }
}

#pragma mark- notification

- (void)handleNotification_stopPlayAudio:(NSNotification *)notification {
    
    if (self.playState == MUIAudioPlayState_Play) {
        MUIAudio *audio = notification.object;
        if (audio != self.audio) {
            
            [self stopPlay];
        }
    }
}
    
- (void)handleNotification_stopDownloadAudio:(NSNotification *)notification {
    
    if (self.playState == MUIAudioPlayState_Download) {
        [self stopDownloadAudio];
    }
}

#pragma mark - private
- (NSString *)getTimeStringWithSec:(NSTimeInterval)sec {
    
    // 格式化时间
    if (!self.dateFormatter) {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [self.dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [self.dateFormatter setDateFormat:@"mm:ss"];
    }
    
    // 毫秒值转化为秒
    NSDate* date = [NSDate dateWithTimeIntervalSince1970:sec];
    NSString* dateString = [self.dateFormatter stringFromDate:date];
    return dateString;
}

#pragma mark - public
- (void)showDefaultWaveView {
    
    [self.waveView ceateDefaultWave];
}

#pragma mark - MUIAudioPlayManagerDelegate
- (void)muiAudioPlayManagerDidBeginInterruption:(MUIAudioPlayManager *)playManager {
    
    [self pausePlay];
}

- (void)muiAudioPlayManagerFinishPlaying:(MUIAudioPlayManager *)playManager {
    
    [self stopPlay];
}
@end

