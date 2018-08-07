//
//  MUIAudioPlayManager.m
//  MUIAudioView
//
//  Created by admin on 2017/7/5.
//  Copyright © 2017年 ND. All rights reserved.
//

#import "MUIAudioPlayManager.h"

#import "MUIAudioDefine.h"
#import "MUIAudioViewHelper.h"

#import <libextobjc/EXTScope.h>

@interface MUIAudioPlayManager ()
<MUPAudioPlayerDelegate>

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation MUIAudioPlayManager

- (instancetype)init {
    
    if (self) {
        self.playManager = [[MUPAudioPlayer alloc] init];
        self.playManager.delegate = self;
    }
    return self;
}

#pragma mark - 音频播放相关
- (void)beginPlay {
    
    if (self.playManager.isPlaying) {
        [self.playManager stop];
        [[NSNotificationCenter defaultCenter] postNotificationName:kMUIAudioNotificationStopPlayAudio object:self.audio];
    }
    [self.playManager setURL:[NSURL fileURLWithPath:self.audio.filePath] error:nil];
    [self.playManager play];
}

- (void)rePlay {

    [self.playManager play];
}

- (void)pause {
    
    [self.playManager pause];
}

- (void)stop {
    
    [self.playManager stop];
}

#pragma mark - 音频下载相关
- (BOOL)canAudioDownLoad {
    
    if (self.downloadOperation) {
        return NO;
    }
    return YES;
}

- (void)downloadAudioProgress:(void(^)(CGFloat progress))newprogress
                callBackBlock:(void (^)(BOOL bSucceed, NSError *error))callBackBlock {
    
    NSString *amrFilePath = [MUIAudioViewHelper amrFilePathByName:self.audio.audioId];
    NSURL *audioURL = [CSDentry getDownURLWithSession:nil ext:nil dentryId:self.audio.audioId path:nil size:CSThumbSizeNone outError:nil];
    
    @weakify(self);
    self.downloadOperation = [CSDentry download:audioURL
                                       localURI:amrFilePath
                                 fileIdentifier:nil shouldAutoStart:YES
                                       progress:^(MUPDownloadRequestOperation *operation, NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpected, long long totalBytesReadForFile, long long totalBytesExpectedToReadForFile) {
                                           
                                           @strongify(self);
                                           
                                           if (self.downloadOperation && newprogress) {
                                               newprogress((CGFloat) totalBytesReadForFile / totalBytesExpectedToReadForFile);
                                               
                                           }
                                       } callBackBlock:^(BOOL bSucceed, NSError *error) {
                                           @strongify(self);
                                           
                                           if (!self.downloadOperation) {
                                               callBackBlock(NO,nil);
                                               return ;
                                           }
                                           if (bSucceed) {
                                               
                                               if ([NSString mup_stringIsEmpty:self.audio.filePath]) {
                                                   self.audio.filePath = [MUIAudioViewHelper wavFilePathByName:self.audio.audioId];
                                               } else {
                                                   NSString *lastPathComponent = [self.audio.filePath lastPathComponent];
                                                   NSRange range = [self.audio.filePath rangeOfString:lastPathComponent];
                                                   NSString *dirPath = [self.audio.filePath substringToIndex:range.location];
                                                   BOOL isDir = YES;
                                                   if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath isDirectory:&isDir]) {
                                                       [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
                                                   }
                                               }
                                               BOOL result = [MUPAudioUtility convertAmrFile:[NSURL fileURLWithPath:amrFilePath] toWavFile:[NSURL fileURLWithPath:self.audio.filePath] error:nil];
                                               if (result) {
                                                   [[NSFileManager defaultManager] removeItemAtPath:amrFilePath error:nil];
                                               }
                                               callBackBlock(result,nil);
                                           } else {
                                               callBackBlock(bSucceed,error);
                                           }
                                       }];
}

- (void)stopDownLoad {
    
    if (self.downloadOperation) {
        [self.downloadOperation cancel];
        self.downloadOperation = nil;
    }
}

- (NSString *)getDurationString {
    
    MUPLogDebug(@"-- MUIAudioNewPlayView -- currentTime = %f, duration = %f",self.playManager.currentTime,self.playManager.duration);
    return [NSString stringWithFormat:@"%@ / %@",[self getTimeStringWithSec:self.playManager.currentTime], [self getTimeStringWithSec:self.playManager.duration]];
}

- (NSString *)getTimeStringWithSec:(NSTimeInterval)sec {
    
    // 格式化时间
    if (!self.dateFormatter) {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [self.dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [self.dateFormatter setDateFormat:@"mm:ss"];
    }
    
    NSDate* date = [NSDate dateWithTimeIntervalSince1970:sec];
    NSString* dateString = [self.dateFormatter stringFromDate:date];
    return dateString;
}

- (void)audioPlayerDidFinishPlaying:(MUPAudioPlayer *)player success:(BOOL)success {
    
    if ([self.delegate respondsToSelector:@selector(muiAudioPlayManagerFinishPlaying:)]) {
        [self.delegate muiAudioPlayManagerFinishPlaying:self];
    }
}

- (void)audioPlayerDidBeginInterruption:(MUPAudioPlayer *)playManager {
    
    if ([self.delegate respondsToSelector:@selector(muiAudioPlayManagerDidBeginInterruption:)]) {
        [self.delegate muiAudioPlayManagerDidBeginInterruption:self];
    }
}


@end
