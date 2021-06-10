//
//  HUDAudioManager.m
//  HUDAudioManager
//
//  Created by MeterWhite on 2020/10/15.
//  Copyright © 2020 Meterwhite. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "HUDAudioManager.h"
#import "HUDAudioView.h"

@interface HUDAudioManager ()<AVAudioPlayerDelegate>

/// 录音
@property (nullable,nonatomic,strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) NSDate *recordStartTime;
@property (nonatomic, strong) HUDAudioView *recordV;
@property (nonatomic, strong) NSTimer *recordTimer;

/// 播放本地文件
@property (nullable,nonatomic,strong) AVAudioPlayer *audioPlayer;
@property (nullable,nonatomic,copy) void(^whenFilePlayedSuc)(void);

/// 播放远程文件
@property (nullable,nonatomic,strong) AVPlayer *avplayer;
@property (nullable,nonatomic,copy) void(^whenURLStringPlayedSuc)(void);
@property (nullable,nonatomic,strong) AVPlayerItem *avplayItem;
@end

@implementation HUDAudioManager

+ (instancetype)shared {
    static HUDAudioManager *_value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _value = HUDAudioManager.new;
        /// 处理AVPlayer的播放异常
        [NSNotificationCenter.defaultCenter addObserver:_value
                                               selector:@selector(whenAVPlayFinished:) name:AVPlayerItemDidPlayToEndTimeNotification
                                                 object:nil];
        [NSNotificationCenter.defaultCenter addObserver:_value
                                               selector:@selector(whenAVPlayFinished:) name:AVPlayerItemFailedToPlayToEndTimeNotification
                                                 object:nil];
        [NSNotificationCenter.defaultCenter addObserver:_value
                                               selector:@selector(whenAVPlayFinished:) name:AVPlayerItemPlaybackStalledNotification
                                                 object:nil];
        /// 只用于处理播放本地文件的中断
        [NSNotificationCenter.defaultCenter addObserver:_value
                                               selector:@selector(whenInterrupted:) name:AVAudioSessionInterruptionNotification
                                                 object:nil];
    });
    return _value;
}

+ (NSString *)audioEntryPath {
    static NSString* _audioEntryPath;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _audioEntryPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"audios"];
    });
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:_audioEntryPath]) {
        [fileManager createDirectoryAtPath:_audioEntryPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return _audioEntryPath;
}

#pragma mark - 播放 听筒与扬声器的处理
/// 播放之前设置yes，播放结束设置NO，这个功能是开启红外感应
- (void)setProximity:(BOOL)enable {
    [[UIDevice currentDevice] setProximityMonitoringEnabled:enable];
    if(enable) {//添加监听
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(whenProximityChanged:) name:@"UIDeviceProximityStateDidChangeNotification"
                                                   object:nil];
    } else {
        //移除监听
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:@"UIDeviceProximityStateDidChangeNotification"
                                                      object:nil];
    }
}

- (void)whenProximityChanged:(NSNotification *)ntf {
    //如果此时手机靠近面部放在耳朵旁，那么声音将通过听筒输出，并将屏幕变暗（省电啊）
    if([[UIDevice currentDevice] proximityState] ==YES) {
//        DELOG(@"靠近耳朵");
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    } else {
//        DELOG(@"远离耳朵");
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    }
}

#pragma mark - 网络播放
- (void)playURLString:(NSString *)url completion:(void(^)(void))completion {
    if(!url) return;
    /// 默认扬声器播放
    AVAudioSession * session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord
             withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:0];
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:url]];
    if(_avplayItem) {
        [_avplayer replaceCurrentItemWithPlayerItem:item];
        _avplayItem = item;
        _whenURLStringPlayedSuc = completion;
        return;
    }
    _avplayItem = item;
    _whenURLStringPlayedSuc = completion;
    _avplayer = [AVPlayer playerWithPlayerItem:item];
    [self setProximity:YES];
    [_avplayer play];
}

- (void)stopPlayURLString {
    _avplayItem = nil;
    [_avplayer pause];
    _avplayer = nil;
}

