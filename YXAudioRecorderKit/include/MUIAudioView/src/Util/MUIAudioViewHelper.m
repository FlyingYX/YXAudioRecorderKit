//
//  UIModuleHelper.m
//  UIModule
//
//  Created by devp on 5/12/15.
//  Copyright (c) 2015 ND. All rights reserved.
//

#import "MUIAudioViewHelper.h"

#import <libextobjc/EXTScope.h>
#import <MUIKit/MUIKit.h>
#import <MUPAssetsKit/MUPAssetsKit.h>
#import <MUPFoundation/MUPFoundation.h>

@interface MUIAudioViewHelper ()

@end

@implementation MUIAudioViewHelper

#pragma mark - 换肤相关
+ (UIImage *)imageNamed:(NSString *)name {
    
    UIImage *image = [MUPSkin imageNamed:name componentID:MUI_AUDIO_COMPONENT_ID];
    return image;
}

+ (UIColor *)colorWithKey:(NSString *)key {
    
    UIColor *color = [MUPSkin colorWithKey:key componentID:MUI_AUDIO_COMPONENT_ID];
    if (nil == color) {
        
        color = [UIColor clearColor];
    }
    
    return color;
}

+ (UIFont *)fontWithKey:(NSString *)key {
    
    UIFont *font = [MUPSkin fontWithKey:key componentID:MUI_AUDIO_COMPONENT_ID];
    if (nil == font) {
        
        font = [UIFont systemFontOfSize:14];
    }
    return font;
}

/**
 *  根据key获取多语言翻译
 */
+ (NSString *)localizedStringWithKey:(NSString *)key {
    
    return [MUPI18nManager localizedStringWithKey:key componentID:MUI_AUDIO_COMPONENT_ID];
}

#pragma mark- audio

+ (NSString *)audioDirectoryPath {
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
	NSString *audioPath = [documentsPath stringByAppendingPathComponent:@"AudioTmp"];
	if (![fileManager fileExistsAtPath:audioPath]) {
		[fileManager createDirectoryAtPath:audioPath withIntermediateDirectories:NO attributes:nil error:nil];
	}
	return audioPath;
}

+ (NSString *)amrFilePathByName:(NSString *)name {
	
	return [NSString stringWithFormat:@"%@/%@.amr",[self audioDirectoryPath],name];
}

+ (NSString *)wavFilePathByName:(NSString *)name {
	
	return [NSString stringWithFormat:@"%@/%@.wav",[self audioDirectoryPath],name];
}

+(NSMutableAttributedString *)setDifferetTxt:(NSString *)string {
    
    
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:string];
    
    NSRange r =[MUIAudioViewHelper getNumRangeFromString:string];
    [attrString addAttribute:NSFontAttributeName
                       value:[MUIAudioViewHelper fontWithKey:@"character_3"]
                       range:r];
    
    [attrString addAttribute:NSForegroundColorAttributeName
                       value:[MUIAudioViewHelper colorWithKey:@"color_7"]
                       range:NSMakeRange(0,[string length])];
    
    return attrString;
}

+(NSRange)getNumRangeFromString:(NSString *)string{
    
    int alength = [string length];
    int star;
    int length = 0;
    BOOL numStar=NO;
    
    for (int i = 0; i<alength; i++) {
        
        char commitChar = [string characterAtIndex:i];
        
        //     if((commitChar>47)&&(commitChar<58)){
        if(isdigit(commitChar)){
            // NSLog(@"数字");
            if (numStar) {
                length++;
            }else{
                star=i;
            }
            
            numStar=YES;
            
        }else{
            // NSLog(@"非数字");
            numStar=NO;
        }
    }
    NSRange r;
    if (length>0) {
        r=NSMakeRange(star+1, length);
    }
    return r;
    
}

+ (NSString*)GetPathByFileName:(NSString *)fileName ofType:(NSString *)type{
    NSString *directory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
    NSString *audioPath = [directory stringByAppendingPathComponent:@"AudioTmp"];
    NSString* fileDirectory = [[[audioPath stringByAppendingPathComponent:fileName]
                                stringByAppendingPathExtension:type]
                               stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return fileDirectory;
}

@end
