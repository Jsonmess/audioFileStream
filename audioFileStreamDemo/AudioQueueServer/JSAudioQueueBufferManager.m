//
// Created by jsonmess on 2017/2/3.
// Copyright (c) 2017 com.jsonmess.audioFileStream. All rights reserved.
//

#import "JSAudioQueueBufferManager.h"
#import <pthread.h>

@interface JSAudioQueueBufferManager ()
{
    pthread_mutex_t p_mutex;
    pthread_cond_t p_cond;
    NSMutableArray *idleBufferArray;//可填充的buffer 数组
    NSMutableArray *busyBufferArray;//已填充数据的buffer 数组
}

@end

@implementation JSAudioQueueBufferManager

#pragma mark ---- life circle

+ (JSAudioQueueBufferManager*)sharedAudioQueueBufferManager
{
    static  JSAudioQueueBufferManager *staticBufferManager = nil;
    static  dispatch_once_t onceToken;//断言指针
    dispatch_once(&onceToken, ^
    {
        staticBufferManager = [[JSAudioQueueBufferManager alloc] init];
    });
    return staticBufferManager;
}

+ (id) allocWithZone:(struct _NSZone *)zone {

    return [JSAudioQueueBufferManager sharedAudioQueueBufferManager];
}

+ (id) copyWithZone:(struct _NSZone *)zone {

    return [JSAudioQueueBufferManager sharedAudioQueueBufferManager];
}


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
    busyBufferArray = [NSMutableArray array];
    idleBufferArray = [NSMutableArray array];
    pthread_mutex_init(&p_mutex, NULL);
    pthread_cond_init(&p_cond, NULL);

}

#pragma mark ----- action

- (JSAudioQueueBuffer *)getIdleBuffer
{
    if (idleBufferArray.count > 0)
    {
        JSAudioQueueBuffer *tmpBuffer =  idleBufferArray.firstObject;
        [self outQueueTheIdleBuffer:tmpBuffer];
        return  tmpBuffer;
    }
    else
    {
        //需要等待空闲的buffer;
        pthread_mutex_lock(&p_mutex);
        pthread_cond_wait(&p_cond, &p_mutex);
        pthread_mutex_unlock(&p_mutex);
        JSAudioQueueBuffer *tmpBuffer = idleBufferArray.firstObject;
        [self outQueueTheIdleBuffer:tmpBuffer];
        return tmpBuffer;
    }
}

//入队
- (void)enqueueTheBusyBuffer:(JSAudioQueueBuffer *)buffer
{
    pthread_mutex_lock(&p_mutex);
    [busyBufferArray addObject:buffer];
    pthread_mutex_unlock(&p_mutex);
}

- (void)enqueueTheIdleBuffer:(JSAudioQueueBuffer *)buffer
{
    pthread_mutex_lock(&p_mutex);
    [idleBufferArray addObject:buffer];
    pthread_cond_signal(&p_cond);
    pthread_mutex_unlock(&p_mutex);
}

- (void)outQueueTheBusyBuffer:(JSAudioQueueBuffer *)buffer
{
    pthread_mutex_lock(&p_mutex);
    [busyBufferArray removeObject:buffer];
    pthread_mutex_unlock(&p_mutex);
}

- (void)outQueueTheIdleBuffer:(JSAudioQueueBuffer *)buffer
{
    pthread_mutex_lock(&p_mutex);
    [idleBufferArray removeObject:buffer];
    pthread_mutex_unlock(&p_mutex);
}

- (JSAudioQueueBuffer *)getBusyBufferWithQueueBufferRef:(AudioQueueBufferRef)bufferRef
{
    JSAudioQueueBuffer *buffer = nil;
    for (JSAudioQueueBuffer *tmp in busyBufferArray)
    {
        if (tmp.audioQueueBuffer == bufferRef)
        {
            buffer = tmp;
            break;
        }
    }
    return buffer;
}

- (void)dealloc
{
    pthread_cond_destroy(&p_cond);
    pthread_mutex_destroy(&p_mutex);
}
@end