- (void)whenAVPlayFinished:(NSNotification *)ntf {
    if(_avplayItem == nil) return;
    if(_avplayItem != ntf.object) return;
    _whenURLStringPlayedSuc ? _whenURLStringPlayedSuc() : nil;
    [self setProximity:NO];
    [self release4AVPaler];
}

- (void)release4AVPaler {
    _avplayItem = nil;
    _whenURLStringPlayedSuc = nil;
}

#pragma mark - 本地播放 不处理中断

- (void)playFile:(NSString *)path completion:(void(^)(void))completion {
    if (!path) return;
    /// 默认扬声器播放
    AVAudioSession * session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:0];
    if(_audioPlayer) {
        /// 销毁旧的播放
        [_audioPlayer stop];
        _audioPlayer = nil;
    }
    _whenFilePlayedSuc = completion;
    NSURL *url = [NSURL fileURLWithPath:path isDirectory:0];
    NSError *err;
    _audioPlayer = [AVAudioPlayer.alloc initWithContentsOfURL:url error:&err];
    [_audioPlayer setDelegate:self];
    if(err) {
//        DELOG(@"音频播放文件错误");
        _audioPlayer = 0;
        return;
    }
    [self setProximity:YES];
    [_audioPlayer play];
}

- (void)stopPlayFile {
    [_audioPlayer stop];
    [self setProximity:NO];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    _whenFilePlayedSuc ? _whenFilePlayedSuc() : 0;
//    DELOG(@"音频文件播放完成 successfully = %@", THE_NB_STRING(flag));
    _audioPlayer = nil;
    [self setProximity:NO];
}

- (void)whenInterrupted:(NSNotification *)ntf {
    if(!_audioPlayer || !_audioPlayer.isPlaying) return;
    _whenFilePlayedSuc ? _whenFilePlayedSuc() : 0;
//    DELOG(@"音频文件播放被打断");
    _audioPlayer = nil;
    [self setProximity:NO];
}

#pragma mark - 录制

- (void)permisionIn:(void(^)(void))block {
    AVAudioSessionRecordPermission permission = AVAudioSession.sharedInstance.recordPermission;
    //在此添加新的判定 undetermined，否则新安装后的第一次询问会出错。新安装后的第一次询问为 undetermined，而非 denied。
    if (permission == AVAudioSessionRecordPermissionDenied || permission == AVAudioSessionRecordPermissionUndetermined) {
        [AVAudioSession.sharedInstance requestRecordPermission:^(BOOL granted) {
            if (!granted) {
                UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Unable to access microphone" message:@"Turn on microphone permissions to send voice messages" preferredStyle:UIAlertControllerStyleAlert];
                [ac addAction:[UIAlertAction actionWithTitle:@"Not now" style:UIAlertActionStyleCancel handler:nil]];
                [ac addAction:[UIAlertAction actionWithTitle:@"Go to open" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    UIApplication *app = [UIApplication sharedApplication];
                    NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                    if ([app canOpenURL:settingsURL]) {
                        [app openURL:settingsURL options:@{} completionHandler:0];
                    }
                }]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.currVC presentViewController:ac animated:YES completion:nil];
                });
            }
        }];
        return;
    }
    //在此包一层判断，添加一层保护措施。
    if(permission == AVAudioSessionRecordPermissionGranted){
        block ? block() : 0;
    }
}

