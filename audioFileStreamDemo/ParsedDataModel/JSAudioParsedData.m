//
// Created by jsonmess on 2017/1/22.
// Copyright (c) 2017 com.jsonmess.audioFileStream. All rights reserved.
//

#import "JSAudioParsedData.h"

@interface JSAudioParsedData()
{
     NSData* _mAudioData;

    AudioStreamPacketDescription _mAudioStreamPacketDescription;
}

@end

@implementation JSAudioParsedData

- (instancetype)initAudioParsedData:(const void *)data audioStreamPacketDescription:(AudioStreamPacketDescription)description
{
    self = [super init];
    if (self)
    {
        [self parsedAudioData:data audioStreamPacketDescription:description];
    }
    return self;
}

- (void)parsedAudioData:(const void *)data audioStreamPacketDescription:(AudioStreamPacketDescription)description
{
    if (description.mDataByteSize != 0 && data != NULL)
    {
        NSUInteger length = description.mDataByteSize;
        NSData *audioData = [NSData dataWithBytes:data length:length];
        _mAudioData = audioData;
        _mAudioStreamPacketDescription = description;
    }
}


- (NSData *)audioData
{
    return _mAudioData;
}

- (AudioStreamPacketDescription)audioStreamPacketDescription
{
    return _mAudioStreamPacketDescription;
}
@end