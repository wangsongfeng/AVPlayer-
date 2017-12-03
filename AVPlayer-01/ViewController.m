//
//  ViewController.m
//  AVPlayer-01
//
//  Created by apple on 2017/12/2.
//  Copyright © 2017年 yangchao. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "ProgressSlider.h"
#import "Masonry.h"
@interface ViewController ()
@property(nonatomic,strong)AVPlayer * player;
@property(nonatomic,strong)AVPlayerLayer * playerLayer;

@property(nonatomic,strong)UIView * bottomView;
@property(nonatomic,strong)UIButton * playButton;
@property(nonatomic,strong)UILabel * timeLable;
@property(nonatomic,strong)ProgressSlider * slider;
@property(nonatomic,strong)CADisplayLink * link;
@property(nonatomic,assign)NSTimeInterval lastTime;
@end
// AVPlayer继承NSObject，所以单独使用AVP layer是无法显示视频的，必须把视图层添加到AVPlayerLayer中才能显示视频
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSURL * videoUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle]pathForResource:@"海贼王精彩剪辑" ofType:@"mp4"]];
    AVPlayerItem * playerItem = [AVPlayerItem playerItemWithURL:videoUrl];
    //添加status属性监听
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //监听loadedTimeRanges
    [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    self.player = [AVPlayer playerWithPlayerItem:playerItem];
    
    AVPlayerLayer * playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    playerLayer.contentsScale = [UIScreen mainScreen].scale;
    playerLayer.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    [self.view.layer addSublayer:playerLayer];
    self.playerLayer = playerLayer;
    //AVPlayer提供了一个Block回调，当播放进度改变的时候回主动回调该Block，但是当视频卡顿的时候是不会回调的，可以在该回调里面处理进度条以及播放时间的刷新，详细方法如下：
//    __weak __typeof(self) weakSelf = self;
//    [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
//        NSTimeInterval current = CMTimeGetSeconds(weakSelf.player.currentTime);
//        NSString * string1 = [weakSelf formatPlayTime:current];
//        NSLog(@"播放进度%@",string1);
//        
//        //视频的总长度
//        NSTimeInterval total = CMTimeGetSeconds(weakSelf.player.currentItem.duration);
//        NSString * string2 = [weakSelf formatPlayTime:total];
//        NSLog(@"总长度%@",string2);
//    }];
    self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(upadte)];
    [self.link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
    
    [self initSubView];

}

-(void)initSubView{
    self.bottomView = [[UIView alloc]initWithFrame:CGRectZero];
    self.bottomView.backgroundColor = [UIColor blackColor];
    self.bottomView.alpha = 0.5;
    self.bottomView.userInteractionEnabled = YES;
    [self.view addSubview:self.bottomView];
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(-(self.view.frame.size.height - 200 - 60));
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(60);
    }];
    
    //播放按钮
    self.playButton = [[UIButton alloc]initWithFrame:CGRectZero];
    [self.playButton setImage:[UIImage imageNamed:@"pauseBtn"] forState:UIControlStateNormal];
    [self.playButton setImage:[UIImage imageNamed:@"playBtn"] forState:UIControlStateSelected];
    [self.playButton addTarget:self action:@selector(playOrPauseAction:) forControlEvents:UIControlEventTouchUpInside];
    self.playButton.userInteractionEnabled = YES;
    self.playButton.enabled = NO;
    [self.bottomView addSubview:self.playButton];
    [self.playButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bottomView).offset(10);
        make.top.equalTo(self.bottomView).offset(10);
        make.bottom.equalTo(self.bottomView).offset(-10);
        make.width.mas_equalTo(self.playButton.mas_height);
    }];
    
    //时间
    self.timeLable = [[UILabel alloc]initWithFrame:CGRectZero];
    self.timeLable.text = @"00:00:00/00:00:00";
    self.timeLable.textColor = [UIColor whiteColor];
    self.timeLable.textAlignment = NSTextAlignmentRight;
    self.timeLable.font = [UIFont systemFontOfSize:14];
    [self.bottomView addSubview:self.timeLable];
    CGSize size = CGSizeMake(1000,10000);
    //计算实际frame大小，并将label的frame变成实际大小
    NSDictionary *attribute = @{NSFontAttributeName:self.timeLable.font};
    CGSize labelsize = [self.timeLable.text boundingRectWithSize:size options: NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:attribute context:nil].size;
    
    [self.timeLable mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.bottomView).offset(-10);
        make.top.equalTo(self.bottomView).offset(10);
        make.bottom.equalTo(self.bottomView).offset(-10);
        make.width.mas_equalTo(labelsize.width + 5);
    }];
    
    //滑块
    self.slider = [[ProgressSlider alloc] initWithFrame:CGRectZero direction:SliderDirectionHorizonal];
    [self.bottomView addSubview:self.slider];
    self.slider.enabled = NO;
    
    [self.slider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.playButton.mas_right).offset(10);
        make.right.equalTo(self.timeLable.mas_left).offset(-10);
        make.height.mas_equalTo(40);
        make.centerY.equalTo(self.bottomView);
    }];
    [self.slider addTarget:self action:@selector(progressValueChange:) forControlEvents:UIControlEventValueChanged];
    
    
}

