//
//  MUIEditAudioNewRecordView.m
//  Pods
//
//  Created by 陈䶮 on 2017/7/11.
//
//

#define kTOP_TIP_VIEW_HEIGHT   44        //顶部提示语的宽度

#define kMUIEditRerecordButtonWidth            65

#define kMUIEditTimerInterval                  0.05

#define kMBSMILEY_VIEW_HEIGHT  220

#import "MUIEditAudioNewRecordView.h"

#import "MUIEditAudioRecordView.h"
#import "MUIAudioWaveView.h"
#import "MUIEditAudioPlayProgressView.h"
#import "MUIAudioViewHelper.h"

#import <MUPFoundation/MUPFoundation.h>
#import <Masonry/Masonry.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <MUIKit/MUIKit.h>
#import <MBProgressHud+MUIExtend/MBProgressHud_MUIExtend.h>
#import <libextobjc/EXTScope.h>
#import <APFUIKit/APFUIKit.h>
#import <APFUIKit/MUPAudioUtility.h>

typedef NS_ENUM(NSUInteger, MUIEditAudioStatus) {
    MUIEditAudioStatus_Record,
    MUIEditAudioStatus_Play
};

typedef NS_ENUM(NSUInteger, MUIEditRecordStatus) {
    MUIEditRecordStatus_Recording,
    MUIEditRecordStatus_Pause,
    MUIEditRecordStatus_EndTime,
    MUIEditRecordStatus_Readey,
    MUIEditRecordStatus_playing
};

@interface MUIEditAudioNewRecordView () <MUPAudioRecorderDelegate,MUPAudioPlayerDelegate>
{
    
}

@property (nonatomic, assign) MUIEditAudioRecordType type;

@property (nonatomic, strong) UIView             *contentView;
@property (nonatomic, strong) UIView             *topView;
@property (nonatomic, strong) UIView             *modalView;
@property (nonatomic, strong) UIView             *recordView;
@property (nonatomic, strong) UIView             *playView;
@property (nonatomic, strong) UIButton           *playButton;
@property (nonatomic, strong) UIButton           *rerecordButton;
@property (nonatomic, strong) UIButton           *confirmButton;

@property (nonatomic, strong) UIButton           *resumeButton;
@property (nonatomic, strong) MUIEditAudioPlayProgressView *playProgressView;
@property (nonatomic, strong) NSTimer            *timer;
@property (nonatomic, assign) NSUInteger         timeCount;
@property (nonatomic, strong) UILabel            *timeLabel;
@property (nonatomic, weak)   MUPAudioRecorder   *recordManager;
@property (nonatomic, weak)   MUPAudioPlayer     *playManager;
@property (nonatomic, strong) UILabel            *tipLabel;
@property (nonatomic, assign) MUIEditAudioStatus status;
@property (nonatomic, strong) MUIAudioWaveView   *waveView;
@property (nonatomic, strong) UIButton           *topTipButton;
@property (nonatomic, assign) MUIEditRecordStatus recordStatus;
@property (nonatomic, assign) MUIEditRecordStatus recordStatusTmp;
@property (nonatomic, assign) BOOL               isGetFinishAudio;

@property (nonatomic, strong) NSString           *tmpAmrPath;
@property (nonatomic, strong) NSString           *tmpWavPath;

@end

@implementation MUIEditAudioNewRecordView


#pragma mark -
#pragma mark - init
- (instancetype)init {
    
    self = [super init];
    
    if (self) {
        _minimumDuration = 1;
        _maximumDuration = 120;
        _isGetFinishAudio=NO;
        self.recordManager = [MUPAudioRecorder sharedInstance];
        self.recordManager.maximumDuration = _maximumDuration;
        self.recordManager.minimumDuration = _minimumDuration;
        self.recordManager.delegate = self;
        
        self.playManager = [MUPAudioPlayer sharedInstance];
        self.playManager.delegate = self;
        
        [self initSubView];
    }
    return self;
}

