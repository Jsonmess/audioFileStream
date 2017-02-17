//
// Created by jsonmess on 2017/1/13.
// Copyright (c) 2017 com.jsonmess.camera. All rights reserved.
//

#import "JSAudioQueue.h"
#import "JSAudioQueueBuffer.h"
#import "JSAudioQueueBufferManager.h"

@interface JSAudioQueue()

@property(nonatomic, assign) AudioQueueRef mAudioQueueRef;

@property(nonatomic, strong) NSData *mMagicData;

@property(nonatomic, assign) AudioStreamBasicDescription mDescription;

//每一个buffer 的容量（可以固定，也可以根据解析音频数据后设置）
@property(nonatomic, assign) UInt32 mPerBufferSize;

@property(nonatomic, assign) BOOL mIsPlaying;

@property(nonatomic, assign) BOOL mAudioQueueIsStarted;

@property (nonatomic, strong) JSAudioQueueBufferManager *mBufferManager;

@end

@implementation JSAudioQueue

#pragma mark ------  AudioQueueOutputCallback and Listener

//一个buffer内容被读取后，自动回调
 void JSAudioQueueOutputCallback (
        void * __nullable       inUserData,
        AudioQueueRef           inAQ,
        AudioQueueBufferRef     inBuffer)
 {
     JSAudioQueue *queue = (__bridge JSAudioQueue *)inUserData;
     [queue handleAudioQueueOutputCallBack:inAQ buffer:inBuffer];
 }

//AudioQueue属性改变那监听
void JSAudioQueuePropertyListenerCallBack(
        void *__nullable inUserData,
        AudioQueueRef inAQ,
        AudioQueuePropertyID inID)
{
    JSAudioQueue *queue = (__bridge JSAudioQueue *)inUserData;
    [queue handleAudioQueuePropertyCallBack:inAQ theProperty:inID];
}

#pragma mark ------ life circle

- (instancetype)initAudioQueueWith:(AudioStreamBasicDescription)description bufferSize:(UInt32)bufferSize audioMagicData:(NSData *)magicData
{
    self = [super init];
    if (self)
    {
        _mDescription = description;
        _mMagicData = magicData;
        _mPerBufferSize = bufferSize;
        _mBufferManager = [JSAudioQueueBufferManager sharedAudioQueueBufferManager];
    }
    return self;
}

- (void)createAudioQueueServerWithType:(AudioQueueType)type
{
    OSStatus status = AudioQueueNewOutput(&_mDescription, &JSAudioQueueOutputCallback, (__bridge void *)(self), NULL, NULL, 0, &_mAudioQueueRef);
    if (status != noErr)
    {
        _mAudioQueueRef = NULL;
        return;
    }
    //设置audioQueue监听
    status = AudioQueueAddPropertyListener(_mAudioQueueRef, kAudioQueueProperty_IsRunning, &JSAudioQueuePropertyListenerCallBack, (__bridge void *)(self));
    if (status != noErr)
    {
        AudioQueueDispose(_mAudioQueueRef, YES);
        _mAudioQueueRef = NULL;
        return;
    }
    //添加缓存容器
    for (int i = 0; i < AUDIOBUFFERDEFAULTCOUNT; ++i)
    {
        AudioQueueBufferRef buffer;
        //如果buffer size 没有设置，则 10KB；
        _mPerBufferSize == 0 ? (_mPerBufferSize = 10*1024*8) : NULL;
       status = AudioQueueAllocateBuffer(_mAudioQueueRef, _mPerBufferSize, &buffer);
        if (status != noErr)
        {
            //TODOJS://这里不太应该创建一个buffer 失败就释放整个audio队列，后期改进。
            AudioQueueDispose(_mAudioQueueRef, YES);
            _mAudioQueueRef = NULL;
            break;
        }
        JSAudioQueueBuffer *audioQueueBuffer = [[JSAudioQueueBuffer alloc] init];
        audioQueueBuffer.audioQueueBuffer = buffer;
        [self.mBufferManager enqueueTheIdleBuffer:audioQueueBuffer];
    }
#if TARGET_OS_IPHONE
    //设置解码,硬编码优先
    UInt32 property = kAudioQueueHardwareCodecPolicy_PreferSoftware;
    AudioQueueSetProperty(_mAudioQueueRef, kAudioQueueProperty_HardwareCodecPolicy, property, sizeof(property));
#endif
    //设置magic cookie
    if (_mMagicData && _mMagicData.length > 0)
    {
        AudioQueueSetProperty(_mAudioQueueRef, kAudioQueueProperty_MagicCookie,[_mMagicData bytes],(UInt32)[_mMagicData length]);
    }
    //设置音量
    [self setAudioQueueVolume:_volume];
}

