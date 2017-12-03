//
//  ProgressSlider.h
//  AVPlayer-01
//
//  Created by apple on 2017/12/2.
//  Copyright © 2017年 yangchao. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, SliderDirection) {
    SliderDirectionHorizonal = 0,
    SliderDirectionVertical = 1
};

@interface ProgressSlider : UIControl

@property(nonatomic,assign)CGFloat minValue;//最小值
@property(nonatomic,assign)CGFloat maxValue;//最大值
@property(nonatomic,assign)CGFloat value;//滑动值
@property(nonatomic,assign)CGFloat sliderPercent;//滑动百分比
@property(nonatomic,assign)CGFloat progressPercent;//缓冲百分比

@property (nonatomic, assign) BOOL isSliding;//是否正在滑动  如果在滑动的是偶外面监听的回调不应该设置sliderPercent progressPercent 避免绘制混乱

@property(nonatomic,assign)SliderDirection direction;

-(id)initWithFrame:(CGRect)frame direction:(SliderDirection)direction;
@end
