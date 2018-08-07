//
//  MUIEditAudioRecordView.m
//  MUIComponent
//
//  Created by zhouwj on 14-3-3.
//  Copyright (c) 2014年 nd. All rights reserved.
//

#define kTOP_TIP_VIEW_HEIGHT   44        //顶部提示语的宽度

#define kMUIEditRerecordButtonWidth            65

#define kMUIEditTimerInterval                  0.05

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

typedef NS_ENUM(NSUInteger, MUIAudioRecordCacelType) {
	MUIAudioRecordCacelType_Upglide,       //上滑取消
	MUIAudioRecordCacelType_Release        //松手取消
};


typedef NS_ENUM(NSUInteger, MUIEditAudioStatus) {
	MUIEditAudioStatus_Record,
	MUIEditAudioStatus_Play
};

@interface MUIEditAudioRecordView () <
MUPAudioRecorderDelegate,
MUPAudioPlayerDelegate
>

@property (nonatomic, strong) UIView             *contentView;
@property (nonatomic, strong) UIView             *topView;
@property (nonatomic, strong) UIView             *modalView;
@property (nonatomic, strong) UIView             *recordView;
@property (nonatomic, strong) UIView             *playView;
@property (nonatomic, strong) UIButton           *playButton;
@property (nonatomic, strong) UIButton           *rerecordButton;
@property (nonatomic, strong) UIButton           *confirmButton;
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

@end

@implementation MUIEditAudioRecordView

#pragma mark -
#pragma mark - init
- (instancetype)init {
    
	self = [super init];
	
	if (self) {
        _minimumDuration = 1;
        _maximumDuration = 300;
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
    _minimumDuration = minimumDuration;
    self.recordManager.minimumDuration = _minimumDuration;
}

- (void)setMaximumDuration:(NSTimeInterval)maximumDuration {
    
    if (_maximumDuration == maximumDuration) {
        return;
    }

    _maximumDuration = maximumDuration;
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
- (UIView *)modalView {
    
    if (!_modalView) {
		if (self.contentView.mui_height == 0) {
			[self layoutIfNeeded];
		}
        CGRect frame = CGRectMake(0, 0, kMUIScreen_Width, kMUIScreen_Height - self.contentView.mui_height - kTOP_TIP_VIEW_HEIGHT);
        _modalView = [[UIView alloc] initWithFrame:frame];
        _modalView.backgroundColor = [UIColor blackColor];
        _modalView.alpha = 0.6;
        
        [[UIApplication sharedApplication].keyWindow addSubview:_modalView];
        
        UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onCancel)];
        [_modalView addGestureRecognizer:gesture];
    }
    return _modalView;
}

- (UIView *)topView {
    
    if (!_topView) {
        _topView = [[UIView alloc] init];
        _topView.backgroundColor = [MUIAudioViewHelper colorWithKey:@"mui_audio_edit_bg_color"];
        [self addSubview:_topView];
        [self.topView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.trailing.equalTo(self);
            make.bottom.equalTo(self.contentView.mas_top);
            make.height.mas_equalTo(kTOP_TIP_VIEW_HEIGHT);
        }];
        _topView.hidden = YES;
    }
    return _topView;
}

