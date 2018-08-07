//
//  MUIAudioLoadProgressView.m
//  Pods
//
//  Created by zhouwj on 15/12/2.
//
//

#import "MUIAudioLoadProgressView.h"
#import "MUIAudioLoadWaveView.h"

#import "MUIAudioViewHelper.h"

#import <Masonry/Masonry.h>


@implementation MUIAudioLoadProgressView


- (instancetype)initWithFrame:(CGRect)frame {
	
	self = [super initWithFrame:frame];
    if (self) {
        [self initSubView];
    }
    return self;
}

- (void)initSubView {
	
	self.loadingImageView = [[UIImageView alloc] init];
	self.loadingImageView.image = [MUIAudioViewHelper imageNamed:@"general_loading_nd_circle"];
	[self addSubview:self.loadingImageView];
	[self.loadingImageView mas_makeConstraints:^(MASConstraintMaker *make) {
		make.edges.equalTo(self);
	}];
	
	self.backgroundImageView = [[UIImageView alloc] init];
	self.backgroundImageView.image = [MUIAudioViewHelper imageNamed:@"general_loading_nd_surface"];
	[self addSubview:self.backgroundImageView];
	[self.backgroundImageView mas_makeConstraints:^(MASConstraintMaker *make) {
		make.center.equalTo(self);
	}];
	
	self.waveView = [[MUIAudioLoadWaveView alloc] init];
	self.waveView.image = [MUIAudioViewHelper imageNamed:@"general_loading_nd_content"];
	[self addSubview:self.waveView];
	[self.waveView mas_makeConstraints:^(MASConstraintMaker *make) {
		make.center.equalTo(self);
	}];
}

- (void)startAnimation {
	
    [self.waveView startAminiation];
    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 ];
    rotationAnimation.duration = 1.5;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = 1E10;
    rotationAnimation.removedOnCompletion = NO;
    [self.loadingImageView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

- (void)stopAnimation {
	
    [self.waveView stopAminiation];
    [self.loadingImageView.layer removeAllAnimations];
}

#pragma mark getter & setter


- (void)setProgress:(CGFloat)progress {
    if (progress < -1e-8 || progress > 1.0 + 1e-8 || isnan(progress)) {
        //越界了 认为进度是0 防止崩溃
        progress = 0.0;
    }
    
    _progress = progress;
    
    self.waveView.progress = progress;
}

@end