- (void)initSubView {
    
    self.contentView = [[UIView alloc] init];
    self.contentView.backgroundColor = [MUIAudioViewHelper colorWithKey:@"mui_audio_edit_bg_color"];
    [self addSubview:self.contentView];
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self);
        make.size.mas_equalTo(self);
    }];
    
    self.timeLabel = [[UILabel alloc] init];
    self.timeLabel.font = [MUIAudioViewHelper fontWithKey:@"character_3"];
    self.timeLabel.textAlignment = NSTextAlignmentCenter;
    self.timeLabel.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.timeLabel];
    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.top.equalTo(self.contentView).offset(15);
    }];
    
    self.tipLabel = [[UILabel alloc] init];
    self.tipLabel.font = [MUIAudioViewHelper fontWithKey:@"character_13"];
    self.tipLabel.textColor = [MUIAudioViewHelper colorWithKey:@"mui_audio_edit_recode_tip_color"];
    self.tipLabel.textAlignment = NSTextAlignmentCenter;
    self.tipLabel.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.tipLabel];
    
    _topView = [[UIView alloc] init];
    _topView.backgroundColor = [MUIAudioViewHelper colorWithKey:@"mui_audio_edit_bg_color"];
    [self addSubview:_topView];
    [_topView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self);
        make.bottom.equalTo(self.contentView.mas_top);
        make.height.mas_equalTo(kTOP_TIP_VIEW_HEIGHT);
    }];
    
    _topTipButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _topTipButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    _topTipButton.layer.cornerRadius = 5;
    [_topTipButton setTitleColor:[MUIAudioViewHelper colorWithKey:@"color_7"] forState:UIControlStateNormal];
    _topTipButton.titleLabel.font = [MUIAudioViewHelper fontWithKey:@"character_5"];
    
    _topTipButton.contentEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 20);
    [self.topView addSubview:_topTipButton];
    [_topTipButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.topView);
        make.top.equalTo(self.topView).offset(12);
        make.height.mas_equalTo(33);
    }];
    
    NSString *colorHex = [UIColor mui_hexValuesFromUIColor:[UIColor blackColor]];
    self.topTipButton.backgroundColor = [UIColor mui_colorWithHexString:colorHex alpha:0.6];
    self.topTipButton.hidden = YES;
    
    CGRect frame = CGRectMake(0, 0, kMUIScreen_Width, kMUIScreen_Height - kMBSMILEY_VIEW_HEIGHT - kTOP_TIP_VIEW_HEIGHT);
    _modalView = [[UIView alloc] initWithFrame:frame];
    _modalView.backgroundColor = [UIColor blackColor];
    _modalView.alpha = 0.6;
    
    [[UIApplication sharedApplication].keyWindow addSubview:_modalView];
    
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onCancel)];
    [_modalView addGestureRecognizer:gesture];

    [self setType:MUIEditAudioRecordType_New];
    
}


- (void)dealloc {
    
    if (_modalView) {
        [_modalView removeFromSuperview];
    }
    if (_topView) {
        [_topView removeFromSuperview];
    }
}

#pragma mark -
#pragma mark - set
- (void)setMinimumDuration:(NSTimeInterval)minimumDuration {
    
    if (_minimumDuration == minimumDuration) {
        return;
    }
    _minimumDuration=minimumDuration;
    self.recordManager.minimumDuration = _minimumDuration;
}

- (void)setMaximumDuration:(NSTimeInterval)maximumDuration {
    
    if (_maximumDuration == maximumDuration) {
        return;
    }
   
       _maximumDuration=maximumDuration;
    self.recordManager.maximumDuration = _maximumDuration;
}

- (void)setType:(MUIEditAudioRecordType)type {
    
    _type = type;
    
    if (type == MUIEditAudioRecordType_New) {
        
        self.audio = [[MUIAudio alloc] init];
        
        self.timeLabel.text = @"0";
        self.status = MUIEditAudioStatus_Record;
        
        [self.tipLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.contentView);
            make.top.equalTo(self.recordView.mas_bottom).offset(9);
        }];
    } else {
        
        self.timeCount = self.audio.duration;
        self.status = MUIEditAudioStatus_Play;
        
        [self.tipLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.contentView);
            make.top.equalTo(self.playView.mas_bottom).offset(9);
        }];
    }
}

#pragma mark -
#pragma mark - lazy load


- (UIView *)recordView {
    
    if (!_recordView) {
        _recordView = [[UIView alloc] init];
        _recordView.hidden = YES;
        [self.contentView addSubview:_recordView];
        [_recordView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.contentView);
            make.top.equalTo(self.timeLabel.mas_bottom).offset(9);
        }];
        
        self.recordImageView = [[UIImageView alloc] init];
        self.recordImageView.userInteractionEnabled = YES;
        self.recordImageView.image = [MUIAudioViewHelper imageNamed:@"social_publish_button_voice_normal.png"];
        [_recordView addSubview:self.recordImageView];
        [self.recordImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(_recordView);
            make.top.bottom.equalTo(_recordView);
        }];
        
        _recordStatus=MUIEditRecordStatus_Readey;
    }
    return _recordView;
}

