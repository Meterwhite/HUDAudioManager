//
//  HUDAudioManager.h
//  HUDAudioManager
//
//  Created by MeterWhite on 2020/10/15.
//  Copyright © 2020 Meterwhite. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 优化释放播放器等
@interface HUDAudioManager : NSObject

+ (instancetype)shared;

@property (nonatomic,class,readonly) NSString *audioEntryPath;

#pragma mark - 播放远程文件
- (void)playURLString:(NSString *)url completion:(void(^)(void))completion;
- (void)stopPlayURLString;
#pragma mark - 播放本地文件
- (void)playFile:(NSString *)path completion:(void(^)(void))completion;
- (void)stopPlayFile;
#pragma mark - 录制
/// Need
@property (nullable,nonatomic,weak) UIViewController *currVC;
@property (nullable,nonatomic,copy) void(^whenTips)(NSString *tips);
- (void)permisionIn:(void(^)(void))block;
- (void)startRecord;
- (void)stopRecordIn:(void(^)(NSString *path))block;
- (void)cancelRecord;
- (void)recordEnter;
- (void)recordExit;

@end

NS_ASSUME_NONNULL_END
