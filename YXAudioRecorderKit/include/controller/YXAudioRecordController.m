//
//  YXAudioRecordController.m
//  YXAudioRecorderKit
//
//  Created by yuxiang on 2018/6/6.
//  Copyright © 2018年 ND. All rights reserved.
//

#import "YXAudioRecordController.h"
#import "MUIEditAudioRecordView.h"
#import "MUIEditAudioNewRecordView.h"
#import <Masonry/Masonry.h>
#import <APFUIKit/MUPAudioUtility.h>

COAudioRecordControllerKey const COAudioRecordControllerMinimumDurationKey = @"COAudioRecordControllerMinimumDurationKey";
COAudioRecordControllerKey const COAudioRecordControllerMaximumDurationKey = @"COAudioRecordControllerMaximumDurationKey";
COAudioRecordControllerKey const COAudioRecordControllerFileSaveDirectoryKey = @"COAudioRecordControllerFileSaveDirectoryKey";
COAudioRecordControllerKey const COAudioRecordControllerFileSaveNameKey = @"COAudioRecordControllerFileSaveNameKey";
COAudioRecordControllerKey const COAudioRecordControllerIfConvertAmrFileKey = @"COAudioRecordControllerIfConvertAmrFileKey";


@interface CRAudioRecordViewTransition : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign) BOOL isPresenting;

@end


@interface YXAudioRecordController () <UIViewControllerTransitioningDelegate, MUIEditAudioRecordViewDelegate>

@property (nonatomic, strong) NSDictionary<COAudioRecordControllerKey,id> *settings;

@property (nonatomic, copy) NSString *fileDirectory;//录音文件存储目录
@property (nonatomic, copy) NSString *fileName;//录音文件名称
@property (nonatomic) BOOL needAmrFile;//是否要转换amr文件
@property (nonatomic, copy) void (^completionHandler)(NSURL *, NSURL *, NSError *);

@property (nonatomic, strong) UIView *backView;
@property (nonatomic, strong) MUIEditAudioRecordView *audioRecordView;

@end


@implementation CRAudioRecordViewTransition

- (void)dealloc {
    MUPLogDebug(@"");
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    UIViewController *fromController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    if (toController.isBeingPresented) {
        return 0.3f;
    }
    else if (fromController.isBeingDismissed) {
        return 0.2f;
    }
    return 0.25f;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    UIViewController *fromController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    if (!fromController || !toController) {
        return;
    }
    UIView *containerView = [transitionContext containerView];
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    
    if (toController.isBeingPresented) {
       
        YXAudioRecordController *audioRecordController = (YXAudioRecordController *)toController;
        audioRecordController.view.frame = containerView.bounds;
        audioRecordController.backView.alpha = 0.0;
        audioRecordController.audioRecordView.alpha = 0.0;
        [containerView addSubview:audioRecordController.view];
    
        [UIView animateWithDuration:duration animations:^{
            audioRecordController.backView.alpha = 0.3f;
            audioRecordController.audioRecordView.alpha = 1.0f;
            
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }];
    }
    else if (fromController.isBeingDismissed) {
        
        YXAudioRecordController *audioRecordController = (YXAudioRecordController *)fromController;
        
        [UIView animateWithDuration:duration animations:^{
            audioRecordController.backView.alpha = 0.0;
            audioRecordController.audioRecordView.alpha = 0.0;
            
        } completion:^(BOOL finished) {
            
            [audioRecordController.audioRecordView close];
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }];
    }
}


@end


@implementation YXAudioRecordController

+ (instancetype)audioRecordControllerWithSettings:(NSDictionary<COAudioRecordControllerKey,id> *)settings
                                completionHandler:(nullable void (^)(NSURL * _Nullable, NSURL * _Nullable, NSError * _Nullable))completionHandler {
    
    YXAudioRecordController *audioRecordController = [[YXAudioRecordController alloc] init];
    audioRecordController.settings = settings.copy;
    audioRecordController.completionHandler = completionHandler;
    return audioRecordController;
}

- (instancetype)init {
    
    self = [super init];
    if (self) {
        
        self.modalPresentationStyle = UIModalPresentationCustom;
        self.transitioningDelegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.needAmrFile = NO;
    if (self.settings) {
        NSString *directory = [self.settings valueForKey:COAudioRecordControllerFileSaveDirectoryKey];
        if (directory && [directory isKindOfClass:[NSString class]] && directory.length > 0) {
            self.fileDirectory = directory;
        }
        NSString *fileName = [self.settings valueForKey:COAudioRecordControllerFileSaveNameKey];
        if (fileName && [fileName isKindOfClass:[NSString class]] && fileName.length > 0) {
            self.fileName = fileName;
        }
        NSNumber *needAmrFile = [self.settings valueForKey:COAudioRecordControllerIfConvertAmrFileKey];
        if (needAmrFile && [needAmrFile isKindOfClass:[NSNumber class]]) {
            self.needAmrFile = needAmrFile.boolValue;
        }
    }
    self.view.backgroundColor = [UIColor clearColor];
    [self initSubviews];
}

- (void)dealloc {
    MUPLogDebug(@"YXAudioRecordController Dealloc");
}

- (void)recordSuccessWavFile:(NSURL *)wavfileURL amrFile:(NSURL *)amrfileURL {
    
    if (self.completionHandler) {
        self.completionHandler(wavfileURL, amrfileURL, nil);
    }
    [self dismissController:nil];
}

- (void)recordFailure:(NSError *)error {
    
    if (self.completionHandler) {
        self.completionHandler(nil, nil, error);
    }
    [self dismissController:nil];
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    
    CRAudioRecordViewTransition *transition = [[CRAudioRecordViewTransition alloc]init];
    transition.isPresenting = YES;
    return transition;
}


- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    
    CRAudioRecordViewTransition *transition = [[CRAudioRecordViewTransition alloc]init];
    transition.isPresenting = NO;
    return transition;
}

