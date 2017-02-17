//
// Created by jsonmess on 2017/1/23.
// Copyright (c) 2017 com.jsonmess.audioFileStream. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * 启动一个runloop，直到数据全部被播放完成才停止
 */
@interface JSAudioEventLoop : NSObject

- (void)startEventLoop;

- (void)play;

- (void)stop;

- (void)flushToPlay;

@end