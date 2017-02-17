//
// Created by jsonmess on 2017/1/13.
// Copyright (c) 2017 com.jsonmess.camera. All rights reserved.
//

#import "JSAudioFileStream.h"
#import "JSAudioStreamPlayerHelper.h"
#import "JSAudioParsedData.h"

#define  BitRateEstimationMinPackets 20 //估算采样率最小数量

@interface JSAudioFileStream ()

@property(nonatomic, weak) id <JSAudioFileStreamDelegate> mDelegate;

@property(nonatomic, assign) AudioFileTypeID mFileType;

@property(nonatomic, assign) unsigned long long mFileSize;

@property(nonatomic, assign) AudioFileStreamID mFileStreamID;

@property(nonatomic, assign) BOOL mIsParsedStreamDisContinuous;//解析音频流是否连续

@property(nonatomic, assign) UInt32 mPacketMaxSize; //包的最大size

@property(nonatomic, assign) SInt64 mAudioDataInFileOffset; //音频数据帧在音频流中的偏移

@property(nonatomic, assign) UInt64 mActualAudioDataSize; //音频数据帧实际长度

@property(nonatomic, assign) NSTimeInterval mAudioDuration; //音频数据时长

@property(nonatomic, assign) AudioStreamBasicDescription mStreamFileFormat;//文件流基本信息

@property(nonatomic, assign) NSTimeInterval mAudioPacketDuration; //音频数据包时长

@property(nonatomic, strong) NSDictionary *mAudioFileExtraInfoDic; //音频数据流额外信息

@property(nonatomic, strong) NSData *mMagicCookie; //音频数据流额外信息

@property(nonatomic, assign) BOOL mIsReadyToProducePacket;

@property(nonatomic, assign,readonly) float  mBitRate; //kbps

@end

@implementation JSAudioFileStream


#pragma mark ------ AudioFileStreamCallBack

static void JSAudioFileStreamPropertyCallBack(
        void *inClientData,
        AudioFileStreamID inAudioFileStream,
        AudioFileStreamPropertyID inPropertyID,
        AudioFileStreamPropertyFlags *ioFlags)
{
     NSLog(@"解析音频数据基本信息");
    JSAudioFileStream *stream = (__bridge JSAudioFileStream *) inClientData;
    [stream handleParseAudioFileStreamProperty:inPropertyID ioFlags:ioFlags];
}

static void JSAudioFileStreamPacketsCallBack(
                                             void *inClientData,
                                             UInt32 inNumberBytes,
                                             UInt32 inNumberPackets,
                                             const void *inInputData,
                                             AudioStreamPacketDescription *inPacketDescriptions)
{
    JSAudioFileStream *stream = (__bridge JSAudioFileStream *) inClientData;
    NSLog(@"有解析数据回调");
    [stream handleParseAudioFileStreamPackets:inNumberBytes
                                numberPackets:inNumberPackets
                                    inputData:inInputData
                      streamPacketDesctiption:inPacketDescriptions];
}

#pragma mark ----- life circle

- (instancetype)initWithFileType:(AudioFileTypeID)typeId fileSize:(unsigned long long)size delegate:(id)delegate
{
    self = [super init];
    if (self)
    {
        _mDelegate = delegate;
        _mFileSize = size;
        _mFileType = typeId;
        _mIsParsedStreamDisContinuous = NO;
    }
    return self;
}

- (instancetype)init
{
    return [self initWithFileType:kAudioFileMP3Type fileSize:0 delegate:nil];
}

- (void)dealloc
{
    [self closeAudioFileStream];
}
#pragma mark ------ getting and setting

- (NSTimeInterval)audioDuration
{
    return _mAudioDuration;
}

- (float)bitRate
{
    return _mBitRate;
}

- (AudioFileTypeID)fileTypeID
{
    return _mFileType;
}

- (AudioFileStreamID)fileStreamID
{
    return _mFileStreamID;
}
- (AudioStreamBasicDescription)streamFileFormat
{
    return _mStreamFileFormat;
}
#pragma mark ------ public

- (void)openAudioFileStreamWithError:(NSError **)error
{
    void *inClientData = (__bridge void *) self;
    OSStatus status = AudioFileStreamOpen(inClientData, &JSAudioFileStreamPropertyCallBack, &JSAudioFileStreamPacketsCallBack, _mFileType, &_mFileStreamID);
    if (status != noErr)
    {
        *error = [JSAudioStreamPlayerHelper createErrorWithOSStatus:status];
        _mFileStreamID = NULL;
    }
}

