//
//  MUIAudioPlayView.h
//  Pods
//
//  Created by zhouwj on 15/12/2.
//
//  发布成功音频展示、播放view

#import <UIKit/UIKit.h>
#import "MUIAudio.h"


@interface MUIAudioPlayView : UIButton

@property (nonatomic, strong) MUIAudio *audio;

- (void)stopPlayAudio;

@end


