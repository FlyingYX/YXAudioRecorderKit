//
//  MUIAudioWaveView.h
//  selfInBlock
//
//  Created by Bruce on 15/12/4.
//  Copyright © 2015年 Bruce. All rights reserved.
//
//  播放音频时的波纹view

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, MUIAudioWaveDerectionType) {
    
    MUIAudioWaveDerectionType_MiddleToBothSide = 0, //自中间向两边扩散
    MUIAudioWaveDerectionType_LeftToRight,          //自左向右
    MUIAudioWaveDerectionType_RightToLeft           //自右向左
};


@interface MUIAudioWaveView : UIView
/**
 *  波形填充颜色
 */
@property (nonatomic, strong) UIColor *waveColor;
/**
 *  刷新间隔时间（默认0.015s）
 */
@property (nonatomic, assign) NSTimeInterval refreshInterval;
/**
 *  波峰距离（默认120点像素）
 */
@property (nonatomic, assign) double waveCrestDistance;
/**
 *  音量大小(0-1)默认0.5
 */
@property (nonatomic, assign) double soundVolume;
/**
 *  左右两个波形的距离,当waveDirectionType为MUIAudioWaveDerectionType_MiddleToBothSide时有效
 */
@property (nonatomic, assign) CGFloat leftRightDistance;

/**
 *  波形方向，默认自中间向两边
 */
@property (nonatomic, assign) MUIAudioWaveDerectionType waveDirectionType;

/**
 *  波形填充区域宽度，默认为1.5
 */
@property (nonatomic, assign) CGFloat waveWidth;
/**
 *  两个波形之间的间距，默认为1
 */
@property (nonatomic, assign) CGFloat waveSpace;

/**
 *  创建一个初始化态的波形图
 */
- (void)ceateDefaultWave;

/**
 *  开始动画
 */
- (void)start;
/**
 *  重置动画
 */
- (void)reStart;
/**
 *  停止动画
 */
- (void)pause;

@end