- (void)closeAudioFileStream
{
    if (_mFileStreamID != NULL)
    {
        AudioFileStreamClose(_mFileStreamID);
        _mFileStreamID = NULL;
    }
}

- (BOOL)parseData:(NSData *)originalData parseError:(NSError **)error
{
    if (_mIsReadyToProducePacket && _mAudioPacketDuration == 0)
    {
       *error = [JSAudioStreamPlayerHelper createErrorWithOSStatus:-1];
        return NO;
    }
    UInt32 dataByteSize = (UInt32)[originalData length];
    OSStatus status =  AudioFileStreamParseBytes(_mFileStreamID,dataByteSize,[originalData bytes],_mIsParsedStreamDisContinuous ? kAudioFileStreamParseFlag_Discontinuity : 0);    [JSAudioStreamPlayerHelper createErrorWithOSStatus:status];
    return  noErr == status;
}

/**
 * 从音频流基本信息中获取 magicCookie
 */
- (NSData *)fetchAudioFileStreamMagicCookie
{
    if (!_mMagicCookie)
    {
        [self parseMagicCookie];
    }
    return _mMagicCookie;
}
/**
 * 快进操作
 */
- (SInt64)seekParseDataWithPosition:(NSTimeInterval*)position
{
    //近似起点
    SInt64 approximateSeekOffset = _mAudioDataInFileOffset + (*position / _mAudioDuration) *_mActualAudioDataSize;
    //向下取整，获取包的数量
    SInt64 seekToPacket = floor(*position / _mAudioPacketDuration);
    SInt64 seekByteOffset;
    UInt32 ioFlags = 0;
    SInt64 outDataByteOffset;
    //尝试快进 ioFlags 是表明outDataByteOffset 是否是预估值
    OSStatus status = AudioFileStreamSeek(_mFileStreamID, seekToPacket, &outDataByteOffset, &ioFlags);
    if (status == noErr && !(ioFlags & kAudioFileStreamSeekFlag_OffsetIsEstimated))
    {
        //修正能跳转的时间点
        *position -= ((approximateSeekOffset - _mAudioDataInFileOffset) - outDataByteOffset) * 8.0 / _mBitRate;
        seekByteOffset = outDataByteOffset + _mAudioDataInFileOffset;
    }
    else
    {
        _mIsParsedStreamDisContinuous = YES;
        //预估值，被AudioFileStreamSeek 直接接受
        seekByteOffset = approximateSeekOffset;
    }
    return seekByteOffset;
}

#pragma mark  ---- parse audio file stream base info and packets data

/****** 解析基本信息 ******/

//获取包的大小
- (void)parsedInfoPropertyInReadyToProducePackets
{
    _mIsParsedStreamDisContinuous = NO;
    _mIsReadyToProducePacket = YES;
    if (self.mDelegate && [self.mDelegate respondsToSelector:@selector(audioFileStreamReadyToProducePacket:)])
    {
        [self.mDelegate audioFileStreamReadyToProducePacket:self];
    }
    //获取最大的packageSize
    //AudioFileStreamGetPropertyInfo 来获取属性的结构，和size，方便创建属性
    //1.获取上限
    UInt32 propertySize = sizeof(_mPacketMaxSize);
    OSStatus status = AudioFileStreamGetProperty(_mFileStreamID, kAudioFileStreamProperty_MaximumPacketSize, &propertySize, &_mPacketMaxSize);
    if (status == noErr)
    {
        //尝试使用UpperBound 来决定包大小
        AudioFileStreamGetProperty(_mFileStreamID, kAudioFileStreamProperty_PacketSizeUpperBound, &propertySize, &_mPacketMaxSize);
    }
}

//获取实际音频帧 偏移量
- (void)parsedInfoPropertyInDataOffset
{
    UInt32 propertySize = sizeof(_mAudioDataInFileOffset);
    AudioFileStreamGetProperty(_mFileStreamID, kAudioFileStreamProperty_DataOffset, &propertySize, &_mAudioDataInFileOffset);
    //实际音频数据 在音频流中的长度
    UInt64 actualAudioDataSize = _mFileSize - _mAudioDataInFileOffset;
    _mActualAudioDataSize = actualAudioDataSize;
    //计算时长（文件大小(byte) * 8）/ 采样率（kbps）
    if (_mActualAudioDataSize > 0 && _mBitRate > 0)
    {
        _mAudioDuration = _mActualAudioDataSize * 8.0 / _mBitRate;
    }
}

