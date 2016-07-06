//
//  ASBaseVideoPlayer.h
//
//  Created by Alexey Stoyanov on 11/30/15.
//  Copyright © 2015 Alexey Stoyanov. All rights reserved.
//

#import "ASBaseVideoPlayer.h"

#import "ASVideoPlayer.h"
#import "ASVideoEvent.h"

void *ASVP_ContextRateObservation                           = &ASVP_ContextRateObservation;
void *ASVP_ContextStatusObservation                         = &ASVP_ContextStatusObservation;
void *ASVP_ContextCurrentItemObservation                    = &ASVP_ContextCurrentItemObservation;
void *ATVP_ContextBufferObservation                         = &ATVP_ContextBufferObservation;
void *ATVP_ContextBufferLikelyToKeepUpObservation           = &ATVP_ContextBufferLikelyToKeepUpObservation;

NSString const *kASVP_TracksKey                             = @"tracks";
NSString const *kASVP_PlayableKey                           = @"playable";

@interface ASBaseVideoPlayer ()

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

@end

@implementation ASBaseVideoPlayer

- (instancetype)init
{
    if (self = [super init])
    {
        [self setState:ASVideoPlayerState_Init];
    }
    
    return self;
}

#pragma mark - Create Video Player

- (AVPlayer *)createVideoPlayer
{
    return [AVPlayer playerWithPlayerItem:self.playerItem];
}

#pragma mark - Send Events

- (void)sendEvent:(ASVideoEvent *)event
{
    if ([self.eventsDelegate respondsToSelector:@selector(videoPlayer:event:)])
    {
        event.position      = @(CMTimeGetSeconds([self.videoPlayer currentTime]));
        
        [self.eventsDelegate videoPlayer:self event:event];
    }
}

- (void)sendEventPause
{
    [self sendEvent:[[ASVideoEventPause alloc] initWithTimePlayed:@(self.playedTimeSeconds)
                                                         position:nil]];
}

- (void)sendEventPlaying
{
    [self sendEvent:[[ASVideoEventPlaying alloc] initWithTimePlayed:@(self.playedTimeSeconds)
                                                           position:nil]];
}

- (void)sendEventStopped
{
    [self sendEvent:[[ASVideoEventStopped alloc] initWithTimePlayed:@(self.playedTimeSeconds)
                                                           position:nil]];
}

- (void)sendEventEnd
{
    [self sendEvent:[[ASVideoEventEnd alloc] initWithTimePlayed:@(self.playedTimeSeconds)
                                                       position:nil]];
}

- (void)sendEventResignActive
{
    [self sendEvent:[[ASVideoEventResignActive alloc] initWithTimePlayed:@(self.playedTimeSeconds)
                                                                position:nil]];
}

#pragma mark - Change Video Player State

- (void)setState:(ASVideoPlayerState)state
{
    switch (state)
    {
        case ASVideoPlayerState_Unknown:
        {
            if (state == self.state)
            {
                return;
            }
            
            break;
        }
            
        case ASVideoPlayerState_Init:
        {
            if (state == self.state)
            {
                return;
            }
            
            break;
        }
            
        case ASVideoPlayerState_AssetPreparing:
        {
            if (state == self.state)
            {
                return;
            }
            
            break;
        }
            
        case ASVideoPlayerState_ReadyToPlay:
        {
            if (state == self.state)
            {
                return;
            }
            
            if (self.state == ASVideoPlayerState_Playing)
            {
                return;
            }
            
            break;
        }
            
        case ASVideoPlayerState_LoadingContent:
        {
            if (state == self.state)
            {
                return;
            }
            
            break;
        }
            
        case ASVideoPlayerState_Playing:
        {
            if (state == self.state)
            {
                return;
            }
            
            break;
        }
            
        case ASVideoPlayerState_Paused:
        {
            if (state == self.state)
            {
                return;
            }
            
            break;
        }
            
        case ASVideoPlayerState_Suspended:
        {
            if (state == self.state)
            {
                return;
            }
            
            break;
        }
            
        case ASVideoPlayerState_Failed:
        {
            if (state == self.state)
            {
                return;
            }
            
            break;
        }
            
        default:
            break;
    }
    
    ASVP_LOG(@"STATE: %@ -> %@",
             [ASVideoPlayer stateStringFromState:_state],
             [ASVideoPlayer stateStringFromState:state]);
    
    ASVP_CLIENT_LOG(self, @"STATE: %@ -> %@",
                    [ASVideoPlayer stateStringFromState:_state],
                    [ASVideoPlayer stateStringFromState:state]);
    
    _state = state;
}

