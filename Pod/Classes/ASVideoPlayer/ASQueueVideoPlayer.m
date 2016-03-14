//
//  ASQueueVideoPlayer.m
//
//  Created by Alexey Stoyanov on 11/30/15.
//  Copyright © 2015 Alexey Stoyanov. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "ASQueueVideoPlayer.h"
#import "ASBaseVideoPlayer_Private.h"

#define ASVP_DEBUG

#ifdef ASVP_DEBUG
    #define ASVP_LOG( s, ... ) NSLog( @"<%p %@:%@:(%d)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], [[NSString stringWithUTF8String:__func__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] );
#else
    #define ASVP_LOG( s, ... )
#endif

static void *ASVP_ContextCurrentItemDurationObservation                 = &ASVP_ContextCurrentItemDurationObservation;
static void *ASVP_ContextCurrentItemMetabservation                      = &ASVP_ContextCurrentItemMetabservation;

@interface ASQueueVideoPlayer ()
{
    UIBackgroundTaskIdentifier _bgExtendedTask;
}

@property (nonatomic, strong) NSMutableArray<ASQueuePlayerItem *>       *playlistMutable;
@property (nonatomic, strong) NSMutableDictionary                       *itemsDict;

@property (nonatomic, strong) ASQueuePlayerItem                         *currentItem;

@property (nonatomic, assign) BOOL                                      stopPreparingAssets;
@property (nonatomic, strong) ASQueuePlayerItem                         *currentPreparingItem;

@end

@implementation ASQueueVideoPlayer

- (void)setup
{
    if (self.videoPlayer != nil)
    {
        // Video player already created.
        return;
    }
    
    self.videoPlayer            = [AVQueuePlayer new];
    
    self.playlistMutable        = [NSMutableArray<ASQueuePlayerItem *> array];
    self.itemsDict              = [NSMutableDictionary new];
    
    [self addAirPlayFunctionality];

    [self initScrubberTimer];
    
    // Add handler for "going to background" notification.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    // Create notification observers for background tasks.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resetBackgroundTask:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stopBackgroundTask:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    /* Observe the AVPlayer "rate" property to update the scrubber control. */
    [self addObserver:self
           forKeyPath:@"videoPlayer.rate"
              options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
              context:&ASVP_ContextRateObservation];
    
    /* Observe the AVPlayer "currentItem" property to find out when any
     AVPlayer replaceCurrentItemWithPlayerItem: replacement will/did
     occur.*/
    [self addObserver:self
           forKeyPath:@"videoPlayer.currentItem"
              options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
              context:&ASVP_ContextCurrentItemObservation];
    
    [self addObserver:self
           forKeyPath:@"videoPlayer.currentItem.status"
              options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
              context:&ASVP_ContextStatusObservation];
    
    [self addObserver:self
           forKeyPath:@"videoPlayer.currentItem.duration"
              options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
              context:&ASVP_ContextCurrentItemDurationObservation];
    
    [self addObserver:self
           forKeyPath:@"videoPlayer.currentItem.playbackBufferEmpty"
              options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
              context:&ATVP_ContextBufferObservation];
    
    [self addObserver:self
           forKeyPath:@"videoPlayer.currentItem.timedMetadata"
              options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
              context:&ASVP_ContextCurrentItemMetabservation];
    
    if ([self.delegate respondsToSelector:@selector(outputViewForVideoPlayer:)])
    {
        AVPlayerLayer *playerLayer = [self.delegate outputViewForVideoPlayer:self];
        
        [playerLayer setPlayer:self.videoPlayer];
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    }
    
    [self setState:ASVideoPlayerState_Init];
}