- (UIButton *)topTipButton {
	
	if (!_topTipButton) {
		_topTipButton = [UIButton buttonWithType:UIButtonTypeCustom];
		_topTipButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
		_topTipButton.layer.cornerRadius = 5;
		[_topTipButton setTitleColor:[MUIAudioViewHelper colorWithKey:@"mui_audio_edit_cancel_tip_color"] forState:UIControlStateNormal];
		_topTipButton.titleLabel.font = [MUIAudioViewHelper fontWithKey:@"character_13"];
		_topTipButton.titleEdgeInsets = UIEdgeInsetsMake(0, 3, 0, -7);
		_topTipButton.contentEdgeInsets = UIEdgeInsetsMake(0, 7, 0, 10);
		[self.topView addSubview:_topTipButton];
		[_topTipButton mas_makeConstraints:^(MASConstraintMaker *make) {
			make.centerX.centerY.equalTo(self.topView);
			make.height.mas_equalTo(25);
		}];
	}
	return _topTipButton;
}

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
            make.top.equalTo(self.timeLabel.mas_bottom).offset(9);
        }];
        
        self.playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.playButton setBackgroundImage:[MUIAudioViewHelper imageNamed:@"social_publish_button_play_normal.png"] forState:UIControlStateNormal];
        [self.playButton setBackgroundImage:[MUIAudioViewHelper imageNamed:@"social_publish_button_play_pressed.png"] forState:UIControlStateHighlighted];
        [self.playButton addTarget:self action:@selector(startPlay) forControlEvents:UIControlEventTouchUpInside];
        [_playView addSubview:self.playButton];
        [self.playButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(_playView);
            make.top.bottom.equalTo(_playView);
        }];
        
        self.playProgressView = [[MUIEditAudioPlayProgressView alloc] init];
        self.playProgressView.backgroundColor = [UIColor clearColor];
        [_playView addSubview:self.playProgressView];
        [_playView sendSubviewToBack:self.playProgressView];
        [self.playProgressView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.playButton).insets(UIEdgeInsetsZero);
        }];
		
		
		self.rerecordButton = [self circleButton];
		[self.rerecordButton setTitle:NSLocalizedString(@"MUIEditAudioRecordView_Rerecord") forState:UIControlStateNormal];
		[self.rerecordButton addTarget:self action:@selector(onRerecord) forControlEvents:UIControlEventTouchUpInside];
		[_playView addSubview:self.rerecordButton];
		[self.rerecordButton mas_makeConstraints:^(MASConstraintMaker *make) {
			make.right.equalTo(self.playButton.mas_left).offset(-27);
			make.centerY.equalTo(self.playButton);
			make.size.mas_equalTo(CGSizeMake(kMUIEditRerecordButtonWidth, kMUIEditRerecordButtonWidth));
		}];
		
		self.confirmButton = [self circleButton];
		[self.confirmButton setTitle:NSLocalizedString(@"MUIEditDecorator.prepareMUIText3") forState:UIControlStateNormal];
		[self.confirmButton addTarget:self action:@selector(onConfirm) forControlEvents:UIControlEventTouchUpInside];
		[_playView addSubview:self.confirmButton];
		[self.confirmButton mas_makeConstraints:^(MASConstraintMaker *make) {
			make.left.equalTo(self.playButton.mas_right).offset(27);
			make.centerY.equalTo(self.playButton);
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
		
		self.tipLabel.text = NSLocalizedString(@"MUIEditAudioRecordView_Label_Text_LongPressedRecord");
		
		_topView.hidden = YES;
		
		if (_modalView) {
			_modalView.hidden = YES;
		}
	} else {
		self.playView.hidden = NO;
		self.recordView.hidden = YES;
		
		self.timeLabel.hidden = NO;
		self.timeLabel.textColor = [MUIAudioViewHelper colorWithKey:@"mui_audio_edit_recode_tip_color"];
		self.timeLabel.text = [NSString stringWithFormat:@"%ld\"", self.timeCount / 1000];
		
		self.tipLabel.text = NSLocalizedString(@"MUIEditAudioRecordView_Label_Text_ClickTry");
		
		self.topView.hidden = NO;
		
		self.modalView.hidden = NO;
	}
}

