//
//  MUIAudioPlayView
//  Pods
//
//  Created by zhouwj on 15/12/2.
//
//

#import "MUIAudioPlayView.h"
#import "MUIAudioWaveView.h"
#import "MUIAudioLoadProgressView.h"

#import "MUIAudioDefine.h"
#import "MUIAudioViewHelper.h"
#import "MUIAudioWaveView.h"

#import <Masonry/Masonry.h>
#import <libextobjc/EXTScope.h>

#import <APFUIKit/APFUIKit.h>
#import <MUPFoundation/MUPFoundation.h>
#import <ContentServiceSDK/ContentServiceSDK.h>



@interface MUIAudioPlayView ()<
MUPAudioPlayerDelegate
>

@property (nonatomic, strong) UILabel *durationLabel;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, weak)   MUPAudioPlayer     *playManager;

@property (nonatomic, strong) MUIAudioLoadProgressView *loadProgressView;
@property (nonatomic, assign) NSUInteger secondCount;
@property (nonatomic, strong) MUPDownloadRequestOperation *downloadOperation;
@property (nonatomic, assign) BOOL isLoadFail;
@property (nonatomic, strong) MUIAudioWaveView *waveView;

@end

@implementation MUIAudioPlayView

- (instancetype)initWithFrame:(CGRect)frame {
	
	self = [super initWithFrame:frame];
	if (self) {
		[self setBackgroundColor:[MUIAudioViewHelper colorWithKey:@"mui_audio_play_bg_color"]];
		
		self.durationLabel = [[UILabel alloc] init];
		self.durationLabel.textColor = [MUIAudioViewHelper colorWithKey:@"mui_audio_play_duration_color"];
		self.durationLabel.font = [MUIAudioViewHelper fontWithKey:@"character_5"];
		[self addSubview:self.durationLabel];
		[self.durationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
			make.leading.top.equalTo(self).offset(8);
		}];
		
		self.loadProgressView = [[MUIAudioLoadProgressView alloc] init];
		self.loadProgressView.hidden = YES;
		[self addSubview:self.loadProgressView];
        [self.loadProgressView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
        }];
		
		[self setImage:[MUIAudioViewHelper imageNamed:@"social_weibo_icon_voice.png"] forState:UIControlStateNormal];
		
		[self addTarget:self action:@selector(startPlay) forControlEvents:UIControlEventTouchUpInside];
		
		self.playManager = [MUPAudioPlayer sharedInstance];
		
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

- (void)dealloc {
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)removeFromSuperview {
	
	[super removeFromSuperview];
	
	[self stopDownloadAudio];
}

#pragma mark- notification

- (void)handleNotification_stopDownloadAudio:(NSNotification *)notification {
	
	[self stopDownloadAudio];
}

- (void)handleNotification_stopPlayAudio:(NSNotification *)notification {
	
	MUIAudio *audio = notification.object;
	if (audio != self.audio) {
		
		[self stopPlay:nil];
	}
}

#pragma mark- get set

- (void)setAudio:(MUIAudio *)audio {
	
	if (_audio != audio) {
		_audio = audio;
		
		self.durationLabel.text = [NSString stringWithFormat:@"%ld\"",audio.duration / 1000];
		self.secondCount = audio.duration / 1000;
	}
}

- (MUIAudioWaveView *)waveView {

	if (!_waveView) {
		_waveView = [[MUIAudioWaveView alloc] init];
		_waveView.waveColor = [MUIAudioViewHelper colorWithKey:@"mui_audio_play_duration_color"];
		[self addSubview:_waveView];
		[_waveView mas_makeConstraints:^(MASConstraintMaker *make) {
			make.edges.equalTo(self);
		}];
	}
	return _waveView;
}

#pragma mark- 播放

- (void)startPlay {
    
	if([[NSFileManager defaultManager] fileExistsAtPath:self.audio.filePath]) {
		
		[self startTimer];
		
		if (self.playManager.isPlaying) {
			[self.playManager stop];
			[[NSNotificationCenter defaultCenter] postNotificationName:kMUIAudioNotificationStopPlayAudio object:self.audio];
		}
		[self.playManager setURL:[NSURL fileURLWithPath:self.audio.filePath] error:nil];
		self.playManager.delegate = self;
		[self.playManager play];
        
        [self setImage:nil forState:UIControlStateNormal];
		
		[self removeTarget:self action:@selector(startPlay) forControlEvents:UIControlEventTouchUpInside];
		[self addTarget:self action:@selector(stopPlay:) forControlEvents:UIControlEventTouchUpInside];
		
		[self.waveView start];
		self.waveView.hidden = NO;
	} else {
        [self downloadAudio];
	}
}

- (void)stopPlay:(id)sender {
	
	if (sender) {
		//通过按钮停止播放音频,其他方式只是刷新UI(比如列表多个音频视图的播放停止状态的控制)
		[self.playManager stop];
	}
    [self stopPlayManager];
}

- (void)stopPlayAudio {
    
    [self.playManager stop];
    
    [self stopPlayManager];
}

