//
//  MUIEditAudioNewRecordView.h
//  Pods
//
//  Created by 陈䶮 on 2017/7/11.
//
//

#import <UIKit/UIKit.h>
#import "MUIEditAudioRecordView.h"
#import "MUIAudio.h"

@protocol MUIEditAudioNewRecordViewDelegate <NSObject>

@required

/**
 *  录音结束
 *
 *  @param audio
 */
- (void)MUIEditRecordViewDidEndRecord:(MUIAudio *)audio;


/**
 *
 *  重录
 */
- (void)MUIEditRecordViewDidRerecord;


@optional

/**
 *  开始录音
 */
- (void)MUIEditRecordViewDidBeginRecord;

/**
 *  录音失败
 *
 *  @param error
 */
- (void)MUIEditRecordViewFailRecord:(NSError *)error;

/**
 *  录音被中断，比如有来电时
 */
- (void)MUIEditRecordViewBeginInterruption;

@end


@interface MUIEditAudioNewRecordView : UIView

@property (nonatomic, strong) UIImageView *recordImageView;

/**
 *  type为 MUIEditAudioRecordType_New 时不用传入audio
 *  type为 MUIEditAudioRecordType_Auditionn 时需传入audio，且filePath，duration是必填项。其他选填。
 */
@property (nonatomic, strong) MUIAudio *audio;

/**
 *  delegate必填
 */
@property (nonatomic, weak) id <MUIEditAudioNewRecordViewDelegate> delegate;

/**
 *  controller必填
 *  controller传入，在录制好一段录音后，不支持右滑返回。而在开始录制前，可支持右滑返回。
 *  controller传入，还处理了在controller上add一个半透明的遮罩。点击到遮罩处，会弹出 alert 询问是否放弃该段录音？
 */
@property (nonatomic, weak) UIViewController *controller;

/**
 * 可以使用这个变量来指定最短录音的时长，单位为秒，不能短于1秒。
 * 默认使用内部设置最短录音时长一秒
 */
@property (nonatomic, assign) NSTimeInterval minimumDuration;

/**
 * 可以使用这个变量来指定最长录音的时长。单位为秒。
 * 默认值为300秒。录音会在到达最大时长时自动结束。
 */
@property (nonatomic, assign) NSTimeInterval maximumDuration;


- (void)close;

@end
