//
//  HUDAudioView.m
//  HUDAudioManager
//
//  Created by meterwhite on 2018/10/9.
//  Copyright © 2018年 meterwhite. All rights reserved.
//

#import "HUDAudioView.h"

@interface HUDAudioView ()

@end

@implementation HUDAudioView

+ (void)initialize {
    if(self != HUDAudioView.class) return;
    self.hudBGColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
    self.hudWarningColor = [UIColor colorWithRed:186 green:60 blue:65 alpha:1];
    CGFloat w_screen = UIScreen.mainScreen.bounds.size.width;
    self.hudSize = CGSizeMake(w_screen * 0.4, w_screen * 0.4);
    self.hudInnerMargin = 8;
}

+ (UIImage *)imageNamed:(NSString *)name {
    NSString *p = [[NSBundle mainBundle] pathForResource:@"HUDAudio" ofType:@"bundle"] == nil ? ([[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"Frameworks/HUDAudioManager.framework/HUDAudio.bundle"] stringByAppendingPathComponent:name]) : ([[[NSBundle mainBundle] pathForResource:@"HUDAudio" ofType:@"bundle"] stringByAppendingPathComponent:name]);
    return [UIImage imageNamed:p];
}

- (id)init {
    self = [super init];
    if(self){
        [self setupViews];
        [self defaultLayout];
    }
    return self;
}

- (void)setupViews {
    self.backgroundColor = [UIColor clearColor];

    _background = [[UIView alloc] init];
    _background.backgroundColor = HUDAudioView.hudBGColor;
    _background.layer.cornerRadius = 5;
    [_background.layer setMasksToBounds:YES];
    [self addSubview:_background];

    _recordImage = [[UIImageView alloc] init];
    _recordImage.image = [HUDAudioView imageNamed:@"record_1"];
    _recordImage.alpha = 0.8;
    _recordImage.contentMode = UIViewContentModeCenter;
    [_background addSubview:_recordImage];

    _title = [[UILabel alloc] init];
    _title.font = [UIFont systemFontOfSize:14];
    _title.textColor = [UIColor whiteColor];
    _title.textAlignment = NSTextAlignmentCenter;
    _title.layer.cornerRadius = 5;
    [_title.layer setMasksToBounds:YES];
    [_background addSubview:_title];
}

- (void)defaultLayout
{
    CGRect screen = [UIScreen mainScreen].bounds;
    CGSize backSize = HUDAudioView.hudSize;
    _title.text = @"手指上滑，取消发送";
    CGSize titleSize = [_title sizeThatFits:CGSizeMake(CGRectGetWidth(screen), CGRectGetHeight(screen))];
    if(titleSize.width > backSize.width){
        backSize.width = titleSize.width + 2 * HUDAudioView.hudInnerMargin;
    }

    _background.frame = CGRectMake((CGRectGetWidth(screen) - backSize.width) * 0.5, (CGRectGetHeight(screen) - backSize.height) * 0.5, backSize.width, backSize.height);
    CGFloat imageHeight = backSize.height - titleSize.height - 2 * HUDAudioView.hudInnerMargin;
    _recordImage.frame = CGRectMake(0, 0, backSize.width, imageHeight);
    CGFloat titley = _recordImage.frame.origin.y + imageHeight;
    _title.frame = CGRectMake(0, titley, backSize.width, backSize.height - titley);
}

- (void)setStatus:(HUDAudioViewRecordStatus)status
{
    switch (status) {
        case HUDAudioViewRecording:
        {
            _title.text = @"手指上滑，取消发送";
            _title.backgroundColor = [UIColor clearColor];
            break;
        }
        case HUDAudioViewCancel:
        {
            _title.text = @"松开手指，取消发送";
            _title.backgroundColor = HUDAudioView.hudWarningColor;
            break;
        }
        case HUDAudioViewTooShort:
        {
            _title.text = @"说话时间太短";
            _title.backgroundColor = [UIColor clearColor];
            break;
        }
        case HUDAudioViewTooLong:
        {
            _title.text = @"说话时间太长";
            _title.backgroundColor = [UIColor clearColor];
            break;
        }
        default:
            break;
    }
}

- (void)setPower:(NSInteger)power
{
    NSString *imageName = [self getRecordImage:power];
    _recordImage.image = [HUDAudioView imageNamed:imageName];
}

- (NSString *)getRecordImage:(NSInteger)power
{
    // 关键代码
    power = power + 60;
    int index = 0;
    if (power < 25){
        index = 1;
    } else{
        index = ceil((power - 25) / 5.0) + 1;
    }

    return [NSString stringWithFormat:@"record_%d", index];
}



static UIColor *_hudBGColor;
+ (UIColor *)hudBGColor {
    return _hudBGColor;
}
+ (void)setHudBGColor:(UIColor *)hudBGColor {
    _hudBGColor = hudBGColor;
}

static UIColor *_hudWarningColor;
+ (UIColor *)hudWarningColor {
    return _hudWarningColor;
}
+ (void)setHudWarningColor:(UIColor *)hudWarningColor {
    _hudWarningColor = hudWarningColor;
}

static CGSize _hudSize;
+ (CGSize)hudSize {
    return _hudSize;
}
+ (void)setHudSize:(CGSize)hudSize{
    _hudSize = hudSize;
}

static CGFloat _hudInnerMargin;
+ (CGFloat)hudInnerMargin {
    return _hudInnerMargin;
}
+ (void)setHudInnerMargin:(CGFloat)hudInnerMargin{
    _hudInnerMargin = hudInnerMargin;
}

@end