#pragma mark - Reset video player
- (void)reset
{
    // Send event "End".
    [self sendEventEnd];
    
    [self.videoPlayer pause];
    
    [self removeScrubberTimer];

    [self removeObserver:self
              forKeyPath:@"videoPlayer.rate"
                 context:&ASVP_ContextRateObservation];
    
    [self removeObserver:self
              forKeyPath:@"videoPlayer.currentItem"
                 context:&ASVP_ContextCurrentItemObservation];
    
    [self removeObserver:self
              forKeyPath:@"videoPlayer.currentItem.status"
                 context:&ASVP_ContextStatusObservation];
    
    [self removeObserver:self
              forKeyPath:@"videoPlayer.currentItem.duration"
                 context:&ASVP_ContextCurrentItemDurationObservation];
    
    [self removeObserver:self
              forKeyPath:@"videoPlayer.currentItem.playbackBufferEmpty"
                 context:ATVP_ContextBufferObservation];
    
    [self removeObserver:self
              forKeyPath:@"videoPlayer.currentItem.timedMetadata"
                 context:&ASVP_ContextCurrentItemMetabservation];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillResignActiveNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
    
    self.videoPlayer = nil;
    
    [self setState:ASVideoPlayerState_Suspended];
}

- (void)appendItemsToPlaylist:(NSArray<ASQueuePlayerItem *> *)items
{
    for (ASQueuePlayerItem *item in items)
    {
        // Add only unique items.
        if (self.itemsDict[item.asset.URL.absoluteString] == nil)
        {
            [self.playlistMutable addObject:item];
            self.itemsDict[item.asset.URL.absoluteString] = item;
            
        }
    }
}

- (void)prepareItems:(NSUInteger)startIndex
          completion:(void (^)())completion
{
    if (self.stopPreparingAssets)
    {
        ASVP_LOG(@"Preparing Interrupted.");
        
        [self.currentPreparingItem cancelPreparing];
        
        if (completion)
        {
            completion();
        }
        
        return;
    }
    
    if (startIndex >= self.playlist.count)
    {
        ASVP_LOG(@"Preparing Completed.");
        if (completion)
        {
            completion();
        }
        
        return;
    }
    
    self.currentPreparingItem = self.playlist[startIndex];
    
    /* Tells the asset to load the values of any of the specified keys that are not already loaded. */
    __weak __typeof(self) weakSelf = self;
    [self.currentPreparingItem prepareItem:^(NSError *error)
    {
        dispatch_async( dispatch_get_main_queue(),
                       ^{
                           if (weakSelf.stopPreparingAssets)
                           {
                               ASVP_LOG(@"Preparing Interrupted.");
                               
                               [weakSelf.currentPreparingItem cancelPreparing];
                               
                               if (completion)
                               {
                                   completion();
                               }
                               
                               return;
                           }
                           
                           if (error)
                           {
                               [weakSelf assetFailedToPrepareForPlayback:error];
                           }
                           
                           /* IMPORTANT: Must dispatch to main queue in order to operate on the AVQueuePlayer and AVPlayerItem. */
                           [(AVQueuePlayer *)weakSelf.videoPlayer insertItem:[AVPlayerItem playerItemWithAsset:weakSelf.currentPreparingItem.asset]
                                                                   afterItem:nil];
                           
                           // Start playing.
                           if (weakSelf.isPlaying == NO)
                           {
                               [weakSelf play];
                           }
                           
                           [weakSelf prepareItems:startIndex + 1 completion:completion];
                       });
    }];
}

#pragma mark - Clear Playlist