#pragma mark - MUIEditAudioRecordViewDelegate

- (void)MUIEditRecordViewDidEndRecord:(MUIAudio *)audio {
    
    [self.audioRecordView close];
    if (audio && audio.filePath) {
        
        NSString *filePath = audio.filePath;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        //录音文件是否存在
        BOOL isDir = NO;
        BOOL isFileExisted = [fileManager fileExistsAtPath:filePath isDirectory:&isDir];
        if (!isDir && isFileExisted) {
            
            //移动文件
            if (self.fileDirectory || self.fileName) {
                
                NSString *fileDir = [filePath stringByDeletingLastPathComponent];
                NSString *fileName = [filePath.lastPathComponent stringByDeletingPathExtension];
                NSString *fileExtension = filePath.pathExtension;
                
                if (self.fileDirectory) {
                    
                    BOOL isFileDir = NO;
                    BOOL isFileDirExisted = [fileManager fileExistsAtPath:self.fileDirectory isDirectory:&isFileDir];
                    if (!isFileDirExisted) {
                        NSError *createDirError;
                        BOOL createDirSuccess = [fileManager createDirectoryAtPath:self.fileDirectory withIntermediateDirectories:YES attributes:nil error:&createDirError];
                        if (!createDirSuccess) {
                            [self recordFailure:createDirError];
                            return;
                        }
                    }
                    fileDir = self.fileDirectory;
                }
                if (self.fileName) {
                    fileName = self.fileName;
                }
                
                NSString *targetFilePath = [[fileDir stringByAppendingPathComponent:fileName] stringByAppendingPathExtension:fileExtension];
                //移除目标路径可能存在的同名文件
                NSError *removeError;
                BOOL removeSuccess = [fileManager removeItemAtPath:targetFilePath error:&removeError];
                if (removeSuccess) {
                }
                
                NSError *moveError;
                BOOL moveSuccess = [fileManager moveItemAtPath:filePath toPath:targetFilePath error:&moveError];
                if (moveSuccess) {
                    filePath = targetFilePath;
                }else {
                    [self recordFailure:moveError];
                    return;
                }
            }
            NSURL *fileURL = [NSURL fileURLWithPath:filePath isDirectory:NO];
            
            //转换amr文件
            NSURL *amrFileURL;
            if (self.needAmrFile) {
                amrFileURL = [[fileURL URLByDeletingPathExtension] URLByAppendingPathExtension:@"amr"];
                NSError *removeError;
                BOOL removeSuccess = [fileManager removeItemAtURL:amrFileURL error:&removeError];
                if (removeSuccess) {
                }
                [MUPAudioUtility convertWavFile:fileURL toAmrFile:amrFileURL error:nil];
            }
            [self recordSuccessWavFile:fileURL amrFile:amrFileURL];
            
        }else {
            
            [self recordFailure:[NSError errorWithDomain:@"com.nd.cloudoffice" code:0 userInfo:@{NSLocalizedDescriptionKey: @"录音文件获取失败"}]];
        }
    
    }else {
        
        //放弃录音（控件放弃录音居然是在完成录音里操作的）
        [self dismissController:nil];
    }
}

- (void)MUIEditRecordViewDidRerecord {
}

- (void)MUIEditRecordViewDidBeginRecord {
}

- (void)MUIEditRecordViewFailRecord:(NSError *)error {
    
    [self recordFailure:error];
}

- (void)MUIEditRecordViewBeginInterruption {
}

- (void)muiEditRecordViewBeingEndRecord {
    
}

- (void)muiEditRecordViewDrageCancleRecord {
    
}

//- muied

#pragma mark - Private

- (void)initSubviews {
    
    UIView *backView = [[UIView alloc]initWithFrame:self.view.bounds];
    backView.backgroundColor = [UIColor blackColor];
    backView.alpha = 0.3f;
    [self.view addSubview:backView];
    self.backView = backView;
    
    [self.backView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dismissController:)];
    [self.backView addGestureRecognizer:tap];
    
    MUIEditAudioRecordView *audioRecordView = [[MUIEditAudioRecordView alloc] init];
    audioRecordView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 280);
    audioRecordView.delegate = self;
    audioRecordView.controller = self;
    audioRecordView.minimumDuration = 1;
    audioRecordView.maximumDuration = 120;
    [self.view addSubview:audioRecordView];
    self.audioRecordView = audioRecordView;
    
    if (self.settings) {
        NSNumber *minDuration = [self.settings valueForKey:COAudioRecordControllerMinimumDurationKey];
        if (minDuration && [minDuration isKindOfClass:[NSNumber class]]) {
            self.audioRecordView.minimumDuration = minDuration.doubleValue;
        }
        NSNumber *maxDuration = [self.settings valueForKey:COAudioRecordControllerMaximumDurationKey];
        if (maxDuration && [maxDuration isKindOfClass:[NSNumber class]]) {
            self.audioRecordView.maximumDuration = maxDuration.doubleValue;
        }
    }
    
    [audioRecordView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(280);
        //MUIEditAudioRecordView 内部录音结束蒙板位置导致只能加载在这里
        make.bottom.equalTo(self.view.mas_bottom);
        /*
        if (@available(iOS 11.0, *)) {
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        } else {
            make.bottom.equalTo(self.mas_bottomLayoutGuide);
        }
         */
        
        
    }];
    
}

- (void)dismissController:(UITapGestureRecognizer *)tap {
    
    //[self.audioRecordView close];
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
