//
//  MUIEditAudioPlayProgressView.m
//  MUIAudioView
//
//  Created by lxh on 16/7/28.
//  Copyright © 2016年 ND. All rights reserved.
//

#import "MUIEditAudioPlayProgressView.h"
#import "MUIAudioViewHelper.h"

@interface MUIEditAudioPlayProgressView ()

@property(nonatomic, assign) CGFloat percent;

@end

@implementation MUIEditAudioPlayProgressView

- (void)drawRect:(CGRect)rect {
    
    if (self.percent >= 100) {
        return;
    }
    
    CGContextRef myContext = UIGraphicsGetCurrentContext();
    
    CGRect imageRect = CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
    
    CGColorRef color = [MUIAudioViewHelper colorWithKey:@"mui_audio_edit_play_duration_color"].CGColor;
    CGContextSetStrokeColorWithColor(myContext, color);
    CGContextSetLineWidth(myContext, 4);
    
    CGContextAddArc(myContext,
                    CGRectGetMidX(imageRect),
                    CGRectGetMidY(imageRect),
                    CGRectGetWidth(imageRect) / 2 - 2,
                    -M_PI / 2,
                    -M_PI / 2 + 2 *
                    M_PI * self.percent / 100.0, 0);
    CGContextStrokePath(myContext);
}

- (void)updatePlayerPercent:(CGFloat)percent {
    
    self.percent = percent * 100;
    
    [self setNeedsDisplay];
}

@end
