//
//  UIModuleHelper.h
//  UIModule
//
//  Created by devp on 5/12/15.
//  Copyright (c) 2015 ND. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define MUI_AUDIO_SANDBOX_DOMAIN  @"mui.audio.sandbox.domain"   //sandbox 的 domain

#define MUI_AUDIO_COMPONENT_ID    @"com.nd.social.mui-audio"

#undef NSLocalizedString
#define NSLocalizedString(key) \
[MUIAudioViewHelper localizedStringWithKey:key]


@interface MUIAudioViewHelper : NSObject

#pragma mark - 换肤相关

+ (UIImage *)imageNamed:(NSString *)name;

+ (UIColor *)colorWithKey:(NSString *)key;

+ (UIFont *)fontWithKey:(NSString *)key;

+ (NSString *)localizedStringWithKey:(NSString *)key;

#pragma mark - audio

+ (NSString *)amrFilePathByName:(NSString *)name;

+ (NSString *)wavFilePathByName:(NSString *)name;


+(NSMutableAttributedString *)setDifferetTxt:(NSString *)string ;

+(NSRange)getNumRangeFromString:(NSString *)string;

+ (NSString*)GetPathByFileName:(NSString *)fileName ofType:(NSString *)type;


@end
