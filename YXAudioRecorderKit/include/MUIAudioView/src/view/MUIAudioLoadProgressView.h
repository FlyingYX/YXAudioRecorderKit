//
//  MUIAudioLoadProgressView.h
//  Pods
//
//  Created by zhouwj on 15/12/2.
//
//  加载音频时的进度view

#import <UIKit/UIKit.h>

@class MUIAudioLoadWaveView;

@interface MUIAudioLoadProgressView : UIView

@property (nonatomic, strong) UIImageView *loadingImageView;
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) MUIAudioLoadWaveView *waveView;
@property (nonatomic, assign) CGFloat progress;

- (void)startAnimation;

- (void)stopAnimation;

@end