//获取音频流 基本描述（采样率等）
- (void)parsedInfoPropertyInDataFormat
{
    UInt32 propertySize = sizeof(_mStreamFileFormat);
    AudioFileStreamGetProperty(_mFileStreamID, kAudioFileStreamProperty_DataFormat, &propertySize, &_mStreamFileFormat);
    //计算音频 包的时长
    if (_mStreamFileFormat.mSampleRate > 0 && _mStreamFileFormat.mFramesPerPacket > 0)
    {
        _mBitRate = _mStreamFileFormat.mSampleRate;
        _mAudioPacketDuration = _mStreamFileFormat.mFramesPerPacket / _mStreamFileFormat.mSampleRate;
    }
}

//获取音频流基本描述列表 （对于AAC SBR 这类格式）
- (void)parsedInfoPropertyInFormatList
{
    //1.获取 format list size
    UInt32 propertySize;
    Boolean outWritable;
    OSStatus status = AudioFileStreamGetPropertyInfo(_mFileStreamID, kAudioFileStreamProperty_FormatList, &propertySize, &outWritable);
    if (status == noErr)
    {
        AudioFormatListItem *formatListItem = (AudioFormatListItem *) malloc(propertySize);
        status = AudioFileStreamGetProperty(_mFileStreamID, kAudioFormatProperty_FormatList, &propertySize, formatListItem);
        if (status == noErr)
        {
            //取出支持的默认所有解码器格式列表
            UInt32 supportedFormatsSize;
            status = AudioFormatGetPropertyInfo(kAudioFormatProperty_DecodeFormatIDs, 0, NULL, &supportedFormatsSize);
            if (status != noErr)
            {
                free(formatListItem);
                return;
            }
            //解码器格式支持数量
            UInt32 supportedFormatCount = supportedFormatsSize / sizeof(OSType);
            OSType *supportedFormats = (OSType *) malloc(supportedFormatsSize);
            status = AudioFormatGetProperty(kAudioFormatProperty_DecodeFormatIDs, 0, NULL,&supportedFormatCount,supportedFormats);
            if (status != noErr)
            {
                free(formatListItem);
                free(supportedFormats);
            }
            for (int i = 0; i * sizeof(AudioFormatListItem) < propertySize; i++)
            {
                //遍历每个格式
                AudioStreamBasicDescription format = formatListItem[i].mASBD;
                for (UInt32 j = 0; j < supportedFormatCount; ++j)
                {
                    //音频数据流 中描述 解码列表，有系统支持的，则返回 （这一段解释不太确定.../(ㄒoㄒ)/~~）
                    if (format.mFormatID == supportedFormats[j])
                    {
                        _mStreamFileFormat = format;
                        if (_mStreamFileFormat.mSampleRate > 0 && _mStreamFileFormat.mFramesPerPacket > 0)
                        {
                            _mBitRate = _mStreamFileFormat.mSampleRate;
                            _mAudioPacketDuration = _mStreamFileFormat.mFramesPerPacket / _mStreamFileFormat.mSampleRate;
                        }
                        break;
                    }
                }
            }
            free(supportedFormats);
        }
        free(formatListItem);
    }

}

//获取音频流额外信息
- (void)parsedExtraInfoDictionary
{
    UInt32 propertyDataSize;
    Boolean outWritable;
    OSStatus status = AudioFileStreamGetPropertyInfo(_mFileStreamID, kAudioFileStreamProperty_InfoDictionary, &propertyDataSize, &outWritable);
    if (status == noErr)
    {
        CFDictionaryRef infoDic = (CFDictionaryRef)malloc(propertyDataSize);
        status = AudioFileStreamGetProperty(_mFileStreamID, kAudioFileStreamProperty_InfoDictionary, &propertyDataSize, &infoDic);
        if (status == noErr)
        {
            NSDictionary *dictionary = (__bridge NSDictionary *) infoDic;
            _mAudioFileExtraInfoDic = dictionary;
        }
    }
}

//获取magicCookie

- (void)parseMagicCookie
{
    Boolean outWritable;
    UInt32 outPropertyDataSize;
    OSStatus status = AudioFileStreamGetPropertyInfo(_mFileStreamID, kAudioFileStreamProperty_MagicCookieData, &outPropertyDataSize, &outWritable);
    if (status == noErr)
    {
        void *magicCookieData = malloc(outPropertyDataSize);
        status =  AudioFileStreamGetProperty(_mFileStreamID, kAudioFileStreamProperty_MagicCookieData, &outPropertyDataSize, magicCookieData);
        if (status == noErr && magicCookieData != NULL)
        {
           NSData * data = [NSData dataWithBytes:magicCookieData length:outPropertyDataSize];
            _mMagicCookie = data;
        }
    }
}

#pragma mark ----- AudioFileStreamParseDataHandle Function