- (UIView *)playView {
    
    if (!_playView) {
        _playView = [[UIView alloc] init];
        _playView.hidden = YES;
        [self.contentView addSubview:_playView];
        [_playView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.contentView);
            make.top.bottom.equalTo(self.contentView);
        }];
        
        self.resumeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.resumeButton setBackgroundImage:[MUIAudioViewHelper imageNamed:@"social_publish_button_voice_normal.png"] forState:UIControlStateNormal];
        [self.resumeButton setBackgroundImage:[MUIAudioViewHelper imageNamed:@"social_publish_button_voice_pressed.png"] forState:UIControlStateHighlighted];
        [self.resumeButton addTarget:self action:@selector(resumeRecord) forControlEvents:UIControlEventTouchUpInside];
        [_playView addSubview:self.resumeButton];
        [self.resumeButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(_playView);
           // make.top.bottom.equalTo(_playView);
             make.top.equalTo(self.timeLabel.mas_bottom).offset(9);
        }];
        
        self.playProgressView = [[MUIEditAudioPlayProgressView alloc] init];
        self.playProgressView.backgroundColor = [UIColor clearColor];
        [_playView addSubview:self.playProgressView];
        [_playView sendSubviewToBack:self.playProgressView];
        [self.playProgressView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.resumeButton).insets(UIEdgeInsetsZero);
        }];
        
        
        self.rerecordButton = [self circleButton];
        [self.rerecordButton setTitle:NSLocalizedString(@"MUIEditAudioRecordView_Rerecord") forState:UIControlStateNormal];
        [self.rerecordButton addTarget:self action:@selector(onRerecord) forControlEvents:UIControlEventTouchUpInside];
        [_playView addSubview:self.rerecordButton];
        [self.rerecordButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.resumeButton.mas_left).offset(-27);
            make.centerY.equalTo(self.resumeButton);
            make.size.mas_equalTo(CGSizeMake(kMUIEditRerecordButtonWidth, kMUIEditRerecordButtonWidth));
        }];
        
        self.confirmButton = [self circleButton];
        [self.confirmButton setTitle:NSLocalizedString(@"MUIEditDecorator.prepareMUIText3") forState:UIControlStateNormal];
        [self.confirmButton addTarget:self action:@selector(onConfirm) forControlEvents:UIControlEventTouchUpInside];
        [_playView addSubview:self.confirmButton];
        [self.confirmButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.resumeButton.mas_right).offset(27);
            make.centerY.equalTo(self.resumeButton);
            make.size.mas_equalTo(CGSizeMake(kMUIEditRerecordButtonWidth, kMUIEditRerecordButtonWidth));
        }];
        
        
        self.playButton= [self circleButton];
        [self.playButton setTitle:NSLocalizedString(@"MUIEditAudioRecordView_ClickTry") forState:UIControlStateNormal];
        [self.playButton addTarget:self action:@selector(startPlay) forControlEvents:UIControlEventTouchUpInside];
        [_playView addSubview:self.playButton];
        [self.playButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.resumeButton.mas_left);
            make.centerY.equalTo(self.resumeButton.mas_top).offset(-10);
            make.size.mas_equalTo(CGSizeMake(kMUIEditRerecordButtonWidth, kMUIEditRerecordButtonWidth));
        }];
    }
    return _playView;
}

- (UIButton *)circleButton {
    
    UIImage *normalImage = [UIImage mui_imageWithColor:[MUIAudioViewHelper colorWithKey:@"mui_audio_edit_circle_button_bg_color_normal"] size:CGSizeMake(1, 1)];
    UIImage *highlightedImage = [UIImage mui_imageWithColor:[MUIAudioViewHelper colorWithKey:@"mui_audio_edit_circle_button_bg_color_pressed"] size:CGSizeMake(1, 1)];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setBackgroundImage:normalImage forState:UIControlStateNormal];
    [button setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
    [button setTitleColor:[MUIAudioViewHelper colorWithKey:@"mui_audio_edit_circle_button_title_color"] forState:UIControlStateNormal];
    button.layer.cornerRadius = kMUIEditRerecordButtonWidth / 2.0;
    button.layer.masksToBounds = YES;
    button.layer.borderColor = [MUIAudioViewHelper colorWithKey:@"mui_audio_edit_circle_button_cg_color"].CGColor;
    button.layer.borderWidth = 0.5;
    button.titleLabel.font = [MUIAudioViewHelper fontWithKey:@"character_4"];
    button.titleLabel.numberOfLines = 2;
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    return button;
}

