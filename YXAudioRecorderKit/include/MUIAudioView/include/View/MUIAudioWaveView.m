//
//  MUIAudioWaveView.m
//  selfInBlock
//
//  Created by Bruce on 15/12/4.
//  Copyright © 2015年 Bruce. All rights reserved.
//

#import "MUIAudioWaveView.h"
#import <objc/runtime.h>

@interface MUIAudioWaveView ()

@property (nonatomic, strong) NSMutableArray *heightArray;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSTimeInterval moveTime;

@end

@implementation MUIAudioWaveView {
	int index;
}

- (instancetype)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		[self commonInit];
	}
	return self;
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		[self commonInit];
	}
	return self;
}
- (void)commonInit
{
	self.userInteractionEnabled = NO;
	self.backgroundColor = [UIColor clearColor];
	self.waveColor = [UIColor colorWithRed:0 green:0.65 blue:1 alpha:1];
	_refreshInterval = 0.015;
	_waveCrestDistance = 120;
	_soundVolume = 0.5;
    _waveWidth = 1.5;
    _waveSpace = 1;
}

#pragma mark - set 20170706 lc add
- (void)setWaveCrestDistance:(double)waveCrestDistance {
    
    if (waveCrestDistance == 0 || _waveCrestDistance == waveCrestDistance) {
        return;
    }
    _waveCrestDistance = waveCrestDistance;
}

- (void)setWaveWidth:(CGFloat)waveWidth {
    
    if (waveWidth == 0 || waveWidth == _waveWidth) {
        return;
    }
    _waveWidth = waveWidth;
}

- (void)setWaveSpace:(CGFloat)waveSpace {
    if (waveSpace == 0 || waveSpace == _waveSpace) {
        return;
    }
    _waveSpace = waveSpace;
}

- (void)setRefreshInterval:(NSTimeInterval)refreshInterval {
    
    if (refreshInterval == 0 || refreshInterval == _refreshInterval) {
        return;
    }
    _refreshInterval = refreshInterval;
}

- (void)setSoundVolume:(double)soundVolume {
    
    if (soundVolume <= 0 || soundVolume > 1 || soundVolume == _soundVolume) {
        return;
    }
    _soundVolume = soundVolume;
}

