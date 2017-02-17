//
// Created by jsonmess on 2017/2/3.
// Copyright (c) 2017 com.jsonmess.audioFileStream. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
/**
 * 音频数据缓存区（现实过程中：1.解析数据要比audio queue 消费数据快 2.解析比较慢情况（网络流））
 */
@interface JSAudioDataBuffer : NSObject

/**
 * 添加解析后的音频数据包
 *
 * @param dataArray 音频数据包数组
 */
- (void)appendAudioParsedData:(NSArray *)dataArray;

/**
 * 获取指定大小的音频数据段，包含多个音频数据包
 *
 * @param dataSize 请求获取数据段 大小
 *
 * @param packetCount  返回数据段包的数量
 *
 * @param descriptions 返回 数据段包的描述数组
 */
- (NSData *)getAudioDataWithDataSize:(UInt32)dataSize packetCount:(UInt32 *)packetCount descriptions:(AudioStreamPacketDescription*)descriptions;


/**
 * 清除所有数据包
 */
- (void)cleanAll;

@end