#pragma mark - Prepare Player

- (void)loadVideoURL:(NSURL *)videoURL
{
    [self setSourceURL:[videoURL copy]];
    
    if (self.sourceURL.absoluteString.length == 0)
    {
        self.userInfo = @{@"error" : [NSError errorWithDomain:@"" code:-1 userInfo:nil]};
        
        [self setState:ASVideoPlayerState_Failed];
        
        return;
    }
    
    [self setState:ASVideoPlayerState_AssetPreparing];
    
    // Add handler for "going to background" notification.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    /*
     Create an asset for inspection of a resource referenced by a given URL.
     Load the values for the asset key "playable".
     */
    self.urlAsset           = [AVURLAsset URLAssetWithURL:self.sourceURL options:nil];
    NSArray *requestedKeys  = @[
                                kASVP_PlayableKey,
                                kASVP_TracksKey
                                ];
    
    /* Tells the asset to load the values of any of the specified keys that are not already loaded. */
    __weak __typeof(self) weakSelf = self;
    [self.urlAsset loadValuesAsynchronouslyForKeys:requestedKeys
                                 completionHandler:
     ^{
         if (weakSelf == nil)
         {
             return;
         }
         __strong __typeof(weakSelf) sself = weakSelf;
         dispatch_async( dispatch_get_main_queue(),
                        ^{
                            /* IMPORTANT: Must dispatch to main queue in order to operate on the AVPlayer and AVPlayerItem. */
                            [self prepareToPlayAsset:sself.urlAsset withKeys:requestedKeys];
                        });
     }];
}

#pragma mark Prepare to play asset, URL

/*
 Invoked at the completion of the loading of the values for all keys on the asset that we require.
 Checks whether loading was successfull and whether the asset is playable.
 If so, sets up an AVPlayerItem and an AVPlayer to play the asset.
 */
- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys
{
    /* Make sure that the value of each key has loaded successfully. */
    for (NSString *thisKey in requestedKeys)
    {
        NSError *error = nil;
        AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
        if (keyStatus == AVKeyValueStatusFailed)
        {
            [self assetFailedToPrepareForPlayback:error];
            return;
        }
        /* If you are also implementing -[AVAsset cancelLoading], add your code here to bail out properly in the case of cancellation. */
    }
    
    /* Use the AVAsset playable property to detect whether the asset can be played. */
    if (!asset.playable)
    {
        /* Generate an error describing the failure. */
        
        [self assetFailedToPrepareForPlayback:nil];
        
        return;
    }
    
    /* At this point we're ready to set up for playback of the asset. */
    
    /* Stop observing our prior AVPlayerItem, if we have one. */
    if (self.playerItem)
    {
        /* Remove existing player item key value observers and notifications. */
        
        [self.playerItem removeObserver:self forKeyPath:@"status"];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.playerItem];
    }
    
    /* Create a new instance of AVPlayerItem from the now successfully loaded AVAsset. */
    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
    
    /* Observe the player item "status" key to determine when it is ready to play. */
    [self.playerItem addObserver:self
                      forKeyPath:@"status"
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:ASVP_ContextStatusObservation];
    
    /* When the player item has played to its end time we'll toggle
     the movie controller Pause button to be the Play button */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.playerItem];
    
    self.seekToZeroBeforePlay = NO;
    
    /* Create new player, if we don't already have one. */
    if (!self.videoPlayer)
    {
        /* Get a new AVPlayer initialized to play the specified player item. */
        [self setVideoPlayer:[self createVideoPlayer]];
        
        /* Observe the AVPlayer "currentItem" property to find out when any
         AVPlayer replaceCurrentItemWithPlayerItem: replacement will/did
         occur.*/
        [self.videoPlayer addObserver:self
                           forKeyPath:@"currentItem"
                              options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                              context:ASVP_ContextCurrentItemObservation];
        
        /* Observe the AVPlayer "rate" property to update the scrubber control. */
        [self.videoPlayer addObserver:self
                           forKeyPath:@"rate"
                              options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                              context:ASVP_ContextRateObservation];
    }
    
    /* Make our new AVPlayerItem the AVPlayer's current item. */
    if (self.videoPlayer.currentItem != self.playerItem)
    {
        /* Replace the player item with a new player item. The item replacement occurs
         asynchronously; observe the currentItem property to find out when the
         replacement will/did occur
         
         If needed, configure player item here (example: adding outputs, setting text style rules,
         selecting media options) before associating it with a player
         */
        [self.videoPlayer replaceCurrentItemWithPlayerItem:self.playerItem];
    }
}

