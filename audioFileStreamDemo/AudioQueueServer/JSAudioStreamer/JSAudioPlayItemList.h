//
// Created by jsonmess on 2017/1/13.
// Copyright (c) 2017 com.jsonmess.camera. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSAudioPlayItem.h"

typedef NS_ENUM(NSInteger,JSAudioPlayMode)
{
    JSAudioPlayModeInOrder = 0,
    JSAudioPlayModeInOrderRandom,
    JSAudioPlayModeIn

}

/**
 * 播放音频列表
 */
@interface JSAudioPlayItemList : NSObject

@property(nonatomic, assign, readonly) NSInteger * currentPlayItemIndex;//当前播放的item index

@property (nonatomic, strong, nullable, readonly) JSAudioPlayItem *nextPlayItem;//下一次播放item

@property (nonatomic, strong, nullable, readonly) JSAudioPlayItem *lastPlayItem;//上一次播放item

@property (nonatomic, strong, readonly) NSArray *playListArray;//当前播放列表；

/**
 * init
 */

- (instancetype)initAudioPlayItemListWithArray:(NSArray *)listArray NS_DESIGNATED_INITIALIZER;


/**
 * 
 */

/**
 * 添加音频到列表
 */
- (void)addItemToPlayItemList:(JSAudioPlayItem *)item;

- (void)insertItemToPlayItemList:(JSAudioPlayItem *)item index:(NSInteger)index;

/**
 * 移除音频
 */
- (void)removeItemToPlayItemList:(JSAudioPlayItem *)item;

- (void)removeItemToPlayItemListWithIndex:(NSInteger)index;

/**
 * 获取音频item
 */
- (JSAudioPlayItem *)getPlayItemWithIndex:(NSInteger)index;

@end