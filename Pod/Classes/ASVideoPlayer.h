//
//  ASVideoPlayer.h
//
//  Created by Alexey Stoyanov on 11/30/15.
//  Copyright © 2015 Alexey Stoyanov. All rights reserved.
//

#import <Foundation/Foundation.h>

// Forward
//[
@class AVPlayer;
@class ASVideoEvent;
@class ATVideoConfiguration;
@class ASVideoPlayer;
@class AVPlayerLayer;
//]

typedef NS_ENUM(NSUInteger, ASVideoPlayerEventType)
{
    ASVideoPlayerEventType_Playing,
    
    ASVideoPlayerEventType_Pause,
    
    ASVideoPlayerEventType_End,
};

typedef NS_ENUM(NSInteger, ASVideoPlayerState)
{
    ASVideoPlayerState_Unknown          = -1,
    
    ASVideoPlayerState_Init,
    
    ASVideoPlayerState_Preparing,
    
    ASVideoPlayerState_ReadyToPlay,
    
    ASVideoPlayerState_LoadingContent,
    
    ASVideoPlayerState_Playing,
    
    ASVideoPlayerState_Paused,
    
    ASVideoPlayerState_Suspended,
    
    ASVideoPlayerState_Failed,
};

@protocol ASVideoPlayerDelegate <NSObject>

- (void)videoPlayer:(ASVideoPlayer *)videoPlayer event:(ASVideoEvent *)event;
- (void)videoPlayer:(ASVideoPlayer *)videoPlayer currentTime:(double)currentTime timeLeft:(double)timeLeft duration:(double)duration;

- (AVPlayerLayer *)outputViewForVideoPlayer:(ASVideoPlayer *)videoPlayer;

@end

@interface ASVideoPlayer : NSObject

@property (nonatomic, strong, readonly) NSURL                   *sourceURL;
@property (nonatomic, weak) id<ASVideoPlayerDelegate>           delegate;

@property (nonatomic, strong, readonly) AVPlayer                *videoPlayer;
@property (nonatomic, assign, readonly) BOOL                    isPlaying;

@property (nonatomic, assign, readonly) ASVideoPlayerState      state;

- (void)loadVideoURL:(NSURL *)videoURL;

- (void)play;
- (void)initialSeek:(double)seekTo;
- (void)pause;
- (BOOL)isScrubbing;
- (void)beginScrubbing;
- (void)seekToTime:(double)time;
- (void)endScrubbing;
- (void)reset;
- (void)enableSubtitles:(BOOL)enable;

- (double)videoDuration;

@end