- (void)clearPlaylist
{
    [((AVQueuePlayer *)self.videoPlayer) removeAllItems];
    [self.itemsDict removeAllObjects];
    [self.playlistMutable removeAllObjects];
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
        
        NSNumber *statusAsNumber = change[NSKeyValueChangeNewKey];
        AVPlayerItemStatus status = [statusAsNumber isKindOfClass:[NSNumber class]] ? statusAsNumber.integerValue : AVPlayerItemStatusUnknown;
        
        if ([statusAsNumber isKindOfClass:[NSNumber class]] == NO)
        {
            [self setState:ASVideoPlayerState_Suspended];
            
            return;
        }
        
        ASVP_LOG(@"Current Item StatusAsNumber: %@", statusAsNumber);
        switch (status)
        {
                /* Indicates that the status of the player is not yet known because
                 it has not tried to load new media resources for playback */
            case AVPlayerItemStatusUnknown:
            {
                [self setState:ASVideoPlayerState_Unknown];
                
                ASVP_LOG(@"Current Item Status: Unknown");
                
                break;
            }
                
            case AVPlayerItemStatusReadyToPlay:
            {
                if (self.initialSeek != 0.0)
                {
                    [self.videoPlayer seekToTime:CMTimeMakeWithSeconds(self.initialSeek, NSEC_PER_SEC)
                               completionHandler:^(BOOL finished)
                     {
                         
                     }];
                    self.initialSeek = 0.0f;
                }
                
                self.videoPlayer.closedCaptionDisplayEnabled = self.enableSubtitles;
                
                ASVP_LOG(@"Current Item Status: Ready To Play");
                
                if (self.state == ASVideoPlayerState_Seeking)
                {
                    if (!self.isScrubbing)
                    {
                        [self setState:ASVideoPlayerState_Playing];
                    }
                }
                else
                {
                    [self setState:ASVideoPlayerState_Playing];
                }
                
                break;
            }
                
            case AVPlayerItemStatusFailed:
            {
                [self.currentItem updateStatus:ASQueuePlayerItemStateFailed
                                         error:self.videoPlayer.currentItem.error];

                [self assetFailedToPrepareForPlayback:self.videoPlayer.currentItem.error];
                
                ASVP_LOG(@"Current Item Status: Failed");
                
                break;
            }
        }
    }
    /* AVPlayer "rate" property value observer. */
    else if (context == ASVP_ContextRateObservation)
    {
        ASVP_LOG(@"rate = %f", self.videoPlayer.rate);
        
        if (self.state == ASVideoPlayerState_Seeking)
        {
            return;
        }
        
        if (self.isPlaying)
        {
            if (self.videoPlayer.currentItem.status == AVPlayerItemStatusReadyToPlay)
            {
                [self setState:ASVideoPlayerState_Playing];
            }
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
        if ([self.delegate respondsToSelector:@selector(videoPlayer:currentItem:)])
        {
            AVURLAsset *asset = (AVURLAsset *)self.videoPlayer.currentItem.asset;
            
            ASQueuePlayerItem *currentItem = self.itemsDict[asset.URL.absoluteString];
            [self.delegate videoPlayer:self currentItem:currentItem];
            
            [self setCurrentItem:currentItem];
        }
    }
    else if (context == ASVP_ContextCurrentItemDurationObservation)
    {
        
    }
    else if (context == ATVP_ContextBufferObservation)
    {
        if (self.videoPlayer.currentItem.playbackBufferEmpty)
        {
            /* Buffer is empty, which will cause player to pause, so show spinner. */
            [self setState:ASVideoPlayerState_LoadingContent];
        }
    }
    else if (context == ASVP_ContextCurrentItemMetabservation)
    {
        if ([self.delegate respondsToSelector:@selector(videoPlayer:meta:)])
        {
            NSMutableArray *metaItems = [NSMutableArray array];
            for (AVMetadataItem *metaItem in self.videoPlayer.currentItem.timedMetadata)
            {
                [metaItems addObject:@{
                                      @"identifier" : metaItem.identifier?  : @"",
                                      @"value"      : metaItem.value?       : @"",
                                      }];
            }
            
            [self.delegate videoPlayer:self meta:metaItems];
        }
    }
    else
    {
        [super observeValueForKeyPath:path ofObject:object change:change context:context];
    }
}

#pragma mark - Handle Video End

// Called when the player item has played to its end time.
- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    // Send video logging ping when video has reached the end.
    [self sendEventEnd];
}

#pragma mark - Error Handling

- (void)assetFailedToPrepareForPlayback:(NSError *)error
{
    [self syncScrubber];
    
    self.userInfo = @{@"error" : error, @"current_item" : self.currentPreparingItem? : @""};
    
    [self setState:ASVideoPlayerState_Failed];
}

#pragma mark - AirPlay

