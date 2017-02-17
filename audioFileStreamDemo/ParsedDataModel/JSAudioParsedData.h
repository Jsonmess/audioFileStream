//
// Created by jsonmess on 2017/1/22.
// Copyright (c) 2017 com.jsonmess.audioFileStream. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface JSAudioParsedData : NSObject

@property (nonatomic, strong, readonly) NSData* audioData;

@property(nonatomic, assign, readonly) AudioStreamPacketDescription audioStreamPacketDescription;


/**
 *  create  JSAudioParsedData
 *  @param data 音频数据data
 *  @param description 音频数据data 所在的音频包的描述
 */
- (instancetype)initAudioParsedData:(const void*)data audioStreamPacketDescription:(AudioStreamPacketDescription)description;

/**
 * 添加解析后的数据
 * @param data 音频数据data
 * @param description 音频数据data 所在的音频包的描述
 */

- (void)parsedAudioData:(const void *)data audioStreamPacketDescription:(AudioStreamPacketDescription)description;
@end