- (MUIAudioWaveView *)waveView {
    
    if (!_waveView) {
        _waveView = [[MUIAudioWaveView alloc] init];
        _waveView.waveColor = [MUIAudioViewHelper colorWithKey:@"mui_audio_edit_recode_wave_color"];
        _waveView.leftRightDistance = 127;
        [self.contentView addSubview:_waveView];
        [_waveView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.contentView);
            make.top.equalTo(self.timeLabel.mas_bottom).offset(9);
            make.bottom.equalTo(self.tipLabel.mas_top).offset(-9);
        }];
    }
    return _waveView;
}

- (void)setStatus:(MUIEditAudioStatus)status; {
    
    _status = status;
    
    if (status == MUIEditAudioStatus_Record) {
        self.playView.hidden = YES;
        self.recordView.hidden = NO;
        
        self.timeLabel.hidden = YES;
        self.timeLabel.textColor = [MUIAudioViewHelper colorWithKey:@"mui_audio_edit_recode_wave_color"];
        self.tipLabel.hidden=NO;
        self.tipLabel.text = NSLocalizedString(@"MUIEditAudioRecordView_Label_Text_ClickRecord");
        
    } else {
        self.playView.hidden = NO;
        self.recordView.hidden = YES;
        
        self.timeLabel.hidden = NO;
        self.timeLabel.textColor = [MUIAudioViewHelper colorWithKey:@"mui_audio_edit_recode_tip_color"];
        self.timeLabel.text = [NSString stringWithFormat:@"%ld\"", self.timeCount / 1000];
        
        self.tipLabel.text = NSLocalizedString(@"MUIEditAudioRecordView_Label_Text_ClickTry");
        
        self.topTipButton.hidden = YES;
       
        if (_recordStatus!=MUIEditRecordStatus_EndTime){
            [self.resumeButton addTarget:self action:@selector(resumeRecord) forControlEvents:UIControlEventTouchUpInside];
        }else{
           self.tipLabel.hidden=YES;
        }
        
    }
}

#pragma mark -
#pragma mark - 按钮点击事件
- (void)onRerecord {
    
    UIAlertView *alertView = [UIAlertView bk_alertViewWithTitle:@"" message:NSLocalizedString(@"MUIEditAudioRecordView_Rerecord_Alert")];
    
    @weakify(self);
    [alertView bk_addButtonWithTitle:NSLocalizedString(@"MUIEditDecorator.chatInputViewTakePic4") handler:^{
        @strongify(self);
        [self actionEndRecord];
        [self stopPlay];
        self.recordStatus=MUIEditRecordStatus_Readey;
        self.type = MUIEditAudioRecordType_New;
        self.status = MUIEditAudioStatus_Record;
        
        [self clearTmpFile];
        if ([self.delegate respondsToSelector:@selector(MUIEditRecordViewDidRerecord)]) {
            [self.delegate MUIEditRecordViewDidRerecord];
        }
    }];
    
    [alertView bk_setCancelButtonWithTitle:NSLocalizedString(@"MUIDetailViewController.onMore1") handler:nil];
    
    [alertView show];
}

- (void)onConfirm {
    
    _isGetFinishAudio=YES;
     [self.recordManager stop];
    
}

- (void)onCancel {
    
    if (self.type == MUIEditAudioRecordType_New && self.status == MUIEditAudioStatus_Play) {
        UIAlertView *alertView = [UIAlertView bk_alertViewWithTitle:@"" message:NSLocalizedString(@"MUIEditAudioRecordView_Rerecord_Alert")];
        
        @weakify(self);
        [alertView bk_addButtonWithTitle:NSLocalizedString(@"MUIEditDecorator.chatInputViewTakePic4") handler:^{
            @strongify(self);
            
            [self clearTmpFile];
            if ([self.delegate respondsToSelector:@selector(MUIEditRecordViewDidEndRecord:)]) {
                [self.delegate MUIEditRecordViewDidEndRecord:nil];
            }
            
            [self reset];
        }];
        
        [alertView bk_setCancelButtonWithTitle:NSLocalizedString(@"MUIDetailViewController.onMore1") handler:nil];
        
        [alertView show];
    } else {
        [self reset];
    }
}

