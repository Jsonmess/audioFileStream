//
// Created by jsonmess on 2017/1/13.
// Copyright (c) 2017 com.jsonmess.camera. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
typedef NS_ENUM(NSInteger,AudioPlayItemType)
{
    kAudioPlayItemRemote = 0,

    kAudioPlayItemLocal
};
/**
 * item for Audio play
 */
@interface JSAudioPlayItem : NSObject

/**
 * 音频基本信息
 */
@property (nonatomic, copy) NSString *itemTitle;//标题

@property (nonatomic, copy) NSString *coverUrl;//专辑封面

@property (nonatomic, copy) NSString *singer;//歌手

@property (nonatomic, copy) NSString *playItemUrl;//播放源地址

@property (nonatomic, copy) NSString *itemCreateTime;//音频创建时间

/**
 * 音频额外信息
 */
@property(nonatomic, copy) NSString *itemDuration;//音频时长

@property(nonatomic, copy) NSString *itemStytle;//风格（年代、流行、古典....）

@property(nonatomic, copy) NSString *itemRelateLyrics;//关联歌词


/**
 * 其他
 */
@property(nonatomic, assign, readonly)  AudioPlayItemType playItemType;

@property(nonatomic, assign, readonly)  AudioFileTypeID fileTypeID;


@end