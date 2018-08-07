//
//  MUIAudioNewPlayView.h
//  MUIAudioView
//
//  Created by admin on 2017/7/5.
//  Copyright © 2017年 ND. All rights reserved.
//
//  新的播放界面，按钮和波纹分开展示，时间显示在最后

#import <UIKit/UIKit.h>
#import "MUIAudioWaveView.h"
#import "MUIAudio.h"

@protocol MUIAudioNewPlayViewDelegate;

@interface MUIAudioNewPlayView : UIView

/**
 *   播放按钮，默认有背景色
 */
@property (nonatomic, strong) UIButton *playButton;

/**
 *   波形图
 */
@property (nonatomic, strong) MUIAudioWaveView *waveView;

/**
 *   时间展示Label
 */
@property (nonatomic, strong) UILabel *durationLabel;

/**
 *   加载失败提示语Label
 */
@property (nonatomic, strong) UILabel *downLoadFailTipLabel;

/**
 *   音频模型,播放音频时传入的音频数据，其中audioId和duration为必填项目
 */
@property (nonatomic, strong) MUIAudio *audio;

/**
 *   代理事件
 */
@property (nonatomic, weak) id <MUIAudioNewPlayViewDelegate> playDelegate;

/**
 *   显示初始默认态波形图
 *   需要在自动布局完成，界面给定宽高之后调用
 */
- (void)showDefaultWaveView;

@end

@protocol MUIAudioNewPlayViewDelegate <NSObject>

@optional

/**
 *  开始播放音频
 *  如果需要对playButton中的图片进行修改，可实现该方法
 */
- (void)muiAudioNewPlayViewStartPlay:(MUIAudioNewPlayView *)playView;

/**
 *  暂停播放音频
 *  如果需要对playButton中的图片进行修改，可实现该方法
 */
- (void)muiAudioNewPlayViewPausePlay:(MUIAudioNewPlayView *)playView;

/**
 *  恢复播放
 *  如果需要对playButton中的图片进行修改，可实现该方法
 */
- (void)muiAudioNewPlayViewReStartPlay:(MUIAudioNewPlayView *)playView;

/**
 *  停止播放，播放时会将playButton的image给清空
 *  如果需要对playButton中的图片进行修改，可实现该方法
 */
- (void)muiAudioNewPlayViewStopPlay:(MUIAudioNewPlayView *)playView;

/**
 *  停止加载音频
 *  如果需要对playButton中的图片进行修改，可实现该方法
 */
- (void)muiAudioNewPlayViewStopDownLoadAudio:(MUIAudioNewPlayView *)playView;

/**
 *  加载音频失败
 *  如果需要对playButton中的图片进行修改，可实现该方法
 */
- (void)muiAudioNewPlayViewDownLoadAudioFailure:(MUIAudioNewPlayView *)playView;


@end