- (void)playOrPauseAction:(UIButton *)sender{
    NSLog(@"点击了");
    sender.selected = !sender.selected;
    if (self.player.rate == 1) {
        [self.player pause];
        self.link.paused = YES;
    }else{
        [self.player play];
        self.link.paused = NO;
    }
}
//监听回调
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    AVPlayerItem * playerItem =(AVPlayerItem*)object;
   
    if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSTimeInterval loadedTime = [self availableDurationWithPlayerItem:playerItem];
        NSTimeInterval totalTime = CMTimeGetSeconds(playerItem.duration);
        
        if (!self.slider.isSliding) {
            self.slider.progressPercent = loadedTime/totalTime;
        }
//       NSTimeInterval result =  [self availableDurationWithPlayerItem:playerItem];
//        NSString * string = [self formatPlayTime:result];
//        NSLog(@"结果%@",string);
        
    }else if ([keyPath isEqualToString:@"status"]){
        if (playerItem.status == AVPlayerItemStatusReadyToPlay){
            [self.player play];
            //视频当前的播放进度
            self.slider.enabled = YES;
            self.playButton.enabled = YES;
            
        } else{
            NSLog(@"load break");
        }

    }
}
//处理滑块
- (void)progressValueChange:(ProgressSlider *)slider
{
    if (self.player.status == AVPlayerStatusReadyToPlay) {
        NSTimeInterval duration = self.slider.sliderPercent* CMTimeGetSeconds(self.player.currentItem.duration);
        CMTime seekTime = CMTimeMake(duration, 1);
        
        NSLog(@"时间%f",self.slider.sliderPercent);
        
        [self.player seekToTime:seekTime completionHandler:^(BOOL finished) {
            
        }];
    }
}

//更新方法
- (void)upadte
{
    NSTimeInterval current = CMTimeGetSeconds(self.player.currentTime);
    NSTimeInterval total = CMTimeGetSeconds(self.player.currentItem.duration);
    //如果用户在手动滑动滑块，则不对滑块的进度进行设置重绘
    if (!self.slider.isSliding) {
        self.slider.sliderPercent = current/total;
    }
    
    if (current!=self.lastTime) {
//        [self.activity stopAnimating];
        self.timeLable.text = [NSString stringWithFormat:@"%@/%@", [self formatPlayTime:current], isnan(total)?@"00:00:00":[self formatPlayTime:total]];
    }else{
//        [self.activity startAnimating];
    }
    self.lastTime = current;
    
}
//计算缓冲
-(NSTimeInterval)availableDurationWithPlayerItem:(AVPlayerItem*)playerItem{
    NSArray * loadedTimeRange = [playerItem loadedTimeRanges];
    
    CMTimeRange  timeRange = [loadedTimeRange.firstObject CMTimeRangeValue];
    NSTimeInterval startSecound  = CMTimeGetSeconds(timeRange.start);
//    NSLog(@"开始%f",startSecound);
    NSTimeInterval durationSecound = CMTimeGetSeconds(timeRange.duration);
//    NSLog(@"缓冲中%f",durationSecound);
    NSTimeInterval result = startSecound + durationSecound;
    
    NSString * string = [self formatPlayTime:result];
    NSLog(@"缓冲时间%@",string);
    return result;
   
    
}

//将时间转换成 00:00:00格式
-(NSString*)formatPlayTime:(NSTimeInterval)duration{
    int minute = 0,hour=0,second = duration;
    minute = (second % 3600)/60;
    hour = second / 3600;
    second = second % 60;
    
    return [NSString stringWithFormat:@"%02d:%02d:%02d",hour,minute,second];
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationLandscapeRight;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}


@end
