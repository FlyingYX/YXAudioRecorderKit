//
//  MUIAudioLoadWaveView.h
//  Pods
//
//  Created by zhouwj on 15/12/2.
//
//  加载音频时的波纹view

#import <UIKit/UIKit.h>

@interface MUIAudioLoadWaveView : UIView

@property (nonatomic,assign) float progress;

@property (nonatomic,strong) UIImage *image;

- (void)startAminiation;

- (void)stopAminiation;

@end