-(void)resumeRecord{

    [self clearTmpFile];
    
    self.recordStatus=MUIEditRecordStatus_Recording;
    
    [self.recordManager resume];
    
    self.recordImageView.image = [MUIAudioViewHelper imageNamed:@"social_publish_button_pause_normal.png"];
    
    self.status =  MUIEditAudioStatus_Record;
    
    self.timeLabel.hidden = NO;
    [self startWave];
    [self startTimer];
    
}

- (void)reset {
    
    if (self.status == MUIEditAudioStatus_Record) {
        
        switch (_recordStatus) {
            case MUIEditRecordStatus_Readey:
                [self clearTmpFile];
                if ([self.delegate respondsToSelector:@selector(MUIEditRecordViewDidEndRecord:)]) {
                    [self.delegate MUIEditRecordViewDidEndRecord:nil];
                }
            break;
            case MUIEditRecordStatus_Recording:
                MUPLogDebug(@"MUIAudioView ---- MUIEditRecordStatus_Recording");
            break;
            
            default:
                [self actionEndRecord];
                self.type = MUIEditAudioRecordType_New;
                self.status = MUIEditAudioStatus_Record;
            break;
        }
        
    } else {
        [self stopPlay];
    }
}

- (void)close {
    
    if (_modalView) {
        MUPLogDebug(@"MUIAudioView ---- 隐藏modalView");
        _modalView.hidden = YES;
    }

//    [UIView animateWithDuration:0.3 animations:^{
//        self.mui_top = kMUIScreen_AppHeight;
//    } completion:^(BOOL finished) {
        self.hidden = YES;
//    }];
    if (self.status == MUIEditAudioStatus_Record) {
        [self actionEndRecord];
    } else {
        [self.playManager stop];
        [self stopTimer];
    }
    
    
}

- (void)updateRecordPercent {
    
    if (self.status == MUIEditAudioStatus_Record) {
        self.timeCount += kMUIEditTimerInterval * 1000;
        if (self.timeCount % 1000 == 0) {

            self.timeLabel.text = [NSString stringWithFormat:@"%ld\"", self.timeCount / 1000];
            
            int lasttime=_maximumDuration-(self.timeCount / 1000);
            if(lasttime<=10){
                self.topTipButton.hidden = NO;
                NSString *lastTimeStr=[NSString stringWithFormat:NSLocalizedString(@"MUIEditAudioRecordView_Msg_LastTime"),lasttime];
                [self.topTipButton setAttributedTitle:[MUIAudioViewHelper setDifferetTxt:lastTimeStr] forState:UIControlStateNormal];
                
            }else{
                self.topTipButton.hidden = YES;
            }
            
            
        }
        
        if (self.timeCount / 1000 == _maximumDuration) {
            
            [self stopTimer];
            [self.recordManager pause];
            [self stopWave];
            self.recordStatus=MUIEditRecordStatus_EndTime;
            self.status = MUIEditAudioStatus_Play;
            self.recordImageView.image = [MUIAudioViewHelper imageNamed:@"social_publish_button_voice_normal.png"];
             [self.resumeButton removeTarget:self action:@selector(resumeRecord) forControlEvents:UIControlEventTouchUpInside];
        } else if(self.timeCount % 200 == 0){
            CGFloat fVoiceLevel = [self.recordManager averagePower];
            if (fVoiceLevel < -45) {
                fVoiceLevel = -45;
            }
            self.waveView.soundVolume = 1 - (CGFloat)fVoiceLevel / (CGFloat)-45;
        }
    } else {
        self.timeCount = self.timeCount - kMUIEditTimerInterval * 1000;
        
        if (self.timeCount % 1000 == 0) {
            self.timeLabel.text = [NSString stringWithFormat:@"%ld\"", self.timeCount / 1000];
        }
        
        if (self.timeCount == 0) {
            [self stopPlay];
        } else {
            
            CGFloat percent = (CGFloat) (self.audio.duration - self.timeCount) / (CGFloat) self.audio.duration;
            [self.playProgressView updatePlayerPercent:percent];
        }
    }
    
}

- (void)stopTimer {
    
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    
    [self.waveView pause];
}

- (void)startTimer {
    
    if (!self.timer) {

        self.timer = [NSTimer scheduledTimerWithTimeInterval:kMUIEditTimerInterval
                                                      target:self
                                                    selector:@selector(updateRecordPercent)
                                                    userInfo:nil
                                                     repeats:YES];
    }
}