#pragma mark -
#pragma mark Asset Key Value Observing
#pragma mark

#pragma mark Key Value Observer for player rate, currentItem, player item status

/* ---------------------------------------------------------
 **  Called when the value at the specified key path relative
 **  to the given object has changed.
 **  Adjust the movie play and pause button controls when the
 **  player item "status" value changes. Update the movie
 **  scrubber control when the player item is ready to play.
 **  Adjust the movie scrubber control when the player item
 **  "rate" value changes. For updates of the player
 **  "currentItem" property, set the AVPlayer for which the
 **  player layer displays visual output.
 **  NOTE: this method is invoked on the main queue.
 ** ------------------------------------------------------- */

- (void)observeValueForKeyPath:(NSString*) path
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
{
    /* AVPlayerItem "status" property value observer. */
    if (context == ASVP_ContextStatusObservation)
    {
        //TODO:
        //        [self.vwVideo syncPlayPauseButtons];
        
        AVPlayerItemStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status)
        {
                /* Indicates that the status of the player is not yet known because
                 it has not tried to load new media resources for playback */
            case AVPlayerItemStatusUnknown:
            {
                [self removePlayerTimeObserver];
                [self syncScrubber];
                
                [self setState:ASVideoPlayerState_Unknown];
            }
                break;
                
            case AVPlayerItemStatusReadyToPlay:
            {
                /* Once the AVPlayerItem becomes ready to play, i.e.
                 [playerItem status] == AVPlayerItemStatusReadyToPlay,
                 its duration can be fetched from the item. */
                
                [self initScrubberTimer];
                
                if (self.initialSeek != 0.0)
                {
                    [self.videoPlayer seekToTime:CMTimeMakeWithSeconds(self.initialSeek, NSEC_PER_SEC)
                               completionHandler:^(BOOL finished)
                     {
                         
                     }];
                    self.initialSeek = 0.0f;
                }
                
                self.videoPlayer.closedCaptionDisplayEnabled = self.enableSubtitles;
                
                [self setState:ASVideoPlayerState_Playing];
            }
                break;
                
            case AVPlayerItemStatusFailed:
            {
                AVPlayerItem *playerItem = (AVPlayerItem *)object;
                [self assetFailedToPrepareForPlayback:playerItem.error];
            }
                break;
        }
    }
    /* AVPlayer "rate" property value observer. */
    else if (context == ASVP_ContextRateObservation)
    {
        if (self.isPlaying)
        {
            [self setState:ASVideoPlayerState_Playing];
        }
        else
        {
            [self setState:ASVideoPlayerState_Paused];
        }
    }
    /* AVPlayer "currentItem" property observer.
     Called when the AVPlayer replaceCurrentItemWithPlayerItem:
     replacement will/did occur. */
    else if (context == ASVP_ContextCurrentItemObservation)
    {
        AVPlayerItem *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];
        
        /* Is the new player item null? */
        if (newPlayerItem == (id)[NSNull null])
        {
            [self setState:ASVideoPlayerState_Suspended];
        }
        else /* Replacement of player currentItem has occurred */
        {
            if ([self.delegate respondsToSelector:@selector(outputViewForVideoPlayer:)])
            {
                AVPlayerLayer *playerLayer = [self.delegate outputViewForVideoPlayer:self];
                
                [playerLayer setPlayer:self.videoPlayer];
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
            }
            
            // Play the video.
            [self.videoPlayer play];
            
            [self setState:ASVideoPlayerState_ReadyToPlay];
        }
    }
    else
    {
        [super observeValueForKeyPath:path ofObject:object change:change context:context];
    }
}