#pragma mark ------ getting and setting

- (BOOL)isPlaying
{
    return _mIsPlaying;
}


- (AudioQueueRef)audioQueue
{
    return _mAudioQueueRef;
}
#pragma mark ----- play audio base action

/**
 * 播放音频数据
 */
- (BOOL)playAudioData:(NSData *)audioData packetSize:(UInt32)bufferSize packetCount:(UInt32)packetCount packetDescription:(AudioStreamPacketDescription)description
{
    if (bufferSize > _mPerBufferSize)
    {
        //保证和初始化audio queue 包缓存大小一致,不一致，则会出现数据缺失情况
        return NO;
    }
    if (_mAudioQueueIsStarted)
    {
        return NO;
    }
    JSAudioQueueBuffer *bufferObj = [self.mBufferManager getIdleBuffer];
    memcpy(bufferObj.audioQueueBuffer->mAudioData, [audioData bytes], [audioData length]);
    bufferObj.audioQueueBuffer->mAudioDataByteSize = (UInt32)[audioData length];
    bufferObj.packetDescription = description;
    OSStatus status = AudioQueueEnqueueBuffer(_mAudioQueueRef, bufferObj.audioQueueBuffer,packetCount, &description);
    return status == noErr;
}

/**
 * 设置音量
 */
- (void)setAudioQueueVolume:(float)volume
{
    if (_mAudioQueueRef)
    {
        OSStatus  status = AudioQueueSetParameter(_mAudioQueueRef, kAudioQueueParam_Volume, volume);
        if (status != noErr)
        {
            NSLog(@"audio queue 设置音量失败");
        }
    }
}

/**
 * 销毁音频队列
 */
- (void)disposeAudioOutputQueue
{
    if (_mAudioQueueRef != NULL)
    {
        AudioQueueDispose(_mAudioQueueRef,true);
        _mAudioQueueRef = NULL;
    }
}

/**
 * 启动音频队列
 */
- (BOOL)startAudioQueue
{
    if (_mAudioQueueRef != NULL)
    {
        return NO;
    }
    OSStatus status = AudioQueueStart(_mAudioQueueRef, NULL);
    _mAudioQueueIsStarted = status == noErr;
    return _mAudioQueueIsStarted;
}

/**
 * 继续音频队列
 */
- (BOOL)resumeAudioQueue
{
    return [self startAudioQueue];
}

/**
 * 暂停音频队列
 */
- (BOOL)pauseAudioQueue
{
    OSStatus status = AudioQueuePause(_mAudioQueueRef);
    _mAudioQueueIsStarted = NO;
    return status == noErr;
}
/**
 * 重置音频队列
 */
- (BOOL)resetAudioQueue
{
    OSStatus status = AudioQueueReset(_mAudioQueueRef);
    return status == noErr;
}

/**
 * 刷新音频队列
 */
- (BOOL)flushAudioQueue
{
    OSStatus status = AudioQueueFlush(_mAudioQueueRef);
    return status == noErr;
}

/**
 * 停止音频队列
 */
- (BOOL)stopAudioQueue:(BOOL)immediately
{
    OSStatus status;
    if (immediately)
    {
        status = AudioQueueStop(_mAudioQueueRef, true);
    }
    else
    {
        status = AudioQueueStop(_mAudioQueueRef, false);
    }
    _mAudioQueueIsStarted = NO;
    return status == noErr;
}

#pragma mark --- AudioQueue Call Back

- (void)handleAudioQueueOutputCallBack:(AudioQueueRef)audioQueue buffer:(AudioQueueBufferRef)bufferRef
{
     JSAudioQueueBuffer *buffer =  [self.mBufferManager getBusyBufferWithQueueBufferRef:bufferRef];
    if (buffer)
    {
        //audio queue 已使用完buffer 则重用
        [self.mBufferManager enqueueTheIdleBuffer:buffer];
    }
}

- (void)handleAudioQueuePropertyCallBack:(AudioQueueRef)audioQueue theProperty:(AudioQueuePropertyID)propertyID
{
    if (propertyID ==kAudioQueueProperty_IsRunning)
    {
        UInt32  isRunning = 0;
        UInt32  size = sizeof(isRunning);
        AudioQueueGetProperty(audioQueue, kAudioQueueProperty_IsRunning, &isRunning, &size);
        _mIsPlaying = isRunning > 0;
    }
}

@end