//
//  MUIAudioPlayManager.h
//  MUIAudioView
//
//  Created by admin on 2017/7/5.
//  Copyright © 2017年 ND. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <APFUIKit/APFUIKit.h>
#import <MUPFoundation/MUPFoundation.h>
#import <ContentServiceSDK/ContentServiceSDK.h>

#import "MUIAudio.h"

@protocol MUIAudioPlayManagerDelegate;

@interface MUIAudioPlayManager : NSObject

/**
 *  播放器
 */
@property (nonatomic, strong)   MUPAudioPlayer     *playManager;

/**
 *  下载线程
 */
@property (nonatomic, strong) MUPDownloadRequestOperation *downloadOperation;

/**
 *  音频
 */
@property (nonatomic, strong) MUIAudio *audio;

@property (nonatomic, weak)   id<MUIAudioPlayManagerDelegate>delegate;

/**
 *  开始播放
 */
- (void)beginPlay;
/**
 *  重新播放
 */
- (void)rePlay;
/**
 *  暂停播放
 */
- (void)pause;
/**
 *  停止播放
 */
- (void)stop;
/**
 *  是否在下载播放
 */
- (BOOL)canAudioDownLoad;
/**
 *  下载音频
 *
 *  @newprogress   返回下载进程
 *  @callBackBlock 返回下载结果
 */
- (void)downloadAudioProgress:(void(^)(CGFloat progress))newprogress
                callBackBlock:(void (^)(BOOL bSucceed, NSError *error))callBackBlock;

/**
 *  停止下载
 */
- (void)stopDownLoad;

/**
 *  获取播放进度时间显示字符串 00:xx/00:xx
 */
- (NSString *)getDurationString;

@end

@protocol MUIAudioPlayManagerDelegate <NSObject>

@optional

/**
 *   下载被打断
 */
- (void)muiAudioPlayManagerDidBeginInterruption:(MUIAudioPlayManager *)playManager;

/**
 *   播放结束
 */
- (void)muiAudioPlayManagerFinishPlaying:(MUIAudioPlayManager *)playManager;

@end
