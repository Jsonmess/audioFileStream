//
// Created by jsonmess on 2017/1/13.
// Copyright (c) 2017 com.jsonmess.camera. All rights reserved.
//

#import "JSAudioPlayItemList.h"

@interface JSAudioPlayItemList ()

@property(nonatomic, assign) NSInteger * mCurrentPlayItemIndex;//当前播放的item index

@property(nonatomic, strong) NSMutableArray * mPlayListArray;//当前播放列表；

@end

@implementation JSAudioPlayItemList

#pragma mark  ---- life cirle
- (instancetype)initAudioPlayItemListWithArray:(NSArray *)listArray
{
    self = [super init];
    if (self)
    {
        self.mPlayListArray = [listArray mutableCopy];
    }
    return self;
}

- (instancetype)init
{
    return [self initAudioPlayItemListWithArray:nil];
}

#pragma mark ---- setting and getting

- (NSMutableArray *)mPlayListArray
{
  if (!_mPlayListArray)
  {
     _mPlayListArray = [NSMutableArray array];
  }
    return _mPlayListArray;
}

- (NSArray *)playListArray
{
    return self.mPlayListArray;
}

- (JSAudioPlayItem *)lastPlayItem
{
   NSInteger lastIndex =
}

- (JSAudioPlayItem *)nextPlayItem
{

}
#pragma mark ---- actions

- (JSAudioPlayItem *)getPlayItemWithIndex:(NSInteger)index
{
    JSAudioPlayItem * tmpItem = nil;
    if (index < self.mPlayListArray.count)
    {
        tmpItem = [self.mPlayListArray objectAtIndex:index];
    }
    return tmpItem;
}
/**
 * 添加音频到列表
 */
- (void)addItemToPlayItemList:(JSAudioPlayItem *)item
{
    if (item)
    {
        [self.mPlayListArray addObject:item];
    }
}

- (void)insertItemToPlayItemList:(JSAudioPlayItem *)item index:(NSInteger)index
{
    if (index >= self.mPlayListArray.count && item)
    {
        [self addItemToPlayItemList:item];
    }
    else
    {
        [self.mPlayListArray insertObject:item atIndex:index];
    }

}

/**
 * 移除音频
 */
- (void)removeItemToPlayItemList:(JSAudioPlayItem *)item
{
   if (item)
   {
       [self.mPlayListArray removeObject:item];
   }
}

- (void)removeItemToPlayItemListWithIndex:(NSInteger)index
{
   if (index < self.mPlayListArray.count)
   {
       [self.mPlayListArray removeObjectAtIndex:index];
   }
}

#pragma mark ----- 其他

@end