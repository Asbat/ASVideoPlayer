//
//  ASBaseVideoPlayer.h
//
//  Created by Alexey Stoyanov on 11/30/15.
//  Copyright © 2015 Alexey Stoyanov. All rights reserved.
//

#import "ASBaseVideoPlayer.h"

// Forward
//[
@class ASBaseVideoPlayer;
@class ASVideoEvent;
//]

@interface ASBaseVideoPlayer (Private)

@property (nonatomic, strong) NSURL                         *sourceURL;

@property (nonatomic, strong) AVPlayer                      *videoPlayer;
@property (nonatomic, strong) AVPlayerItem                  *playerItem;
@property (nonatomic, strong) AVURLAsset                    *urlAsset;
@property (nonatomic, weak) id                              timeObserver;

@property (nonatomic, assign) float                         restoreAfterScrubbingRate;

@property (nonatomic, assign) BOOL                          seekToZeroBeforePlay;
@property (nonatomic, assign) BOOL                          isSeeking;
@property (nonatomic, assign) int                           playedTimeSeconds;
@property (nonatomic, assign) double                        initialSeek;
@property (nonatomic, assign) BOOL                          enableSubtitles;

@property (nonatomic, assign) ASVideoPlayerState            state;
@property (nonatomic, strong) NSDictionary                  *userInfo;

#pragma mark - Send Events
- (void)sendEvent:(ASVideoEvent *)event;
- (void)sendEventPause;
- (void)sendEventPlaying;
- (void)sendEventEnd;

- (void)syncScrubber;

@end