- (void)startWave {
    
    self.waveView.hidden = NO;
    self.waveView.soundVolume = 0.5;
    [self.waveView reStart];
    

    if (_recordStatus==MUIEditRecordStatus_Recording) {
        self.tipLabel.text=NSLocalizedString(@"MUIEditAudioRecordView_Label_Text_ClickPause");
    }else{
        self.tipLabel.hidden = YES;
    }
}

- (void)stopWave {
    
    [self.waveView pause];
    self.waveView.hidden = YES;
    
    self.tipLabel.text=NSLocalizedString(@"MUIEditAudioRecordView_Label_Text_ClickResume");
    if(self.recordStatus==MUIEditRecordStatus_EndTime){
        self.tipLabel.hidden = YES;
    }else{
        self.tipLabel.hidden = NO;
    }
    
}

#pragma mark - 重写hitTest

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
	
	UIView *view = [super hitTest:point withEvent:event];
	if (!view && _topView && !_topView.hidden) {
		// 转换坐标系
		CGPoint newPoint = [self.topView convertPoint:point fromView:self];
		// 判断触摸点是否在超出self的topView上
		if (CGRectContainsPoint(self.topView.bounds, newPoint)) {
			//返回topView,topView就可响应事件
			view = self.topView;
		}
	}
	return view;
}

#pragma mark - 录音

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [[event allTouches] anyObject];
    if (touch.view == self.recordImageView) {
        
        switch (_recordStatus) {
            case MUIEditRecordStatus_Readey:
                self.recordImageView.image = [MUIAudioViewHelper imageNamed:@"social_publish_button_voice_pressed.png"];
                [self actionBeginRecord];
            
            break;
            
            case MUIEditRecordStatus_Recording:
            
                _recordStatus=MUIEditRecordStatus_Pause;
            
                [self.recordManager pause];
                self.recordImageView.image = [MUIAudioViewHelper imageNamed:@"social_publish_button_voice_normal.png"];
            
                [self stopTimer];
            
                self.audio.duration = self.timeCount;
            
                self.status = MUIEditAudioStatus_Play;

                [self stopWave];
                [UIApplication sharedApplication].idleTimerDisabled = NO;// 自动锁屏
            
            
            
            break;

            default:
            break;
        }
        
       
       
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [[event allTouches] anyObject];
    if (touch.view == self.recordImageView) {
        
        switch (_recordStatus) {
            case MUIEditRecordStatus_Readey:
                self.recordImageView.image = [MUIAudioViewHelper imageNamed:@"social_publish_button_voice_pressed.png"];
 
                break;
                
            case MUIEditRecordStatus_Recording:
                
                self.recordImageView.image = [MUIAudioViewHelper imageNamed:@"social_publish_button_pause_pressed.png"];
   
                break;
                
            default:
                break;
        }

        
    }
}


//开始录音
- (void)actionBeginRecord {
 
    NSError *error = nil;
    [self.recordManager recordWithError:&error ];
    self.recordImageView.image = [MUIAudioViewHelper imageNamed:@"social_publish_button_voice_normal.png"];
    
    AVAuthorizationStatus AVstatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    switch (AVstatus) {
                //允许状态
        case AVAuthorizationStatusAuthorized:{
            NSLog(@"Authorized");
                
            if (error) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(MUIEditRecordViewFailRecord:)]) {
                    [self.delegate MUIEditRecordViewFailRecord:error];
                }
                    
                switch ([error code]) {
                    case MUPAudioRecordErrorTypeFoundMic: {
                        [[MBProgressHUD_MUIExt instance] show:YES withText:NSLocalizedString(@"MUIEditAudioRecordView_Msg_CannotFindAudioInput") inView:self];
                    }
                        break;
                    case MUPAudioRecordErrorTypeAccessMic: {
                        [self showAudioAuthorizedAlert];
                            
                            
                    }
                        break;
                    case MUPAudioRecordErrorTypeCreateFile: {
                        [[MBProgressHUD_MUIExt instance] show:YES withText:NSLocalizedString(@"MUIEditAudioRecordView_CreateFileError") inView:self];
                    }
                        break;
                    default:
                        break;
                    }
                    
                    self.recordImageView.image = [MUIAudioViewHelper imageNamed:@"social_publish_button_voice_normal.png"];
                } else {
                    
                    self.recordStatus=MUIEditRecordStatus_Recording;
                    [self startWave];
                    self.recordImageView.image = [MUIAudioViewHelper imageNamed:@"social_publish_button_pause_normal.png"];
                }
                
                }
                break;
                //不允许状态，可以弹出一个alertview提示用户在隐私设置中开启权限
        case AVAuthorizationStatusDenied:
                NSLog(@"Denied");
                [self showAudioAuthorizedAlert];
                break;
                //未知，第一次申请权限
        case AVAuthorizationStatusNotDetermined:
                NSLog(@"not Determined");
                
                break;
                //此应用程序没有被授权访问,可能是家长控制权限
        case AVAuthorizationStatusRestricted:
                NSLog(@"Restricted");
                
                [self showAudioAuthorizedAlert];
                break;
                
        default:
                break;
        }
   
}

