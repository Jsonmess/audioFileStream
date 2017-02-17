//
// Created by jsonmess on 2017/1/13.
// Copyright (c) 2017 com.jsonmess.camera. All rights reserved.
//

#import <Foundation/Foundation.h>

@class JSAudioStreamer,JSAudioPlayItem;

@protocol JSAudioStreamerDelegate <NSObject>

//播放进度时间回调
- (void)playProgressInTime:(JSAudioStreamer*)playerController progress:(Float64)progress;

@end



@interface JSAudioStreamer : NSObject

@property (nonatomic, readonly) NSTimeInterval playableDuration;//可播放的时长



@property (nonatomic,weak,nullable)id<JSAudioStreamerDelegate>delegate;

- (instancetype)initWithPlayItems:(NSArray<JSAudioPlayItem* >*)item NS_DESIGNATED_INITIALIZER;


-(void)setPlayItem:(JSAudioPlayItem *)item;


- (BOOL)isPlaying;

- (void)play;

- (void)pause;

- (void)stop;

@end