/* Cancels the previously registered time observer. */
-(void)removePlayerTimeObserver
{
    if (self.timeObserver)
    {
        [self.videoPlayer removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
    }
}

#pragma mark - Handle Notifications

#pragma mark - Handle Video End

// Called when the player item has played to its end time.
- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    // After the movie has played to its end time, seek back to time zero to play it again.
    self.seekToZeroBeforePlay = YES;
    
    // Send video logging ping when video has reached the end.
    [self sendEventEnd];
}

#pragma mark - Error Handling

- (void)assetFailedToPrepareForPlayback:(NSError *)error
{
    [self removePlayerTimeObserver];
    [self syncScrubber];
    
    self.userInfo = @{@"error" : error};
    
    [self setState:ASVideoPlayerState_Failed];
}

#pragma mark - Duration

- (CMTime)playerItemDuration
{
    AVPlayerItem *playerItem = [self.videoPlayer currentItem];
    if (playerItem.status == AVPlayerItemStatusReadyToPlay)
    {
        return([playerItem duration]);
    }
    else if (playerItem.status == AVPlayerItemStatusUnknown && self.videoPlayer.externalPlaybackActive)
    {
        return([playerItem duration]);
    }
    
    return(kCMTimeInvalid);
}

#pragma mark -
#pragma mark Movie scrubber control

/* ---------------------------------------------------------
 **  Methods to handle manipulation of the movie scrubber control
 ** ------------------------------------------------------- */

/* Requests invocation of a given block during media playback to update the movie scrubber control. */
-(void)initScrubberTimer
{
    double interval = .1f;
    
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration))
    {
        return;
    }
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration))
    {
        interval = 1.0f;
    }
    
    /* Update the scrubber during normal playback. */
    __weak ASBaseVideoPlayer *weakSelf = self;
    self.timeObserver = [self.videoPlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC)
                                                                       queue:NULL /* If you pass NULL, the main queue is used. */
                                                                  usingBlock:^(CMTime time)
                         {
                             [weakSelf syncScrubber];
                         }];
}

/* Set the scrubber based on the player current time. */
- (void)syncScrubber
{
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration))
    {
        //TODO:
        //        self.vwVideo.scrubberMinValue = 0.0;
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration))
    {
        double time = CMTimeGetSeconds([self.videoPlayer currentTime]);
        
        if ([self.delegate respondsToSelector:@selector(videoPlayer:currentTime:timeLeft:duration:)])
        {
            [self.delegate videoPlayer:self currentTime:time timeLeft:duration - time duration:duration];
        }
        
        // Sync playedTime by starting to track played time when video starts playing.
        if (time >= 1.0 && [self isPlaying])
        {
            self.playedTimeSeconds++;
        }
        
        // Send video logging ping every 30 seconds of actual played time.
        if ((self.playedTimeSeconds >= 1) && ((self.playedTimeSeconds % 30) == 0))
        {
            [self sendEventPlaying];
        }
    }
}

#pragma mark - Public Methods

- (BOOL)isScrubbing
{
    return self.restoreAfterScrubbingRate != 0.f;
}

- (BOOL)isPlaying
{
    return  [self.videoPlayer rate] != 0.f;
}

- (void)beginScrubbing
{
    self.restoreAfterScrubbingRate = [self.videoPlayer rate];
    [self.videoPlayer setRate:0.f];
    
    /* Remove previous timer. */
    [self removePlayerTimeObserver];
}