- (void)stopPlayManager {
    
    [self stopTimer];
    [self removeTarget:self action:@selector(stopPlay:) forControlEvents:UIControlEventTouchUpInside];
    [self addTarget:self action:@selector(startPlay) forControlEvents:UIControlEventTouchUpInside];
    
    self.durationLabel.text = [NSString stringWithFormat:@"%ld\"",self.audio.duration / 1000];
    self.secondCount = self.audio.duration / 1000;
    [self setImage:[MUIAudioViewHelper imageNamed:@"social_weibo_icon_voice.png"] forState:UIControlStateNormal];
    
    [self.waveView pause];
    self.waveView.hidden = YES;
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
		self.timer = [NSTimer timerWithTimeInterval:1
											 target:self
										   selector:@selector(updateDuration)
										   userInfo:nil
											repeats:YES];
		[[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
	}
}

- (void)updateDuration {
	
	self.secondCount--;
	if (self.secondCount != 0) {
		self.durationLabel.text = [NSString stringWithFormat:@"%ld\"",self.secondCount];
	} else {
		[self stopPlay:nil];
	}
}


#pragma mark- 下载音频

- (void)downloadAudio {

	if (self.downloadOperation) {
		return;
	}
	
	[self startLoadView];
	
	NSString *amrFilePath = [MUIAudioViewHelper amrFilePathByName:self.audio.audioId];
	NSURL *audioURL = [CSDentry getDownURLWithSession:nil ext:nil dentryId:self.audio.audioId path:nil size:CSThumbSizeNone outError:nil];
	
	@weakify(self);
	self.downloadOperation = [CSDentry download:audioURL
									   localURI:amrFilePath
								 fileIdentifier:nil shouldAutoStart:YES
								progress:^(MUPDownloadRequestOperation *operation, NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpected, long long totalBytesReadForFile, long long totalBytesExpectedToReadForFile) {
									
									@strongify(self);
									
									 if (self.downloadOperation) {
										 self.loadProgressView.progress = (CGFloat) totalBytesReadForFile / totalBytesExpectedToReadForFile;

									 }
								} callBackBlock:^(BOOL bSucceed, NSError *error) {
                                 @strongify(self);
                                 
                                 if (!self.downloadOperation) {
                                     return ;
                                 }
                                 
                                 [self stopLoadView];
                                 if (bSucceed) {
                                     self.isLoadFail = NO;
									 
									 if ([NSString mup_stringIsEmpty:self.audio.filePath]) {
										 self.audio.filePath = [MUIAudioViewHelper wavFilePathByName:self.audio.audioId];
									 } else {
										 NSString *lastPathComponent = [self.audio.filePath lastPathComponent];
										 NSRange range = [self.audio.filePath rangeOfString:lastPathComponent];
										 NSString *dirPath = [self.audio.filePath substringToIndex:range.location];
										 BOOL isDir = YES;
										 if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath isDirectory:&isDir]) {
											 [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
										 }
									 }
                                     BOOL result = [MUPAudioUtility convertAmrFile:[NSURL fileURLWithPath:amrFilePath] toWavFile:[NSURL fileURLWithPath:self.audio.filePath] error:nil];
                                     if (result) {
                                         [[NSFileManager defaultManager] removeItemAtPath:amrFilePath error:nil];
                                         [self startPlay];
                                     }
                                 } else {
                                     self.isLoadFail = YES;
                                     [self setImage:[MUIAudioViewHelper imageNamed:@"social_weibo_icon_loading_fail.png"] forState:UIControlStateNormal];
                                     [self setBackgroundColor:[MUIAudioViewHelper colorWithKey:@"mui_audio_play_load_faile_color"]];
                                     MUPLogError(@"音频控件-下载音频失败，错误信息 = %@",error);
                                 }
                             }];
}

- (void)stopDownloadAudio {
	
	if (self.downloadOperation) {
		[self.downloadOperation cancel];
        self.downloadOperation = nil;
		
        [self stopLoadView];
        
        [self setImage:[MUIAudioViewHelper imageNamed:@"social_weibo_icon_voice.png"] forState:UIControlStateNormal];
	}
	
	if (self.isLoadFail) {
		self.isLoadFail = NO;
		[self setBackgroundColor:[MUIAudioViewHelper colorWithKey:@"mui_audio_play_bg_color"]];
		[self setImage:[MUIAudioViewHelper imageNamed:@"social_weibo_icon_voice.png"] forState:UIControlStateNormal];
	}
}

- (void)startLoadView {
	
	[self setBackgroundColor:[MUIAudioViewHelper colorWithKey:@"mui_audio_play_bg_color"]];
	[self setImage:nil forState:UIControlStateNormal];
	
    self.loadProgressView.progress = 0;
	[self.loadProgressView startAnimation];
	self.loadProgressView.hidden = NO;
}


- (void)stopLoadView {
	
    [self setImage:nil forState:UIControlStateNormal];
	
    self.loadProgressView.hidden = YES;
	[self.loadProgressView stopAnimation];
	
	if (self.downloadOperation) {
		self.downloadOperation = nil;
	}
}


#pragma mark - AudioPlayManagerDelegate -

- (void)audioPlayerDidEndInterruption:(MUPAudioPlayer *)player {
	
	[self stopPlay:nil];
}

- (void)audioPlayerDidFinishPlaying:(MUPAudioPlayer *)player
							success:(BOOL)success {
	
	[self stopPlay:nil];
}

@end
