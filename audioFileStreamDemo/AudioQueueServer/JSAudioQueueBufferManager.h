//
// Created by jsonmess on 2017/2/3.
// Copyright (c) 2017 com.jsonmess.audioFileStream. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSAudioQueueBuffer.h"

#define AUDIOBUFFERDEFAULTCOUNT 3 //默认buffer 数量

@interface JSAudioQueueBufferManager : NSObject

+ (JSAudioQueueBufferManager*)sharedAudioQueueBufferManager;

/**
 * 获取空闲的buffer
 */
- (JSAudioQueueBuffer *)getIdleBuffer;

/**
 * 从使用buffer数组中 获取指定buffer
 */
- (JSAudioQueueBuffer *)getBusyBufferWithQueueBufferRef:(AudioQueueBufferRef)bufferRef;

/**
 * 入队 正在使用的buffer
 */
- (void)enqueueTheBusyBuffer:(JSAudioQueueBuffer *)buffer;

/**
 * 入队 空闲buffer
 */
- (void)enqueueTheIdleBuffer:(JSAudioQueueBuffer *)buffer;

/**
 * 出队 正在使用的buffer
 */
- (void)outQueueTheBusyBuffer:(JSAudioQueueBuffer *)buffer;

/**
 * 出队 空闲buffer
 */
- (void)outQueueTheIdleBuffer:(JSAudioQueueBuffer *)buffer;

@end