/* The user has released the movie thumb control to stop scrubbing through the movie. */
- (void)endScrubbing
{
    if (self.restoreAfterScrubbingRate)
    {
        [self.videoPlayer setRate:self.restoreAfterScrubbingRate];
        self.restoreAfterScrubbingRate = 0.0f;
    }
}

/* Set the player current time to match the scrubber position. */
- (void)seekToTime:(double)time
{
    //    if (!self.isSeeking)
    {
        self.isSeeking = YES;
        
        CMTime playerDuration = [self playerItemDuration];
        if (CMTIME_IS_INVALID(playerDuration))
        {
            return;
        }
        
        double duration = CMTimeGetSeconds(playerDuration);
        if (isfinite(duration))
        {
            [self.videoPlayer seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
        }
    }
}

- (double)videoDuration
{
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration))
    {
        return 0.0;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration))
    {
        return duration;
    }
    
    return DBL_MAX;
}

- (void)play
{
    if (self.isPlaying)
    {
        return;
    }
    
    /* If we are at the end of the movie, we must seek to the beginning first
     before starting playback. */
    if (YES == self.seekToZeroBeforePlay)
    {
        self.seekToZeroBeforePlay = NO;
        [self.videoPlayer seekToTime:kCMTimeZero];
    }
    
    [self.videoPlayer play];
}

- (void)pause
{
    if (self.isPlaying == NO)
    {
        return;
    }
    
    [self.videoPlayer pause];
    
    // Send event "Pause".
    [self sendEventPause];
}

- (void)enableSubtitles:(BOOL)enable
{
    self.enableSubtitles = enable;
}

- (void)initialSeek:(double)seekTo
{
    self.initialSeek = seekTo;
}

#pragma mark - Reset video player
- (void)reset
{
    [self setState:ASVideoPlayerState_Suspended];
    
    [self.urlAsset cancelLoading];
    
    // Send event "End".
    [self sendEventEnd];
    
    [self.videoPlayer pause];
    
    [self removePlayerTimeObserver];
    
    [self.videoPlayer removeObserver:self
                          forKeyPath:@"rate"
                             context:ASVP_ContextRateObservation];
    
    [self.videoPlayer removeObserver:self
                          forKeyPath:@"currentItem"
                             context:ASVP_ContextCurrentItemObservation];
    
    [self.videoPlayer.currentItem removeObserver:self
                                      forKeyPath:@"status"
                                         context:ASVP_ContextStatusObservation];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:self.playerItem];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillResignActiveNotification
                                                  object:nil];
    
    self.playerItem = nil;
    
    self.videoPlayer = nil;
}

#pragma mark - Dealloc

- (void)dealloc
{
    [self reset];
}

#pragma mark - Handle notifications

- (void)appWillResignActive:(NSNotification *)notification
{
    [self pause];
}

#pragma mark - Helpers

+ (NSString *)stateStringFromState:(ASVideoPlayerState)state
{
    NSString *stateString = nil;
    
    switch (state)
    {
        case ASVideoPlayerState_Unknown:
        {
            stateString = @"Unknown";
            
            break;
        }
            
        case ASVideoPlayerState_Init:
        {
            stateString = @"Init";
            
            break;
        }
            
        case ASVideoPlayerState_AssetPreparing:
        {
            stateString = @"Preparing";
            
            break;
        }
            
        case ASVideoPlayerState_ReadyToPlay:
        {
            stateString = @"ReadyToPlay";
            
            break;
        }
            
        case ASVideoPlayerState_LoadingContent:
        {
            stateString = @"LoadingContent";
            
            break;
        }
            
        case ASVideoPlayerState_Playing:
        {
            stateString = @"Playing";
            
            break;
        }
            
        case ASVideoPlayerState_Paused:
        {
            stateString = @"Paused";
            
            break;
        }
            
        case ASVideoPlayerState_Seeking:
        {
            stateString = @"Seeking";
            
            break;
        }
            
        case ASVideoPlayerState_Suspended:
        {
            stateString = @"Suspended";
            
            break;
        }
            
        case ASVideoPlayerState_Failed:
        {
            stateString = @"Failed";
            
            break;
        }
            
        default:
            break;
    }
    
    return stateString;
}

@end