- (void)addAirPlayFunctionality
{
    // Set AirPlay properties for AVPlayer.
    self.videoPlayer.allowsExternalPlayback                             = YES;
    self.videoPlayer.usesExternalPlaybackWhileExternalScreenIsActive    = YES;
    self.videoPlayer.externalPlaybackVideoGravity                       = AVLayerVideoGravityResizeAspect;
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

/* Cancels the previously registered time observer. */
- (void)removeScrubberTimer
{
    if (self.timeObserver)
    {
        [self.videoPlayer removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
    }
}

/* Requests invocation of a given block during media playback to update the movie scrubber control. */
-(void)initScrubberTimer
{
    double interval = 1.0f;
    
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
    return [self.videoPlayer rate] != 0.f;
}

- (void)beginScrubbing
{
    // Enter in Seeking mode.
    [self setState:ASVideoPlayerState_Seeking];
    
    self.restoreAfterScrubbingRate = [self.videoPlayer rate];
    [self.videoPlayer setRate:0.f];
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

- (NSArray<ASQueuePlayerItem *> *)playlist
{
    return self.playlistMutable;
}

#pragma mark - Controls

- (BOOL)prevItem
{
    if (self.playlist.count && (self.currentItem.playlistIndex > 0))
    {
        NSUInteger currentItemPlaylistIndex = self.currentItem.playlistIndex;
        
        [(AVQueuePlayer *)self.videoPlayer removeAllItems];
        
        AVPlayerItem *tempItem = nil;
        for (NSUInteger index = currentItemPlaylistIndex - 1; index < self.playlist.count; index++)
        {
            tempItem = [AVPlayerItem playerItemWithAsset:self.playlist[index].asset];
            [(AVQueuePlayer *)self.videoPlayer insertItem:tempItem afterItem:nil];
        }
        
        [self.videoPlayer play];
        
        return YES;
    }
    
    return NO;
}

- (BOOL)nextItem
{
    if (self.playlist.count && (self.currentItem.playlistIndex < self.playlist.count - 1))
    {
        [(AVQueuePlayer *)self.videoPlayer advanceToNextItem];
        
        return YES;
    }
    
    return NO;
}

- (BOOL)playItemAtIndex:(NSUInteger)itemIndex
{
    if (itemIndex >= self.playlist.count)
    {
        return NO;
    }
    
    if (self.currentItem && (itemIndex == self.currentItem.playlistIndex))
    {
        return NO;
    }
    
    self.stopPreparingAssets = YES;
    [self.currentPreparingItem cancelPreparing];
    
    [(AVQueuePlayer *)self.videoPlayer removeAllItems];
    
    self.stopPreparingAssets = NO;
    [self prepareItems:itemIndex completion:nil];
    
    return YES;
}

- (NSInteger)indexForItemURL:(NSString *)itemURL
{
    ASQueuePlayerItem *item = self.itemsDict[itemURL];
    if (item)
    {
        return item.playlistIndex;
    }
    
    return -1;
}

- (void)stop
{
    self.stopPreparingAssets = YES;
    [self.currentPreparingItem cancelPreparing];
    
    [(AVQueuePlayer *)self.videoPlayer removeAllItems];
}

#pragma mark - Handle notifications

- (void)appWillResignActive:(NSNotification *)notification
{
    // Add handler for "going to background" notification.
    [self sendEventEnd];
}

- (void)resetBackgroundTask:(NSNotification*)notification
{
    // When app is sent to the background or the device is in sleep/standby mode,
    // this method should be called to extend app's active background session.
    //DLog(@"");
    
    UIApplication *thisApp = [UIApplication sharedApplication];
    
    // If an existing background task is running,
    // end it first before starting a new one.
    if (_bgExtendedTask != UIBackgroundTaskInvalid) {
        [thisApp endBackgroundTask:_bgExtendedTask];
        _bgExtendedTask = UIBackgroundTaskInvalid;
    }
    
    // Start new background task to extend background session.
    _bgExtendedTask = [thisApp beginBackgroundTaskWithExpirationHandler:^
                       {
                           if (_bgExtendedTask != UIBackgroundTaskInvalid)
                           {
                               [[UIApplication sharedApplication] endBackgroundTask:_bgExtendedTask];
                               _bgExtendedTask = UIBackgroundTaskInvalid;
                           }
                       }];
}

- (void)stopBackgroundTask:(NSNotification*)notification
{
    // When app returns to the foreground as the active app,
    // this method should be called to end any extended background session.
    //DLog(@"");
    
    UIApplication *thisApp = [UIApplication sharedApplication];
    if (_bgExtendedTask != UIBackgroundTaskInvalid)
    {
        [thisApp endBackgroundTask:_bgExtendedTask];
        _bgExtendedTask = UIBackgroundTaskInvalid;
    }
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
            
        case ASVideoPlayerState_Preparing:
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