#pragma mark - 给出一个初始化波形图 20170706 lc add
- (void)ceateDefaultWave {
    
    [self layoutIfNeeded];
    
    if (self.heightArray == nil) {
        self.heightArray = [NSMutableArray array];
        NSUInteger count = 0;
        switch (self.waveDirectionType) {
            case MUIAudioWaveDerectionType_LeftToRight:
            case MUIAudioWaveDerectionType_RightToLeft:{
                count = self.bounds.size.width;
            }
                break;
            default:
                count = (self.bounds.size.width - self.leftRightDistance) / 2;
                break;
        }
        for (int i = 0; i < count; i++) {
            [self.heightArray addObject:@(0)];
        }
        
        for (int i = 0; i < count; i++) {
            self.moveTime += self.refreshInterval;
            NSNumber *heightNumber = nil;
            if (index % 4 == 0) {
                double phase = self.moveTime / self.refreshInterval * M_PI / self.waveCrestDistance;
                double height = self.bounds.size.height * (1.01 - MAX(fabs(sin(phase)), fabs(sin(phase - M_PI / 2.3))));
                heightNumber = [NSNumber numberWithDouble:height];
                objc_setAssociatedObject(heightNumber, "isFirstOfFour", @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            } else {
                heightNumber = [NSNumber numberWithDouble:0];
            }
            
            [self.heightArray removeObjectAtIndex:0];
            [self.heightArray addObject:heightNumber];
            index ++;
            [self setNeedsDisplay];
        }
        
    }
}

#pragma mark - 波形动画播放
- (void)pause {
	if (self.timer) {
		[self.timer invalidate];
		self.timer = nil;
	}
}

- (void)start {
	[self pause];
	
	[self layoutIfNeeded];
	
	if (self.heightArray == nil) {
		self.heightArray = [NSMutableArray array];
        NSUInteger count = 0;
        //增加波形动画输出方向 lc 20170706 add
        switch (self.waveDirectionType) {
            case MUIAudioWaveDerectionType_LeftToRight:
            case MUIAudioWaveDerectionType_RightToLeft:{
                count = self.bounds.size.width;
            }
                break;
            default:
                count = (self.bounds.size.width - self.leftRightDistance) / 2;
                break;
        }
		for (int i = 0; i < count; i++) {
			[self.heightArray addObject:@(0)];
		}
	}

	self.timer = [NSTimer scheduledTimerWithTimeInterval:self.refreshInterval target:self selector:@selector(updateView) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
	[self.timer fire];
}
- (void)reStart {
	[self pause];
	
	self.moveTime = 0;
	self.heightArray = nil;
	[self start];
}

#pragma mark - 界面更新
- (void)updateView {
    
	self.moveTime += self.refreshInterval;
	NSNumber *heightNumber = nil;
	if (index % 4 == 0) {
		double phase = self.moveTime / self.refreshInterval * M_PI / self.waveCrestDistance;
		double height = self.bounds.size.height * (1.01 - MAX(fabs(sin(phase)), fabs(sin(phase - M_PI / 2.3))));
		heightNumber = [NSNumber numberWithDouble:height];
		objc_setAssociatedObject(heightNumber, "isFirstOfFour", @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	} else {
		heightNumber = [NSNumber numberWithDouble:0];
	}
	
	[self.heightArray removeObjectAtIndex:0];
	[self.heightArray addObject:heightNumber];

	[self setNeedsDisplay];
	index ++;
}

- (void)drawRect:(CGRect)rect {
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGContextSetFillColorWithColor(context,self.waveColor.CGColor);
    
	[self.heightArray enumerateObjectsUsingBlock:^(NSNumber *heightNumber, NSUInteger idx, BOOL *stop) {
		if ([objc_getAssociatedObject(heightNumber, "isFirstOfFour") boolValue]) {
			
			CGFloat centerY = rect.size.height / 2;
            //增加波形输出方向相对应绘制 lc 20170706 modify
            switch (self.waveDirectionType) {
                case MUIAudioWaveDerectionType_RightToLeft:
                {
                    CGContextAddRect(context, CGRectMake(idx * self.waveSpace, centerY- [heightNumber doubleValue] * self.soundVolume, self.waveWidth, 2 * [heightNumber doubleValue] * self.soundVolume));
                    CGContextFillPath(context);
                    CGContextFillEllipseInRect(context, CGRectMake(idx * self.waveSpace, centerY - [heightNumber doubleValue] * self.soundVolume - 0.75, self.waveWidth, self.waveWidth));
                    CGContextFillEllipseInRect(context, CGRectMake(idx * self.waveSpace, centerY + [heightNumber doubleValue] * self.soundVolume - 0.75, self.waveWidth, self.waveWidth));
                    CGContextFillPath(context);
                }
                    break;
                case MUIAudioWaveDerectionType_LeftToRight: {
                    
                    CGContextAddRect(context, CGRectMake(rect.size.width - idx * self.waveSpace, centerY- [heightNumber doubleValue] * self.soundVolume, self.waveWidth, 2 * [heightNumber doubleValue] * self.soundVolume));
                    CGContextFillPath(context);
                    CGContextFillEllipseInRect(context, CGRectMake(rect.size.width - idx * self.waveSpace, centerY - [heightNumber doubleValue] * self.soundVolume - 0.75, self.waveWidth, self.waveWidth));
                    CGContextFillEllipseInRect(context, CGRectMake(rect.size.width - idx * self.waveSpace, centerY + [heightNumber doubleValue] * self.soundVolume - 0.75, self.waveWidth, self.waveWidth));
                    CGContextFillPath(context);
                }
                    break;
                default:
                {
                    CGContextAddRect(context, CGRectMake(idx * self.waveSpace, centerY- [heightNumber doubleValue] * self.soundVolume, self.waveWidth, 2 * [heightNumber doubleValue] * self.soundVolume));
                    CGContextFillPath(context);
                    CGContextFillEllipseInRect(context, CGRectMake(idx * self.waveSpace, centerY - [heightNumber doubleValue] * self.soundVolume - 0.75, self.waveWidth, self.waveWidth));
                    CGContextFillEllipseInRect(context, CGRectMake(idx * self.waveSpace, centerY + [heightNumber doubleValue] * self.soundVolume - 0.75, self.waveWidth, self.waveWidth));
                    CGContextFillPath(context);
                    
                    
                    CGContextAddRect(context, CGRectMake(rect.size.width - idx * self.waveSpace, centerY- [heightNumber doubleValue] * self.soundVolume, self.waveWidth, 2 * [heightNumber doubleValue] * self.soundVolume));
                    CGContextFillPath(context);
                    CGContextFillEllipseInRect(context, CGRectMake(rect.size.width - idx * self.waveSpace, centerY - [heightNumber doubleValue] * self.soundVolume - 0.75, self.waveWidth, self.waveWidth));
                    CGContextFillEllipseInRect(context, CGRectMake(rect.size.width - idx * self.waveSpace, centerY + [heightNumber doubleValue] * self.soundVolume - 0.75, self.waveWidth, self.waveWidth));
                    CGContextFillPath(context);
                }
                    break;
            }
		}
	}];
}


@end
