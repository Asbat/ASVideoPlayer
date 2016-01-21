//
//  ATPlaybackView.m
//  AcornTV
//
//  Created by Alexey Stoyanov on 12/3/15.
//  Copyright © 2015 Qello. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "ATPlaybackView.h"

@implementation ATPlaybackView

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (void)addPlayer:(AVPlayer *)player
{
    [(AVPlayerLayer*)[self layer] setPlayer:player];
}

- (AVPlayer*)player
{
    return [(AVPlayerLayer*)[self layer] player];
}

- (AVPlayerLayer*)playerLayer
{
    return (AVPlayerLayer*)[self layer];
}

- (void)setVideoFillMode:(NSString *)fillMode
{
    // Specifies how the video will be displayed within the player's
    // layer bounds. AVLayerVideoGravityResizeAspect is the default.
    
    AVPlayerLayer *playerLayer = (AVPlayerLayer*)[self layer];
    playerLayer.videoGravity = fillMode;
}

@end
