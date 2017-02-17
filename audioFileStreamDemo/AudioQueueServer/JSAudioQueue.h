//
// Created by jsonmess on 2017/1/13.
// Copyright (c) 2017 com.jsonmess.camera. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

typedef NS_ENUM(NSInteger ,AudioQueueType)
{
    AudioQueueTypePlayBack = 0,//播放  默认
    AudioQueueTypeRecord       //录音
};

@interface JSAudioQueue : NSObject

//队列
@property (nonatomic, assign, readonly) AudioQueueRef audioQueue;

@property(nonatomic, assign, readonly) BOOL isPlaying;

/*****播放相关*****/
@property(nonatomic, assign) float volume;//音量


- (instancetype)initAudioQueueWith:(AudioStreamBasicDescription)description bufferSize:(UInt32)bufferSize audioMagicData:(NSData *)magicData;

/**
 * 创建音频队列
 *
 * @param type type  默认为 AudioQueueTypePlayBack
 */

- (void)createAudioQueueServerWithType:(AudioQueueType)type;

/**
 * 播放音频数据
 *
 * @param bufferSize buffer 的size
 *
 * @param packetCount 当前数据中共多少个包
 *
 * @param description buffer中 描述
 *
 */
- (BOOL)playAudioData:(NSData *)audioData packetSize:(UInt32)bufferSize packetCount:(UInt32)packetCount packetDescription:(AudioStreamPacketDescription)description;

#pragma mark ----- 基本操作

/**
 * 开始音频队列
 */
- (BOOL)startAudioQueue;
/**
 * 暂停音频队列
 */
- (BOOL)pauseAudioQueue;
/**
 * 重置音频队列
 */
- (BOOL)resetAudioQueue;
/**
 * 停止音频队列
 */
- (BOOL)stopAudioQueue:(BOOL)immediately;

@end