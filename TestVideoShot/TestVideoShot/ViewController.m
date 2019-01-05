//
//  ViewController.m
//  TestVideoShot
//
//  Created by iOS on 2019/1/4.
//  Copyright © 2019 weiman. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *image;
@property (strong, nonatomic) NSMutableArray * imageArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self getImage];
    //[self getImages];
}

- (void)getImage {
    
    NSURL * url = [[NSBundle mainBundle] URLForResource:@"launch_guide" withExtension:@"mp4"];
    _imageArray = [NSMutableArray array];
    
    //获取视频时长，单位：秒
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:url options:nil];
    CMTime length = urlAsset.duration;
    int second = (int)length.value / length.timescale;
    NSLog(@"second: %d", second);
    
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:urlAsset];
    generator.appliesPreferredTrackTransform = YES;
    generator.maximumSize = self.view.bounds.size;
    //下面两句是截取每一帧的关键
    generator.requestedTimeToleranceBefore = kCMTimeZero;
    generator.requestedTimeToleranceAfter = kCMTimeZero;
    
    NSMutableArray *timeArray = [NSMutableArray array];
    for (int i = 1; i < second + 1 ; i++) {
        [timeArray addObject:[NSValue valueWithCMTime:CMTimeMake(i, 1)]];
    }
    
    //开始截图
    __weak ViewController * weakself = self;
    [generator generateCGImagesAsynchronouslyForTimes:timeArray completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
        
        UIImage *imageSen = [UIImage imageWithCGImage:image];
        [weakself.imageArray addObject:imageSen];
        
        UIImage * image3 = [self.imageArray lastObject];
        dispatch_queue_t mainQueue = dispatch_get_main_queue();
        dispatch_async(mainQueue, ^{
            [weakself.image setImage:image3];
        });
        NSLog(@"count: %d", weakself.imageArray.count);
    }];
}

-(void) getImages {
    
    NSURL * url = [[NSBundle mainBundle] URLForResource:@"launch_guide" withExtension:@"mp4"];
    _imageArray = [NSMutableArray array];
    
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:url options:nil];
    CMTime length = urlAsset.duration;
    int second = (int)length.value / length.timescale;
    NSLog(@"second: %d", second);
    
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:urlAsset];
    generator.appliesPreferredTrackTransform = NO;
    generator.maximumSize = self.view.bounds.size;
    NSError *error = nil;
    for (float i = 1; i < second + 1 ; i += 1) {
        //不会CMTime就去了解一下
        CGImageRef img = [generator copyCGImageAtTime:CMTimeMake(i, 10) actualTime:NULL error:&error];
        UIImage *image = [UIImage imageWithCGImage: img];
        [self.imageArray addObject:image];
    }
    
    NSLog(@"imageArray = %@",_imageArray);
    UIImage * image3 = [self.imageArray lastObject];
    [self.image setImage:image3];
    
}


@end