#pragma mark -
#pragma mark - 按钮点击事件
- (void)onRerecord {
	
	UIAlertView *alertView = [UIAlertView bk_alertViewWithTitle:@"" message:NSLocalizedString(@"MUIEditAudioRecordView_Rerecord_Alert")];
	
	@weakify(self);
	[alertView bk_addButtonWithTitle:NSLocalizedString(@"MUIEditDecorator.chatInputViewTakePic4") handler:^{
		@strongify(self);
		[self stopPlay];
		self.type = MUIEditAudioRecordType_New;
		self.status = MUIEditAudioStatus_Record;
		
		if ([self.delegate respondsToSelector:@selector(MUIEditRecordViewDidRerecord)]) {
			[self.delegate MUIEditRecordViewDidRerecord];
		}
	}];
	
	[alertView bk_setCancelButtonWithTitle:NSLocalizedString(@"MUIDetailViewController.onMore1") handler:nil];
	
	[alertView show];
}

- (void)onConfirm {
	
	if ([self.delegate respondsToSelector:@selector(MUIEditRecordViewDidEndRecord:)]) {
        [self.delegate MUIEditRecordViewDidEndRecord:self.audio];
	}
    [self reset];
}

- (void)onCancel {
	
	if (self.type == MUIEditAudioRecordType_New && self.status == MUIEditAudioStatus_Play) {
		UIAlertView *alertView = [UIAlertView bk_alertViewWithTitle:@"" message:NSLocalizedString(@"MUIEditAudioRecordView_Rerecord_Alert")];
		
		@weakify(self);
		[alertView bk_addButtonWithTitle:NSLocalizedString(@"MUIEditDecorator.chatInputViewTakePic4") handler:^{
			@strongify(self);
            
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

- (void)reset {
    
    if (self.status == MUIEditAudioStatus_Record) {
        [self actionEndRecord];
        if (_modalView) {
            _modalView.hidden = YES;
        }
        self.type = MUIEditAudioRecordType_New;
        self.status = MUIEditAudioStatus_Record;
    } else {
        [self stopPlay];
    }
}

- (void)close {
    
    if (_modalView) {
        MUPLogDebug(@"MUIAudioView ---- 隐藏modalView");
        _modalView.hidden = YES;
    }
    if (_topView) {
        _topView.hidden = YES;
    }
    [UIView animateWithDuration:0.3 animations:^{
        self.mui_top = kMUIScreen_AppHeight;
    } completion:^(BOOL finished) {
        self.hidden = YES;
    }];
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
		}
		
        if (self.timeCount / 1000 == _maximumDuration) {
            [self actionEndRecord];
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
	
    if (_waveView) {
        [_waveView pause];
    }
}

- (void)startTimer {

    if (!self.timer) {
        
        if (_recordView && !_recordView.hidden) {
            self.timeCount = 0;
        }
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
	
	self.tipLabel.hidden = YES;
}

- (void)stopWave {
	
	[self.waveView pause];
	self.waveView.hidden = YES;
	
	self.tipLabel.hidden = NO;
}

#pragma mark - 重写hitTest

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
	
	UIView *view = [super hitTest:point withEvent:event];
	if (!view && _topView && !_topView.hidden && !self.hidden) {
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

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	
	UITouch *touch = [[event allTouches] anyObject];
	if (touch.view == self.recordImageView) {
		[self actionBeginRecord];
		self.recordImageView.image = [MUIAudioViewHelper imageNamed:@"social_publish_button_voice_pressed.png"];
	}
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	
	UITouch *touch = [[event allTouches] anyObject];
	if (touch.view == self.recordImageView) {
		CGPoint point = [touch locationInView:self.recordView];
		
		if (point.y <= self.recordImageView.mui_top) {
			[self actionDragOutsideRecord];
		} else {
			[self actionDragInsideRecord];
		}
	}
	
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	
	UITouch *touch = [[event allTouches] anyObject];
	if (touch.view == self.recordImageView) {
		CGPoint point = [touch locationInView:self.recordView];
		if (point.y <= self.recordImageView.mui_top) {
			[self actionUpOutsideRecord];
		} else {
            
            if ([self.delegate respondsToSelector:@selector(muiEditRecordViewBeingEndRecord)]) {
                [self.delegate muiEditRecordViewBeingEndRecord];
            }
			[self actionEndRecord];
		}
		self.recordImageView.image = [MUIAudioViewHelper imageNamed:@"social_publish_button_voice_normal.png"];
	}
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    if (touch.view == self.recordImageView) {
        CGPoint point = [touch locationInView:self.recordView];
        if (point.y <= self.recordImageView.mui_top) {
            [self actionUpOutsideRecord];
        } else {
            [self actionEndRecord];
        }
        self.recordImageView.image = [MUIAudioViewHelper imageNamed:@"social_publish_button_voice_normal.png"];
    }
}

//开始录音
- (void)actionBeginRecord {
	
    NSError *error = nil;
    [self.recordManager recordWithError:&error];
    if (error) {
        MUPLogDebug(@"%---@", error);
        if (self.delegate && [self.delegate respondsToSelector:@selector(MUIEditRecordViewFailRecord:)]) {
            [self.delegate MUIEditRecordViewFailRecord:error];
        }
        
        switch ([error code]) {
            case MUPAudioRecordErrorTypeFoundMic: {
                [[MBProgressHUD_MUIExt instance] show:YES withText:NSLocalizedString(@"MUIEditAudioRecordView_Msg_CannotFindAudioInput") inView:self];
            }
                break;
            case MUPAudioRecordErrorTypeAccessMic: {
                NSString *appName = NSLocalizedStringFromTable(@"CFBundleDisplayName", @"InfoPlist", nil);
                NSString *message = [NSString stringWithFormat:NSLocalizedString(@"MUIEditAudioRecordView_MicrophoneCannotUse_Alert_Msg"),appName];
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"MUIEditAudioRecordView_MicrophoneCannotUse_Alert_Title")
                                            message:message
                                           delegate:nil
                                  cancelButtonTitle:NSLocalizedString(@"MUIEditDecorator.chatInputViewTakePic4")
                                  otherButtonTitles:nil] show];
                
                
            }
                break;
            case MUPAudioRecordErrorTypeCreateFile: {
                [[MBProgressHUD_MUIExt instance] show:YES withText:NSLocalizedString(@"MUIEditAudioRecordView_CreateFileError") inView:self];
            }
                break;
            default:
                break;
		}
	} else {
	    [self startWave];
		
		self.topView.hidden = NO;
		[self changeRecordCancelTip:MUIAudioRecordCacelType_Upglide];
		self.topTipButton.hidden = NO;
	}
}

//结束录音
- (void)actionEndRecord {

    [self stopTimer];

    [self.recordManager stop];
	
	_topTipButton.hidden = YES;
}

//录音拖到外部
- (void)actionDragOutsideRecord {
	
	[self changeRecordCancelTip:MUIAudioRecordCacelType_Release];
}

//录音拖到内部
- (void)actionDragInsideRecord {
	
	[self changeRecordCancelTip:MUIAudioRecordCacelType_Upglide];
}

//录音在外部松开手
- (void)actionUpOutsideRecord {
	
    if ([self.delegate respondsToSelector:@selector(muiEditRecordViewDrageCancleRecord)]) {
        [self.delegate muiEditRecordViewDrageCancleRecord];
    }
	[self.recordManager cancel];
	[self stopTimer];
	[self stopWave];
	self.status = MUIEditAudioStatus_Record;
}

- (void)changeRecordCancelTip:(MUIAudioRecordCacelType)type {
	
	if (type == MUIAudioRecordCacelType_Upglide) {
		[self.topTipButton setImage:[MUIAudioViewHelper imageNamed:@"social_publish_icon_up"] forState:UIControlStateNormal];
		[self.topTipButton setTitle:NSLocalizedString(@"MUIEditAudioRecordView_Upglide_Cancel") forState:UIControlStateNormal];
		NSString *colorHex = [UIColor mui_hexValuesFromUIColor:[MUIAudioViewHelper colorWithKey:@"mui_audio_edit_upglide_cancel_bg_color"]];
		self.topTipButton.backgroundColor = [UIColor mui_colorWithHexString:colorHex alpha:0.45];
	} else {
		[self.topTipButton setImage:[MUIAudioViewHelper imageNamed:@"social_publish_icon_updelete"] forState:UIControlStateNormal];
		[self.topTipButton setTitle:NSLocalizedString(@"MUIEditAudioRecordView_Release_Cancel") forState:UIControlStateNormal];
		self.topTipButton.backgroundColor = [MUIAudioViewHelper colorWithKey:@"mui_audio_edit_release_cancel_bg_color"];
	}
}

#pragma mark - 播放

- (void)startPlay {
	
	[self startWave];
    
    [self.playManager setURL:[NSURL URLWithString:self.audio.filePath] error:nil];
    
    [self.playManager play];
    
    [self startTimer];
    
    [self.playButton setBackgroundImage:[MUIAudioViewHelper imageNamed:@"social_publish_button_stop_normal.png"] forState:UIControlStateNormal];
    [self.playButton setBackgroundImage:[MUIAudioViewHelper imageNamed:@"social_publish_button_stop_pressed.png"] forState:UIControlStateHighlighted];
    [self.playButton removeTarget:self action:@selector(startPlay) forControlEvents:UIControlEventTouchUpInside];
    [self.playButton addTarget:self action:@selector(stopPlay) forControlEvents:UIControlEventTouchUpInside];
	
	self.rerecordButton.hidden = YES;
	self.confirmButton.hidden = YES;
}

- (void)stopPlay {
	
	[self.playManager stop];
	
	[self stopTimer];
	
    self.timeCount = self.audio.duration;
	self.timeLabel.text = [NSString stringWithFormat:@"%ld\"", self.timeCount / 1000];
	
	[self.playButton setBackgroundImage:[MUIAudioViewHelper imageNamed:@"social_publish_button_play_normal.png"] forState:UIControlStateNormal];
	[self.playButton setBackgroundImage:[MUIAudioViewHelper imageNamed:@"social_publish_button_play_pressed.png"] forState:UIControlStateHighlighted];
	[self.playButton removeTarget:self action:@selector(stopPlay) forControlEvents:UIControlEventTouchUpInside];
	[self.playButton addTarget:self action:@selector(startPlay) forControlEvents:UIControlEventTouchUpInside];
	
	[self.playProgressView updatePlayerPercent:0];
	
	[self stopWave];
	
	self.rerecordButton.hidden = NO;
	self.confirmButton.hidden = NO;
}

#pragma mark  - MUPAudioRecorderDelegate

- (void)audioRecorderDidBeginRecord:(MUPAudioRecorder *)recording {

	
	[UIApplication sharedApplication].idleTimerDisabled = YES;// 不自动锁屏
	
    [self startTimer];

    self.timeLabel.text = @"0\"";
    self.timeLabel.hidden = NO;

    if (self.delegate && [self.delegate respondsToSelector:@selector(MUIEditRecordViewDidBeginRecord)]) {
        [self.delegate MUIEditRecordViewDidBeginRecord];
    }
}

/**
*    实例已经保存音频文件至指定目录，完成录音
*/
- (void)audioRecorderDidFinishRecording:(MUPAudioRecorder *)recorder
                               filePath:(NSURL *)filePath
                                  error:(NSError *)error {

    if (error) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(MUIEditRecordViewFailRecord:)]) {
            [self.delegate MUIEditRecordViewFailRecord:error];
        }
        
        switch ([error code]) {
            case MUPAudioRecordErrorTypeAudioDuringShort: {
                [[MBProgressHUD_MUIExt instance] show:YES withText:NSLocalizedString(@"MUIEditAudioRecordView_Msg_AudioIsTooShort") inView:self];
            }
                break;
            default:
                break;
        }
		
		self.status = MUIEditAudioStatus_Record;
    } else {
        
        self.audio.filePath = filePath.path;
        self.audio.duration = self.timeCount;
        
		self.status = MUIEditAudioStatus_Play;
    }
	
	[self stopWave];
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

@end



