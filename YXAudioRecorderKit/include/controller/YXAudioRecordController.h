//
//  YXAudioRecordController.h
//  YXAudioRecorderKit
//
//  Created by yuxiang on 2018/6/6.
//  Copyright © 2018年 ND. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSString * YXAudioRecordControllerKey;

UIKIT_EXTERN YXAudioRecordControllerKey const YXAudioRecordControllerMinimumDurationKey;    //NSNumber of NSTimeInterval 录制最短时长
UIKIT_EXTERN YXAudioRecordControllerKey const YXAudioRecordControllerMaximumDurationKey;    //NSNumber of NSTimeInterval 录制最长时长
UIKIT_EXTERN YXAudioRecordControllerKey const YXAudioRecordControllerFileSaveDirectoryKey;  //NSString 录音文件存储目录
UIKIT_EXTERN YXAudioRecordControllerKey const YXAudioRecordControllerFileSaveNameKey;       //NSString 录音文件名
UIKIT_EXTERN YXAudioRecordControllerKey const YXAudioRecordControllerIfConvertAmrFileKey;   //NSNumber of BOOL 录音文件是否需要转换为amr文件

@interface YXAudioRecordController : UIViewController

/**
 create a audio record controller

 @param settings configure for the recording
 @param completionHandler 录音结束时的回调block.block参数:录音完成时生产录音文件URL, 录音时产生的错误信息.
 */
+ (instancetype)audioRecordControllerWithSettings:(nullable NSDictionary<YXAudioRecordControllerKey, id> *)settings
                                completionHandler:(nullable void (^)(NSURL *_Nullable wavfileURL, NSURL *_Nullable amrfileURL, NSError *_Nullable error))completionHandler;

@end

NS_ASSUME_NONNULL_END
