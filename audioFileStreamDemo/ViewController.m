//
//  ViewController.m
//  audioFileStreamDemo
//
//  Created by jsonmess on 2017/1/19.
//  Copyright (c) 2017 com.jsonmess.audioFileStream. All rights reserved.
//

#import "ViewController.h"
#import "JSAudioFileStream.h"

#import "JSAudioEventLoop.h"
@interface ViewController ()<JSAudioFileStreamDelegate>
@property (nonatomic, strong) JSAudioFileStream *audioFileStream;
@property (nonatomic, strong) JSAudioEventLoop *runloop;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.runloop =  [[JSAudioEventLoop alloc] init];
    [self.runloop startEventLoop];
    //return;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"MP3Sample" ofType:@"mp3"];
    //创建读的文件连接器
    NSFileHandle *file = [NSFileHandle fileHandleForReadingAtPath:path];
    unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] fileSize];
    NSError *error = nil;
    _audioFileStream = [[JSAudioFileStream alloc] initWithFileType:kAudioFileMP3Type fileSize:fileSize delegate:self];
    [_audioFileStream openAudioFileStreamWithError:&error];
    if (error)
    {
        _audioFileStream = nil;
        NSLog(@"create audio file stream failed, error: %@",[error description]);
    }
    else
    {
        NSLog(@"audio file opened.");
        if (file)
        {
            NSUInteger lengthPerRead = 10000;
            while (fileSize > 0)
            {
                NSData *data = [file readDataOfLength:lengthPerRead];
                fileSize -= [data length];
                [_audioFileStream parseData:data parseError:&error];
                if (error)
                {
                    if (error.code == kAudioFileStreamError_NotOptimized)
                    {
                        NSLog(@"audio not optimized.");
                    }
                    break;
                }
                [_audioFileStream fetchAudioFileStreamMagicCookie];
            }
            NSLog(@"audio format: bitrate = %f, duration = %lf.",_audioFileStream.bitRate,_audioFileStream.audioDuration);
            [_audioFileStream closeAudioFileStream];
            _audioFileStream = nil;
            NSLog(@"audio file closed.");
            
            
            [file closeFile];
        }
    }
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)audioFileStreamReadyToProducePacket:(JSAudioFileStream *)audioFileStream
{
    NSLog(@"准备上产包");
}

- (void)audioFileStream:(JSAudioFileStream *)audioFileStream parsedAudioData:(NSArray *)parsedData
{
    NSLog(@"本次解析了------%d 个数据包",parsedData.count);
}
@end