//结束录音
- (void)actionEndRecord {
    
    [self stopTimer];
    
    [self.recordManager stop];
    
}

#pragma mark - 播放

- (void)startPlay {
    
    _recordStatusTmp=_recordStatus;
    _recordStatus=MUIEditRecordStatus_playing;
    
    [self startWave];
    [self.playManager setURL:[NSURL URLWithString:self.audio.filePath] error:nil];
    
    [self.playManager play];
    
    [self startTimer];
    
    [self.resumeButton setBackgroundImage:[MUIAudioViewHelper imageNamed:@"social_publish_button_stop_normal.png"] forState:UIControlStateNormal];
    [self.resumeButton setBackgroundImage:[MUIAudioViewHelper imageNamed:@"social_publish_button_stop_pressed.png"] forState:UIControlStateHighlighted];
    [self.resumeButton removeTarget:self action:@selector(resumeRecord) forControlEvents:UIControlEventTouchUpInside];
    [self.resumeButton addTarget:self action:@selector(stopPlay) forControlEvents:UIControlEventTouchUpInside];
    
    self.rerecordButton.hidden = YES;
    self.confirmButton.hidden = YES;
    self.playButton.hidden =YES;
    
}

- (void)stopPlay {
    
    _recordStatus=_recordStatusTmp;
    
    [self.playManager stop];
    
    [self stopTimer];
    
    self.timeCount = self.audio.duration;
    self.timeLabel.text = [NSString stringWithFormat:@"%ld\"", self.timeCount / 1000];
    
    [self.resumeButton setBackgroundImage:[MUIAudioViewHelper imageNamed:@"social_publish_button_voice_normal.png"] forState:UIControlStateNormal];
    [self.resumeButton setBackgroundImage:[MUIAudioViewHelper imageNamed:@"social_publish_button_voice_pressed.png"] forState:UIControlStateHighlighted];
    [self.resumeButton removeTarget:self action:@selector(stopPlay) forControlEvents:UIControlEventTouchUpInside];
    if (_recordStatus!=MUIEditRecordStatus_EndTime){
        [self.resumeButton addTarget:self action:@selector(resumeRecord) forControlEvents:UIControlEventTouchUpInside];
    }

    [self.playProgressView updatePlayerPercent:0];
    
    [self stopWave];
    
    self.rerecordButton.hidden = NO;
    self.confirmButton.hidden = NO;
    self.playButton.hidden =NO;
}

#pragma mark  - MUPAudioRecorderDelegate

- (void)audioRecorderDidBeginRecord:(MUPAudioRecorder *)recording {
    
    AVAuthorizationStatus AVstatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];//麦克风权限
   
    if (AVstatus==AVAuthorizationStatusAuthorized) {
        [UIApplication sharedApplication].idleTimerDisabled = YES;// 不自动锁屏
        self.timeCount = 0;
        [self startTimer];
        
        self.timeLabel.text = @"0\"";
        self.timeLabel.hidden = NO;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(MUIEditRecordViewDidBeginRecord)]) {
            [self.delegate MUIEditRecordViewDidBeginRecord];
        }
    }else{
        [self.recordManager stop];
        self.recordStatus=MUIEditRecordStatus_Readey;
        self.type = MUIEditAudioRecordType_New;
        self.status = MUIEditAudioStatus_Record;

    }
   
}

/**
 *    实例已经暂停录音
 *
 *    @param recorder     暂停录音的实例 AudioRecorder 对象
 *    @param filePath 录音音频文件保存的路径
 */
