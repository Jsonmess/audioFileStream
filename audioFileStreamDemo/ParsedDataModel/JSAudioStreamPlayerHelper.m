//
// Created by jsonmess on 2017/1/19.
// Copyright (c) 2017 com.jsonmess.audioFileStream. All rights reserved.
//

#import "JSAudioStreamPlayerHelper.h"


@implementation JSAudioStreamPlayerHelper


+ (NSError *)createErrorWithOSStatus:(OSStatus)status
{
    NSError *error = nil;

    if (status != noErr)
    {
        NSDictionary *userInfo = @{
                                    @"status":@(-1),
                                    @"msg":@"",
                                    @"errorCreator" : @"jsonmess"
                                  };
        error = [[NSError alloc] initWithDomain:NSOSStatusErrorDomain code:status userInfo:userInfo];
    }
    return error;
}
@end
