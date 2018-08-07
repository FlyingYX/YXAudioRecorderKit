//
//  MUIAudio.h
//  Pods
//
//  Created by zhouwj on 15/11/25.
//
//

#import <Foundation/Foundation.h>

@interface MUIAudio : NSObject

//内容服务上音频id
@property (nonatomic, copy) NSString *audioId;

//本地音频路径
@property (nonatomic, copy) NSString *filePath;

//时长，单位毫秒
@property (nonatomic, assign) NSUInteger duration;

@property (nonatomic, assign) UInt64 size;

@end