- (void)audioRecorderDidPauseRecording:(MUPAudioRecorder *)recorder
                              filePath:(NSURL *)filePath{
    
    self.audio.filePath = filePath.path;
    self.audio.duration = self.timeCount;
    
    NSArray * arr = [filePath.path.lastPathComponent  componentsSeparatedByString:@"."];
    
    _tmpAmrPath = [MUIAudioViewHelper GetPathByFileName:[arr[0] stringByAppendingString:@"_wavToamrTmp"]ofType:@"amr"];
    _tmpWavPath = [MUIAudioViewHelper GetPathByFileName:[arr[0] stringByAppendingString:@"_amrTowavTmp"]ofType:@"wav"];
    
   //  NSLog(@" pause file path:%@",filePath.path);
   // NSLog(@" pause newAmrPath path:%@",_tmpAmrPath);
   // NSLog(@" pause newWavPath path:%@",_tmpWavPath);
    
    NSError *toAmrError;
    if([MUPAudioUtility convertWavFile:filePath
                          toAmrFile:[NSURL URLWithString:_tmpAmrPath]
                                 error:&toAmrError]){
        
      //  NSLog(@" pause amrTmp file path:%@",_tmpAmrPath);
        NSError *toWavError;
        if([MUPAudioUtility convertAmrFile:[NSURL URLWithString:_tmpAmrPath] toWavFile:[NSURL URLWithString:_tmpWavPath] error:&toWavError]){
            
            NSLog(@" pause wavTmp file path:%@",_tmpWavPath);
            self.audio.filePath = _tmpWavPath;
        }
    }

}



/**
 *    实例已经保存音频文件至指定目录，完成录音
 */
- (void)audioRecorderDidFinishRecording:(MUPAudioRecorder *)recorder
                               filePath:(NSURL *)filePath
                                  error:(NSError *)error {
    AVAuthorizationStatus AVstatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];//麦克风权限
    
    if (AVstatus!=AVAuthorizationStatusAuthorized) {
        return;
    }
    
    
    if (error) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(MUIEditRecordViewFailRecord:)]) {
            [self.delegate MUIEditRecordViewFailRecord:error];
        }
        
        switch ([error code]) {
            case MUPAudioRecordErrorTypeAudioDuringShort: {
                [[MBProgressHUD_MUIExt instance] show:YES withText:NSLocalizedString(@"MUIEditAudioRecordView_Msg_AudioIsTooShort") inView:self];

                self.recordStatus=MUIEditRecordStatus_Readey;
                self.type = MUIEditAudioRecordType_New;
                self.status = MUIEditAudioStatus_Record;
                if (_isGetFinishAudio) {
                    _isGetFinishAudio=NO;
                }
            }
            break;
            default:
            break;
        }
        
        self.status = MUIEditAudioStatus_Record;
    } else {
        
        self.audio.filePath = filePath.path;
        self.audio.duration = self.timeCount;

        // NSLog(@" stop file path:%@",filePath.path);
        //[self startPlay];
        if (_isGetFinishAudio) {
            _isGetFinishAudio=NO;
            
            [self clearTmpFile];
            if ([self.delegate respondsToSelector:@selector(MUIEditRecordViewDidEndRecord:)]) {
                    [self.delegate MUIEditRecordViewDidEndRecord:self.audio];
            }
            
            [self reset];
        }
        
    }
    
    [UIApplication sharedApplication].idleTimerDisabled = NO;// 自动锁屏
}

- (void)audioRecorderDidBeginInterruption:(MUPAudioRecorder *)recorder; {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(MUIEditRecordViewBeginInterruption)]) {
        [self.delegate MUIEditRecordViewBeginInterruption];
    }
    
    [self stopWave];
    [self stopTimer];
    
    [UIApplication sharedApplication].idleTimerDisabled = NO;// 自动锁屏
}

#pragma mark -
#pragma mark - privacy

-(void)clearTmpFile{
    if (_tmpAmrPath) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:_tmpAmrPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:_tmpAmrPath error:nil];
        }
        _tmpAmrPath=nil;
    }
    
    if (_tmpWavPath) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:_tmpWavPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:_tmpWavPath error:nil];
        }
        _tmpWavPath=nil;
    }
}

-(void)showAudioAuthorizedAlert{
    NSString *appName = NSLocalizedStringFromTable(@"CFBundleDisplayName", @"InfoPlist", nil);
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"MUIEditAudioRecordView_MicrophoneCannotUse_Alert_Msg"),appName];
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"MUIEditAudioRecordView_MicrophoneCannotUse_Alert_Title")
                                message:message
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"MUIEditDecorator.chatInputViewTakePic4")
                      otherButtonTitles:nil] show];

}

@end
