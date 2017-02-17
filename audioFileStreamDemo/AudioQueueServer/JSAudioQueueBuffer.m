//
// Created by jsonmess on 2017/1/23.
// Copyright (c) 2017 com.jsonmess.audioFileStream. All rights reserved.
//

#import "JSAudioQueueBuffer.h"


@implementation JSAudioQueueBuffer

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.isEmpty = YES;
    }
    return self;
}


@end