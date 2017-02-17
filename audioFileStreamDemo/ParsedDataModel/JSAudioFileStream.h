//
// Created by jsonmess on 2017/1/13.
// Copyright (c) 2017 jsonmess All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@class JSAudioFileStream;

@protocol JSAudioFileStreamDelegate <NSObject>

/**
 * 解析后数据回调
 */
- (void)audioFileStream:(JSAudioFileStream*)audioFileStream parsedAudioData:(NSArray *)parsedData;

/**
 * 通知外部，AudioFileStream 基本完成音频流信息解析
 */
- (void)audioFileStreamReadyToProducePacket:(JSAudioFileStream *)audioFileStream;

@end

/**
 *  @音频流解析
 *
 *  @info：用于本地音频文件和网络音频流
 */
@interface JSAudioFileStream : NSObject

/*****音频基本信息******/

@property (nonatomic, assign,readonly) NSTimeInterval audioDuration;//时长

@property(nonatomic, assign,readonly) float  bitRate; //kbps

@property(nonatomic, assign, readonly) AudioFileTypeID fileTypeID;

@property(nonatomic, assign, readonly) AudioStreamBasicDescription streamFileFormat;//文件流基本信息

@property(nonatomic, assign, readonly) AudioFileStreamID fileStreamID;

/**
 *  初始化
 *
 *  @param typeId 文件类型，参考 AudioFileTypeID
 *
 *  @param size 文件流数据大小
 *
 *  @param delegate  delegate
 */
- (instancetype)initWithFileType:(AudioFileTypeID)typeId
                        fileSize:(unsigned long long)size
                        delegate:(id)delegate NS_DESIGNATED_INITIALIZER;

/**
 *  打开音频流
 *
 *  @param error error
 */
- (void)openAudioFileStreamWithError:(NSError **)error;

/**
 * 关闭音频流
 */
- (void)closeAudioFileStream;
/**
 * 解析音频流原始数据
 *
 * @param originalData 数据源
 *
 * @param error  error
 */
- (BOOL)parseData:(NSData *)originalData parseError:(NSError **)error;


/**
 * 快进 解析
 *
 * @param position 当前快进的位置
 */
- (SInt64)seekParseDataWithPosition:(NSTimeInterval*)position;


/**
 * 获取 音频流 的MagicCookie
 * magicCookie 是音频文件格式中描述
 * 一般用在基于ISO基础媒体文件格式如MP4和M4A的文件上
 *
 * @return  magicCookie
 */
- (NSData *)fetchAudioFileStreamMagicCookie;
@end

