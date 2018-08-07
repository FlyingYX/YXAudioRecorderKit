//
//  MUIAudioLoadWaveView.h
//  Pods
//
//  Created by zhouwj on 15/12/2.
//
//

#import "MUIAudioLoadWaveView.h"
#import <Masonry/Masonry.h>


@interface MUIAudioLoadWaveView()

@property(nonatomic,strong) UIBezierPath* wavePath;
@property(atomic,strong) NSMutableArray *bezerPointArrays;
@property(nonatomic,assign) float waveHeight;
@property(nonatomic,assign) float waveWidth;
@property(nonatomic,assign) float realY;
@property(nonatomic,assign) int numWave;
@property(nonatomic,assign) float moveLength;
@property(nonatomic,strong) NSTimer *mTimer;
@property(nonatomic,strong) UIImageView *imageView;

@property(nonatomic,strong) CAShapeLayer *waveLayer;

@end

@implementation MUIAudioLoadWaveView

- (void)dealloc{
    [self.mTimer invalidate];
}

- (instancetype)init{
	
	self = [super init];
    if(self){
		[self initWaveView];
    }
    return self;
}

- (void)initWaveView{
    self.wavePath = [[UIBezierPath alloc] init];
    self.bezerPointArrays = [[NSMutableArray alloc] init];
    self.moveLength = 0;
    self.waveLayer = [[CAShapeLayer alloc] init];
    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor clearColor];
	
    self.imageView = [[UIImageView alloc] init];
    self.imageView.clipsToBounds = YES;
    [self addSubview:self.imageView];
    [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(self);
    }];
}

- (void)layoutSubviews{
    [super layoutSubviews];
	
	self.imageView.image = self.image;
   
    self.waveHeight = CGRectGetWidth(self.frame)/2.5;
    self.realY = CGRectGetHeight(self.frame)-self.waveHeight/2;
    self.waveWidth = CGRectGetWidth(self.frame)*2;
    self.numWave = (int)round(CGRectGetWidth(self.frame)/self.waveWidth+0.5);
    
    [self resetKeyPoint];
    
    self.waveLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
    self.layer.mask = self.waveLayer;
}

- (void)startAminiation{
    [self resetKeyPoint];
    if(self.mTimer != nil){
        [self.mTimer invalidate];
    }
    self.mTimer = [NSTimer timerWithTimeInterval:0.03 target:self selector:@selector(drawBeazerPath) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.mTimer forMode:NSRunLoopCommonModes];
}

- (void)stopAminiation{
    [self.mTimer invalidate];
}

- (void)drawBeazerPath {
    
    [self.wavePath removeAllPoints];
    
    CGPoint point = [self.bezerPointArrays[0] CGPointValue];
    [self.wavePath moveToPoint:point];
    int i = 0;
    
    CGPoint ctlPoint,targetPoint;
    for( ;i<[self.bezerPointArrays count]-2;i=i+2){
        ctlPoint = [self.bezerPointArrays[i+1] CGPointValue];
        targetPoint = [self.bezerPointArrays[i+2] CGPointValue];
        [self.wavePath addQuadCurveToPoint:targetPoint
                              controlPoint:ctlPoint];
    }
    
    CGPoint endPoint = [self.bezerPointArrays[i] CGPointValue];
    
    [self.wavePath addLineToPoint:CGPointMake(endPoint.x,self.frame.size.height)];
    [self.wavePath addLineToPoint:CGPointMake(point.x,CGRectGetHeight(self.frame))];
    [self.wavePath closePath];
    self.waveLayer.path = self.wavePath.CGPath;
    
    [self updateMove];
}

- (void)updateMove{
    self.moveLength += 2.0f;
    if(_moveLength >= self.waveWidth){
        _moveLength = 0;
        return;
    }
    [self generateBezerArray];
}

- (void)resetKeyPoint{
    _moveLength = 0;
    self.progress = 0.0f;
    [self.bezerPointArrays removeAllObjects];
    [self generateBezerArray];
}

- (void)generateBezerArray{
    
    BOOL isCreateModel = ([self.bezerPointArrays count] == 0);
	
    for(int i=0;i<(4*_numWave+5);i++){
        float pointX = i*_waveWidth/4-_waveWidth+_moveLength;
        float pointY = 0;
        switch (i%4) {
            case 0:
            case 2:{
                pointY = (1-self.progress)*self.realY;
                break;
            }
            case 1:{
                pointY = (1-self.progress)*self.realY+_waveHeight;
                break;
            }
            case 3:{
                pointY = (1-self.progress)*self.realY-_waveHeight;
                break;
            }
            default:{
                break;
            }
        }
        
        if(isCreateModel){
            [self.bezerPointArrays addObject:[NSValue valueWithCGPoint:CGPointMake(pointX, pointY)]];
        }else{
            self.bezerPointArrays[i] = [NSValue valueWithCGPoint:CGPointMake(pointX, pointY)];
        }
    
    }
}

@end
