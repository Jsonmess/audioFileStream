//
// Created by jsonmess on 2017/1/19.
// Copyright (c) 2017 com.jsonmess.audioFileStream. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface JSAudioStreamPlayerHelper : NSObject


/********* 处理错误 *********/

+ (NSError *)createErrorWithOSStatus:(OSStatus)status;

/********* 处理错误 end *********/
@end