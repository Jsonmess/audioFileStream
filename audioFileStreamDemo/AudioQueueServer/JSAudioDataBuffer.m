//
// Created by jsonmess on 2017/2/3.
// Copyright (c) 2017 com.jsonmess.audioFileStream. All rights reserved.
//

#import "JSAudioDataBuffer.h"
#import "JSAudioParsedData.h"

@interface JSAudioDataBuffer()

@property (nonatomic, strong) NSMutableArray *mAudioDataArray; //存储音频数据
@property (nonatomic, assign) NSUInteger dataLength;

@end

@implementation JSAudioDataBuffer

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _mAudioDataArray = [NSMutableArray array];
    }
    return self;
}


- (void)appendAudioParsedData:(NSArray *)dataArray
{
    for (int i = 0; i < dataArray.count; ++i)
    {
        JSAudioParsedData *data = [self safeGetObjFromArray:dataArray index:i];
        [_mAudioDataArray addObject:data];
        _dataLength+=data.audioData.length;
    }
}

- (NSData *)getAudioDataWithDataSize:(UInt32)dataSize packetCount:(UInt32 *)packetCount descriptions:(AudioStreamPacketDescription*)descriptions
{
    if (dataSize == 0 && _mAudioDataArray.count == 0)
    {
        return nil;
    }
    //根据请求的数据大小，找出 缓存区的对应数据---取是顺序取资源--_mAudioDataArray 包数据是完整的
    //1.缓存区缓存的数据 大于请求数据大小，则能成功找到；

    //2.缓存区缓存数据小于请求数据大小，则返回返回就近 全部数据，并取得包的数量和descriptions

    NSUInteger tmpCount = 0;
    for (int i = 0; i < _mAudioDataArray.count ; ++i)
    {
        JSAudioParsedData *data = [self safeGetObjFromArray:_mAudioDataArray index:i];
        NSUInteger  dataLength = data.audioData.length;
        if (dataSize >= dataLength)
        {
            dataSize -= dataLength;
            tmpCount = i;
        }
        else
        {
            break;
        }
    }
    if (tmpCount < 1)
    {
        return nil;
    }
    *packetCount = (UInt32)tmpCount;
    if (descriptions != NULL)
    {
        descriptions = (AudioStreamPacketDescription*)malloc(sizeof(AudioStreamPacketDescription)*tmpCount);
    }
    NSMutableData *audioData = [NSMutableData data];
    //开始遍历
    //    struct  AudioStreamPacketDescription
    //    {
    //        SInt64  mStartOffset; //代表每一个buffer 的offset，我们指定了audioqueue buffer 大小，则解析后的packet 这个属性需要重新计算
    //        UInt32  mVariableFramesInPacket;
    //        UInt32  mDataByteSize;
    //    };
    //TODOJS://这里可以优化下，减少遍历..
    for (int j = 0; j < tmpCount; ++j)
    {
        JSAudioParsedData *data = [self safeGetObjFromArray:_mAudioDataArray index:j];
        if (descriptions != NULL)
        {
            AudioStreamPacketDescription des = data.audioStreamPacketDescription;
            des.mStartOffset = (SInt64)[audioData length];
            descriptions[j] = des;
            NSUInteger tmpDataLength = [data.audioData length];
            [audioData appendBytes:[data.audioData bytes] length:tmpDataLength];
        }
    }
    [_mAudioDataArray removeObjectsInRange:NSMakeRange(0, tmpCount)];
    _dataLength -= [audioData length];
    return audioData;
}

- (void)cleanAll
{
    [_mAudioDataArray removeAllObjects];
    _dataLength = 0;
}


#pragma mark ----- other action

- (id)safeGetObjFromArray:(NSArray *)array index:(NSInteger)index
{
  if (index < array.count)
  {
      return [array objectAtIndex:index];
  }
  else
  {
      return nil;
  }
}


@end