- (void)startRecord {
    if (AVAudioSession.sharedInstance.recordPermission == AVAudioSessionRecordPermissionDenied) {
        return;
    }
//    [_recordButton setTitle:@"Press to talk" forState:UIControlStateNormal];
    NSAssert(self.currVC, @"必选");
    if(!_recordV){
        _recordV = [[HUDAudioView alloc] init];
        [_recordV setUserInteractionEnabled:0];
        _recordV.frame = [UIScreen mainScreen].bounds;
    }
    [self.currVC.view.window addSubview:_recordV];
    _recordStartTime = [NSDate date];
    [_recordV setStatus:HUDAudioViewRecording];
//    _recordButton.backgroundColor = [UIColor lightGrayColor];
//    [_recordButton setTitle:@"Release to send" forState:UIControlStateNormal];
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error = nil;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    [session setActive:YES error:&error];

    //设置参数
    NSDictionary *recordSetting = [[NSDictionary alloc] initWithObjectsAndKeys:
                                   //采样率  8000/11025/22050/44100/96000（影响音频的质量）
                                   [NSNumber numberWithFloat: 8000.0],AVSampleRateKey,
                                   // 音频格式
                                   [NSNumber numberWithInt: kAudioFormatMPEG4AAC],AVFormatIDKey,
                                   //采样位数  8、16、24、32 默认为16
                                   [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
                                   // 音频通道数 1 或 2
                                   [NSNumber numberWithInt: 1], AVNumberOfChannelsKey,
                                   //录音质量
                                   [NSNumber numberWithInt:AVAudioQualityHigh],AVEncoderAudioQualityKey,
                                   nil];

    NSString *path = [HUDAudioManager.audioEntryPath stringByAppendingString:[NSString stringWithFormat:@"%@.m4a",[NSDate date]]];
    NSURL *url = [NSURL fileURLWithPath:path];
    _recorder = [[AVAudioRecorder alloc] initWithURL:url settings:recordSetting error:nil];
    _recorder.meteringEnabled = YES;
    [_recorder prepareToRecord];
    [_recorder record];
    [_recorder updateMeters];
    _recordTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(recordTick:) userInfo:nil repeats:YES];
}

- (void)recordTick:(NSTimer *)timer{
    [_recorder updateMeters];
    float power = [_recorder averagePowerForChannel:0];
    [_recordV setPower:power];
    
    //在此处添加一个时长判定，如果时长超过60s，则取消录制，提示时间过长,同时不再显示 recordView。
    //此处使用 recorder 的属性，使得录音结果尽量精准。注意：由于语音的时长为整形，所以 60.X 秒的情况会被向下取整。但因为 ticker 0.5秒执行一次，所以因该都会在超时时显示为60s
    NSTimeInterval interval = _recorder.currentTime;
    if(interval >= 55 && interval < 60){
        NSInteger seconds = 60 - interval;
        NSString *secondsString = [NSString stringWithFormat:@"Recording will end in %ld seconds",(long)seconds + 1];//此处加long，是为了消除编译器警告。此处 +1 是为了向上取整，优化时间逻辑。
        _recordV.title.text = secondsString;
    }
    if(interval >= 60){
        [self stopRecordIn:^(NSString * _Nonnull path) {
            [self.recordV setStatus:HUDAudioViewTooLong];
        }];
    }
}

/// 结束录制
- (void)stopRecordIn:(void(^)(NSString *path))block {
    NSTimeInterval interval = _recorder.currentTime;
    if(interval <= 1) {
        [self cancelRecordWithState:HUDAudioViewTooShort];
        return;
    }
    if(_recordTimer){
        [_recordTimer invalidate];
    }
    if([_recorder isRecording]){
        [_recorder stop];
    }
    block ? block(_recorder.url.path) : 0;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.recordV removeFromSuperview];
    });
    [self release4Recod];
}

/// 取消录制
- (void)cancelRecord {
    [self cancelRecordWithState:HUDAudioViewCancel];
}

/// 指定显示并取消录制
- (void)cancelRecordWithState:(HUDAudioViewRecordStatus)state {
    if(_recordTimer) {
        [_recordTimer invalidate];
    }
    if([_recorder isRecording]) {
        [_recorder stop];
    }
    NSString *path = _recorder.url.path;
    if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    [self.recordV setStatus:state];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^ {
        [self.recordV removeFromSuperview];
    });
    [self release4Recod];
}

- (void)recordExit {
    [_recordV setStatus:HUDAudioViewCancel];
}

- (void)recordEnter {
    [_recordV setStatus:HUDAudioViewRecording];
}

- (void)release4Recod {
    _recordTimer = nil;
    _recordStartTime = nil;
    _recorder = nil;
    _recorder = nil;
    _currVC = nil;
}
@end
