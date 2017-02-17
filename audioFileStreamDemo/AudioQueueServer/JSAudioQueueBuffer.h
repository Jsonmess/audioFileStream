//
// Created by jsonmess on 2017/1/23.
// Copyright (c) 2017 com.jsonmess.audioFileStream. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

/**
 * 音频队列中 音频数据容器
 */
@interface JSAudioQueueBuffer : NSObject

//音频队列缓存容器
@property(nonatomic, assign) AudioQueueBufferRef audioQueueBuffer;

@property(nonatomic, assign) BOOL isEmpty;//重用标志位。

@property(nonatomic, assign) AudioStreamPacketDescription packetDescription;

@end