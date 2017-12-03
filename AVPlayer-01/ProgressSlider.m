//
//  ProgressSlider.m
//  AVPlayer-01
//
//  Created by apple on 2017/12/2.
//  Copyright © 2017年 yangchao. All rights reserved.
//

#import "ProgressSlider.h"
#define RGBColor(r,g,b,a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]
@interface ProgressSlider()
@property (nonatomic, strong) UIColor *lineColor;//整条线的颜色
@property (nonatomic, strong) UIColor *slidedLineColor;//滑动过的线的颜色
@property (nonatomic, strong) UIColor *progressLineColor;//预加载线的颜色
@property (nonatomic, strong) UIColor *circleColor;//圆的颜色

@property (nonatomic, assign) CGFloat lineWidth;//线的宽度
@property (nonatomic, assign) CGFloat circleRadius;//圆的半径
@end

@implementation ProgressSlider

-(id)initWithFrame:(CGRect)frame direction:(SliderDirection)direction{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        
        _minValue = 0;
        _maxValue = 1;
        
        _direction = direction;
        _lineColor = [UIColor whiteColor];
        _slidedLineColor = RGBColor(254, 64, 22, 1);
        _circleColor = RGBColor(254, 64, 22, 1);
        _progressLineColor = [UIColor grayColor];
        
        _sliderPercent = 0.0;
        _lineWidth = 2;
        _circleRadius = 8;
        
    }
    
    return self;
}

-(void)drawRect:(CGRect)rect{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //画总体的线
    CGContextSetStrokeColorWithColor(context, _lineColor.CGColor);
    //线的宽度
    CGContextSetLineWidth(context, _lineWidth);
    
    CGFloat startLineX = (_direction==SliderDirectionHorizonal? _circleRadius : (self.frame.size.width-_lineWidth)/2);
    CGFloat startLineY = (_direction == SliderDirectionHorizonal? (self.frame.size.height - _lineWidth)/2 : _circleRadius);
    
    CGFloat endLineX = (_direction == SliderDirectionHorizonal ? self.frame.size.width - _circleRadius :(self.frame.size.width-_lineWidth)/2);
    CGFloat endLineY = (_direction == SliderDirectionHorizonal? (self.frame.size.height - _lineWidth) / 2 : self.frame.size.height- _circleRadius);
    
    CGContextMoveToPoint(context, startLineX, startLineY);
    CGContextAddLineToPoint(context, endLineX, endLineY);
    
    CGContextClosePath(context);
    CGContextStrokePath(context);
    
    
    //画已滑动进度的线
    CGContextSetStrokeColorWithColor(context, _slidedLineColor.CGColor);
    CGContextSetLineWidth(context, _lineWidth);
    
    CGFloat slidedlineX = (_direction == SliderDirectionHorizonal ? MAX(_circleRadius, (_sliderPercent * (self.frame.size.width -2 * _circleRadius) + _circleRadius)) : startLineX);
    CGFloat slidedLineY = (_direction == SliderDirectionHorizonal ? startLineY : MAX(_circleRadius, (_sliderPercent * self.frame.size.height - _circleRadius)));
    CGContextMoveToPoint(context, startLineX, startLineY);
    CGContextAddLineToPoint(context, slidedlineX, slidedLineY);
    CGContextClosePath(context);
    CGContextStrokePath(context);
    
    //画圆，外层
    CGFloat penWidth = 1.f;
    CGContextSetStrokeColorWithColor(context, _circleColor.CGColor);
    CGContextSetLineWidth(context, penWidth);
    
    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    CGContextSetShadow(context, CGSizeMake(1, 1), 1.f);
    
    CGFloat circleX = (_direction == SliderDirectionHorizonal ? MAX(_circleRadius + penWidth, slidedlineX - penWidth) : startLineX);
    CGFloat circleY = (_direction == SliderDirectionHorizonal ? startLineY : MAX(_circleRadius+penWidth, slidedLineY - penWidth));
    CGContextAddArc(context, circleX, circleY, _circleRadius, 0, 2*M_PI, 0);
    CGContextDrawPath(context, kCGPathFillStroke);
    
    //内层的圆
    
    CGContextSetStrokeColorWithColor(context, nil);
    CGContextSetLineWidth(context, 0);
    CGContextSetFillColorWithColor(context, _circleColor.CGColor);
    CGContextAddArc(context, circleX, circleY, _circleRadius / 2, 0, 2 * M_PI, 0);
    CGContextDrawPath(context, kCGPathFillStroke);
    
}
-(void)touchesBegan:(NSSet*)touches withEvent:(UIEvent *)event{
    if (!self.enabled) {
        return;
    }
    [self updataTouchPoint:touches];
    [self callbackTouchEnd:NO];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    if (!self.enabled) {
        return;
    }
    [self updataTouchPoint:touches];
    [self callbackTouchEnd:NO];
}
-(void)touchesEnded:(NSSet*)touches withEvent:(UIEvent *)event{
    if (!self.enabled) {
        return;
    }
    [self updataTouchPoint:touches];
    [self callbackTouchEnd:YES];
}

-(void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent *)event{
    if (!self.enabled) {
        return;
    }
    [self updataTouchPoint:touches];
    [self callbackTouchEnd:YES];
}

//更新进度条
-(void)updataTouchPoint:(NSSet*)touches{
    CGPoint touchPoint = [[touches anyObject]locationInView:self];
    self.sliderPercent = (_direction == SliderDirectionHorizonal ? touchPoint.x : touchPoint.y) / (_direction == SliderDirectionHorizonal ? self.frame.size.width : self.frame.size.height);
    NSLog(@"wawa%f",self.sliderPercent);

}

-(void)setSliderPercent:(CGFloat)sliderPercent{
    if (_sliderPercent != sliderPercent) {
        _sliderPercent = sliderPercent;
        self.value = _minValue + sliderPercent * (_maxValue - _minValue);
    }
}

-(void)setProgressPercent:(CGFloat)progressPercent{
    if (_progressPercent != progressPercent) {
        _progressPercent = progressPercent;
        [self setNeedsDisplay];
    }
}

-(void)setValue:(CGFloat)value{
    if (value != _value) {
        if (value < _minValue) {
            _value = _minValue;
            return;
        }else if (value > _maxValue){
            _value = _maxValue;
            return;
        }
        _value = value;
        _sliderPercent = (_value - _minValue) / (_maxValue - _minValue);
        [self setNeedsDisplay];
    }
}

- (void)callbackTouchEnd:(BOOL)isTouchEnd {
    _isSliding = !isTouchEnd;
    if (isTouchEnd == YES) {
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}




@end
