//
// Created by jsonmess on 2017/1/23.
// Copyright (c) 2017 com.jsonmess.audioFileStream. All rights reserved.
//

#import "JSAudioEventLoop.h"
#import <pthread.h>
#import <objc/runtime.h>

typedef NS_ENUM(NSInteger,JSAudioEventActonType)
{
    JSAudioEventActonPlay = 0,

    JSAudioEventActonStop,

    JSAudioEventActonPause,

    JSAudioEventActonResume
};

/**
 * 该runloop
 */

@interface JSAudioEventLoop()

@property (nonatomic, strong) NSThread * mEventThread;
//停止播放信号；
@property (nonatomic, strong) NSMachPort * queueMachPort;//loop循环中止信号

@end

@implementation JSAudioEventLoop

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self setUp];
    }
    return self;
}

- (void)setUp
{
    _mEventThread = [[NSThread alloc] initWithBlock:^
    {
        self.queueMachPort = [NSMachPort port];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:self.queueMachPort forMode:NSRunLoopCommonModes];
        [runLoop run];
    }];
    [_mEventThread setName:@"com.jsonmess.audioQueue"];
}
/**
 * 启动runloop
 */
- (void)startEventLoop
{
    if (!_mEventThread)
    {
        return;
    }
    [self.mEventThread start];
}


- (void)sendEventActionWithType:(JSAudioEventActonType)type
{
    NSDictionary * dic = @{
            @"actionType":@(JSAudioEventActonPlay)
    };
    [self performSelector:@selector(sendActionWithParams:) onThread:self.mEventThread
               withObject:dic
            waitUntilDone:NO];
}

- (void)sendActionWithParams:(NSDictionary *)pararmDic
{
    JSAudioEventActonType eventActonType = [pararmDic valueForKey:@"actionType"];
    while (1)
    {
        @autoreleasepool
        {

                switch (eventActonType)
                    {
                          case JSAudioEventActonPlay:

                            break;

                          case :

                            break;

                          case :

                            break;

                          default:

                            break;
                    }



        }

    }
}
#pragma mark ---- actions

- (void)stop
{
    [self sendEventActionWithType:JSAudioEventActonStop];
}

- (void)play
{
    [self sendEventActionWithType:JSAudioEventActonPlay];
}
@end