/**
 * 解析处理基本信息
 */
- (void)handleParseAudioFileStreamProperty:(AudioFileStreamPropertyID)propertyID
                                   ioFlags:(AudioFileStreamPropertyFlags *)flags
{
    if (propertyID == kAudioFileStreamProperty_ReadyToProducePackets)
    {
        [self parsedInfoPropertyInReadyToProducePackets];
    } else if (propertyID == kAudioFileStreamProperty_DataOffset)
    {
        [self parsedInfoPropertyInDataOffset];
    } else if (propertyID == kAudioFileStreamProperty_DataFormat)
    {
        [self parsedInfoPropertyInDataFormat];
    } else if (propertyID == kAudioFileStreamProperty_FormatList)
    {
        //是用来支持AAC SBR这样的包含多个文件类型的音频格式。到底有多少个format我们并不知晓，所以全部拿出来
        [self parsedInfoPropertyInFormatList];
    } else if (propertyID == kAudioFileStreamProperty_InfoDictionary)
    {
        //解析音频数据流中 额外信息：如作者，歌词，封面等
        [self parsedExtraInfoDictionary];
    } else if (propertyID == kAudioFileStreamProperty_MagicCookieData)
    {
        //解析音频数据流 中的magicCookie
        [self parseMagicCookie];
    }
}

/**
 * 解析数据包
 */

- (void)handleParseAudioFileStreamPackets:(UInt32)inNumberBytes
                            numberPackets:(UInt32)inNumberPackets
                                inputData:(const void *)inInputData
                  streamPacketDesctiption:(AudioStreamPacketDescription *)inPacketDescriptions
{
    NSLog(@"解析数据有回调了");
    if (_mIsParsedStreamDisContinuous)
    {
        //快进后，数据解析不连续，但解析来数据是连续的，所以置为No；
        _mIsParsedStreamDisContinuous = NO;
    }
    if (inNumberBytes == 0 || inNumberPackets == 0)
        return;
    Boolean isCreatePacketDescriptions = NO;
    if (inPacketDescriptions == NULL)
    {
        //当前解析没有拿到包的基本描述，尝试手动创建
        isCreatePacketDescriptions = YES;
        inPacketDescriptions = (AudioStreamPacketDescription *) malloc(sizeof(AudioStreamPacketDescription) * inNumberPackets);
        UInt32 startOffset;
        UInt32 dataByteSize = inNumberBytes / inNumberPackets;
        for (int i = 0; i < inNumberPackets; ++i)
        {
            inPacketDescriptions[i].mVariableFramesInPacket = 0; //无法获取
            inPacketDescriptions[i].mStartOffset = startOffset * i;
            if (startOffset + dataByteSize > inNumberBytes)
            {
                //超过界限了，则全部给到
                inPacketDescriptions[i].mDataByteSize = inNumberBytes - startOffset;

            } else
            {
                inPacketDescriptions[i].mDataByteSize = dataByteSize;
            }
        }
    }
    //开始遍历,取出音频数据 （inPutData 指向的内存块）
    NSMutableArray *audioParsedDataArray = [NSMutableArray arrayWithCapacity:inNumberPackets];
    for (int j = 0; j < inNumberPackets; ++j)
    {
        const void *byteDataPoint = inInputData + inPacketDescriptions[j].mStartOffset;
        JSAudioParsedData *data = [[JSAudioParsedData alloc] initAudioParsedData:byteDataPoint
                                                    audioStreamPacketDescription:inPacketDescriptions[j]];
        [audioParsedDataArray addObject:data];
        if (inNumberPackets > BitRateEstimationMinPackets)
        {
            //包多，数据均衡
            //1.计算采样率（如果解析 basedespcation SampleRate 为 0情况）
            UInt32 dataByteSize = inNumberBytes / inNumberPackets;
            if (_mAudioPacketDuration != 0 && dataByteSize > 0 && _mBitRate <= 0)
            {
                _mBitRate = dataByteSize * 8.0 / _mAudioPacketDuration;
            }
            //2.计算时长
            if (_mFileSize > 0 && _mBitRate > 0)
            {
                _mAudioDuration = ((_mFileSize - _mAudioDataInFileOffset) * 8.0) / _mBitRate;
            }
        }
    }
    //解析完成：
    if (_mDelegate && [_mDelegate respondsToSelector:@selector(audioFileStream:parsedAudioData:)])
    {
        [_mDelegate audioFileStream:self parsedAudioData:audioParsedDataArray];
    }
    if (isCreatePacketDescriptions)
    {
        free(inPacketDescriptions);
    }
}
@end




