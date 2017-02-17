//
// Created by jsonmess on 2017/1/13.
// Copyright (c) 2017 com.jsonmess.camera. All rights reserved.
//

#import "JSAudioStreamer.h"
#import "JSAudioPlayItem.h"
#import "JSAudioPlayItemList.h"


@interface  JSAudioStreamer()

@property (nonatomic, strong) JSAudioPlayItemList *playItemList;//播放列表

@end

@implementation JSAudioStreamer

#pragma mark --- init life cirle

- (instancetype)initWithPlayItems:(NSArray<JSAudioPlayItem* >*)items
{
    self = [super init];
    if(self)
    {
        [self setUpStreamer:items];
    }
    return self;
}

- (instancetype)init
{
    return [self initWithPlayItems:nil];
}

#pragma mark ---- set up
- (void)setUpStreamer:(NSArray<JSAudioPlayItem* >*)items
{
    self.playItemList = [[JSAudioPlayItemList alloc] initAudioPlayItemListWithArray:items];
}

#pragma mark  ---- public

- (void)setPlayItem:(JSAudioPlayItem*)item
{
    //设置streamer item



}


@end