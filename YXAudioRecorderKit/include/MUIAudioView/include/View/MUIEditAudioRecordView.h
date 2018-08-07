//
//  MUIEditAudioRecordView.h
//
//
//  Created by zhouwj on 14-3-3.
//  Copyright (c) 2014年 nd. All rights reserved.
//
//  音频录制View

#import <UIKit/UIKit.h>
#import "MUIAudio.h"

typedef NS_ENUM(NSUInteger, MUIEditAudioRecordType) {
	MUIEditAudioRecordType_New,       //录制新音频
	MUIEditAudioRecordType_Auditionn  //试听
};

@protocol MUIEditAudioRecordViewDelegate <NSObject>

@required

/**
*  录音结束，确认按钮点击，完成录音生成音频文件
*
*  @param audio 录音生成音频数据
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
*  @param error 错误提示
*/
- (void)MUIEditRecordViewFailRecord:(NSError *)error;

/**
*  录音被中断，比如有来电时
*/
- (void)MUIEditRecordViewBeginInterruption;

/**
 *  录音手势放开，结束录音（正常录音结束，未点击确认按钮）
 */
- (void)muiEditRecordViewBeingEndRecord;

/**
 *  手势滑出范围放开取消录音，取消录音
 */
- (void)muiEditRecordViewDrageCancleRecord;

@end

@interface MUIEditAudioRecordView : UIView

@property (nonatomic, strong) UIImageView *recordImageView;

/**
 *  type为 MUIEditAudioRecordType_New 时不用传入audio
 *  type为 MUIEditAudioRecordType_Auditionn 时需传入audio，且filePath，duration是必填项。其他选填。
 */
@property (nonatomic, strong) MUIAudio *audio;

/**
 *  type必填
 */
@property (nonatomic, assign) MUIEditAudioRecordType type;

/**
 *  delegate必填
 */
@property (nonatomic, weak) id <MUIEditAudioRecordViewDelegate> delegate;

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

