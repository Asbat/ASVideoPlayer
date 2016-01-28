//
//  ASVideoView.m
//
//  Created by Alexey Stoyanov on 12/3/15.
//  Copyright © 2015 Alexey Stoyanov. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
//#import <SVProgressHUD/SVProgressHUD.h>

#import "ASVideoView.h"
#import "ASVideoEvent.h"
//#import "ASVideoPlayer.h"
#import "ASQueueVideoPlayer.h"

static void *ASVV_ContextVideoStateObservation                  = &ASVV_ContextVideoStateObservation;

/**
 *  ASPlaybackView
 */
@interface ASPlaybackView : UIView

- (void)addPlayer:(AVPlayer *)player;
- (AVPlayer *)player;
- (void)setVideoFillMode:(NSString *)fillMode;

@end

/**
 *  ASVideoView
 */
@interface ASVideoView () <ASVideoPlayerDelegate>

// IBOutlets
//[
@property (nonatomic, strong) IBOutlet ASPlaybackView           *vwPlayback;

@property (nonatomic, strong) IBOutlet UIView                   *vwOverlayContainer;
@property (nonatomic, strong) IBOutlet UIView                   *vwTopBar;
@property (nonatomic, strong) IBOutlet UIView                   *vwBottomBar;

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView  *vwActivityIndicator;

@property (nonatomic, strong) IBOutlet UILabel                  *lblTitle;
@property (nonatomic, strong) IBOutlet UILabel                  *lblTimePlayed;
@property (nonatomic, strong) IBOutlet UILabel                  *lblTimeLeft;

@property (nonatomic, strong) IBOutlet UISlider                 *scrubber;

@property (nonatomic, strong) IBOutlet UIButton                 *btnFullscreen; // Won't be needed.
@property (nonatomic, strong) IBOutlet UIButton                 *btnVolume;
@property (nonatomic, strong) IBOutlet UIButton                 *btnPlay;
@property (nonatomic, strong) IBOutlet UIButton                 *btnContainer;
@property (nonatomic, strong) IBOutlet UIButton                 *btnDone;
@property (nonatomic, strong) IBOutlet UIButton                 *btnDoneArea;
//]

//@property (nonatomic, strong) ASVideoPlayer                     *player;
@property (nonatomic, strong) ASQueueVideoPlayer                *player;

@end

@implementation ASVideoView

+ (instancetype)create
{
    ASVideoView *vwVideo        = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self)
                                                                owner:self
                                                              options:nil][0];
    
    return vwVideo;
}

- (void)awakeFromNib
{
    self.player                 = [ASQueueVideoPlayer new];
    self.player.delegate        = self;
    
    [self.player setup];
    
    [self subscribeForVideoPlayerState];
}

- (void)dealloc
{
    [self unsubscribeForVideoPlayerState];
}

#pragma mark - ASVideoPlayer State Machine

- (void)subscribeForVideoPlayerState
{
    [self.player addObserver:self
                  forKeyPath:@"state"
                     options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                     context:ASVV_ContextVideoStateObservation];
}

- (void)unsubscribeForVideoPlayerState
{
    [self.player removeObserver:self
                     forKeyPath:@"state"
                        context:ASVV_ContextVideoStateObservation];
}

- (void)handleVideoPlayerState:(ASVideoPlayerState)state
{
    switch (state)
    {
        case ASVideoPlayerState_Unknown:
        {
            [self disableScrubber];
            [self disablePlayerButtons];
            
            [self busy:YES];
            
            break;
        }
            
        case ASVideoPlayerState_Init:
        {
            [self syncPlayPauseButtons];
            [self disableScrubber];
            [self disablePlayerButtons];
            [self enableDoneButton];
    
            break;
        }
            
        case ASVideoPlayerState_Playing:
        {
            [self syncPlayPauseButtons];
            [self enableDoneButton];
            
            [self enableScrubber];
            [self enablePlayerButtons];
            
            [self busy:NO];
            
            break;
        }
            
        case ASVideoPlayerState_Paused:
        {
            [self syncPlayPauseButtons];
            
            break;
        }
            
        case ASVideoPlayerState_Seeking:
        {
            [self busy:YES];
            
            break;
        }
            
        case ASVideoPlayerState_Suspended:
        {
            [self disablePlayerButtons];
            [self disableScrubber];
            
            [self busy:NO];
            
            break;
        }
            
        case ASVideoPlayerState_Failed:
        {
            [self enableDoneButton];
            [self disableScrubber];
            [self disablePlayerButtons];

            [self busy:NO];
            
            NSError *error = self.player.userInfo[@"error"];
            
            if (error)
            {
                /* Display the error. */
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
                                                                    message:[error localizedFailureReason]
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                [alertView show];
            }
            
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString*)path
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
{
    if (context == ASVV_ContextVideoStateObservation)
    {
        [self handleVideoPlayerState:self.player.state];
    }
    else
    {
        [super observeValueForKeyPath:path
                             ofObject:object
                               change:change
                              context:context];
    }
}

#pragma mark - Play, Stop buttons

/* Show the pause button in the movie player controller. */
-(void)showPauseButton
{
    [self.btnPlay setImage:[UIImage imageNamed:@"EBVideoIcon-Pause"]
                  forState:UIControlStateNormal];
}

/* Show the play button in the movie player controller. */
-(void)showPlayButton
{
    [self.btnPlay setImage:[UIImage imageNamed:@"EBVideoIcon-Play"]
                  forState:UIControlStateNormal];
}

/* If the media is playing, show the pause button; otherwise, show the play button. */
- (void)syncPlayPauseButtons
{
    if (self.player.state == ASVideoPlayerState_Playing)
    {
        [self showPauseButton];
    }
    else
    {
        [self showPlayButton];
    }
}

-(void)enablePlayerButtons
{
    self.btnPlay.enabled = YES;
}

-(void)disablePlayerButtons
{
    self.btnPlay.enabled = NO;
}

#pragma mark - Scrubber

- (void)enableScrubber
{
    self.scrubber.enabled = YES;
}

- (void)disableScrubber
{
    self.scrubber.enabled = NO;
}

- (void)setScrubberValue:(CGFloat)scrubberValue
{
    [self.scrubber setValue:scrubberValue];
}

- (CGFloat)scrubberValue
{
    return self.scrubber.value;
}

- (CGFloat)scrubberMinValue
{
    return self.scrubber.minimumValue;
}

- (CGFloat)scrubberMaxValue
{
    return self.scrubber.maximumValue;
}

- (void)setScrubberMinValue:(CGFloat)scrubberMinValue
{
    self.scrubber.minimumValue = scrubberMinValue;
}

- (void)setScrubberMaxValue:(CGFloat)scrubberMaxValue
{
    self.scrubber.maximumValue = scrubberMaxValue;
}

- (void)scrubberColor:(UIColor *)color
{
    self.scrubber.minimumTrackTintColor = color;
}

#pragma mark - Enable Done Button

- (void)enableDoneButton
{
    self.btnDone.enabled = YES;
    self.btnDoneArea.enabled = YES;
}

#pragma mark - IBActions

- (IBAction)play:(id)sender
{
    if (self.player.isPlaying)
    {
        [self.player pause];
        [self showPlayButton];
        return;
    }
    
    [self.player play];
    [self showPauseButton];
}

/* The user is dragging the movie controller thumb to scrub through the movie. */
- (IBAction)beginScrubbing:(id)sender
{
    [self.player beginScrubbing];
}

/* Set the player current time to match the scrubber position. */
- (IBAction)scrub:(id)sender
{
    double minValue     = self.scrubberMinValue;
    double maxValue     = self.scrubberMaxValue;
    double value        = self.scrubberValue;

    double duration     = self.player.videoDuration;
    double time         = duration * (value - minValue) / (maxValue - minValue);

    // Update time labels on each side of scrubber.
    [self updateLeftTimeLabel:duration - time];
    [self updatePlayedTimeLabel:time];
    [self.player seekToTime:time];
}

/* The user has released the movie thumb control to stop scrubbing through the movie. */
- (IBAction)endScrubbing:(id)sender
{
    [self.player endScrubbing];
}

- (IBAction)onToggleControlBar:(id)sender
{
    static BOOL isAnimating         = NO;
    
    if (isAnimating)
    {
        return;
    }
    
    isAnimating                     = YES;
    
    CGFloat alpha                   = self.vwTopBar.alpha == 1.0f ? 0.0f : 1.0f;

    [UIView animateWithDuration:0.3f
                     animations:^
    {
        self.vwTopBar.alpha         = alpha;
        self.vwBottomBar.alpha      = alpha;
    }
                     completion:^(BOOL finished)
    {
        isAnimating                 = NO;
    }];
}

- (IBAction)onCloseButtonTapped:(id)sender
{
    [self.player reset];
    [self unsubscribeForVideoPlayerState];
    self.player = nil;

    if (self.closeHandler)
    {
        self.closeHandler();
    }
    
    [self removeFromSuperview];
}

#pragma mark - Title

- (void)updateTitle:(NSString *)title
{
    self.lblTitle.text = title;
}

#pragma mark - Update time labels

- (void)updatePlayedTimeLabel:(double)seconds
{
    // Update time labels on each side of scrubber.
    self.lblTimePlayed.text = [ASVideoView getFormattedTime:seconds];
}

- (void)updateLeftTimeLabel:(double)seconds
{
    // Update time labels on each side of scrubber.
    self.lblTimeLeft.text = [@"-" stringByAppendingString:[ASVideoView getFormattedTime:seconds]];
}

#pragma mark - Get formatted time from seconds.

+ (NSString*)getFormattedTime:(double)timeSeconds
{
    if (timeSeconds >= 0)
    {
        // timeSeconds is not Nil, so convert total seconds into readable 0:00:00 time format.
        
        double hrs   = floor( fmod(timeSeconds / 3600, 24) );
        double mins = floor( fmod(timeSeconds / 60, 60) );
        double secs = round( fmod(timeSeconds, 60) );
        
        NSString *formattedHrs;
        if (hrs == 0) {
            formattedHrs = @"";
        } else {
            formattedHrs = [NSString stringWithFormat:@"%1.0f:", hrs];
        }
        NSString *formattedMins;
        if (mins == 0) {
            formattedMins = @"00:";
        } else {
            formattedMins = [NSString stringWithFormat:@"%02.0f:", mins];
        }
        NSString *formattedSecs;
        if (secs == 0) {
            formattedSecs = @"00";
        } else {
            formattedSecs = [NSString stringWithFormat:@"%02.0f", secs];
        }
        return [NSString stringWithFormat:@"%@%@%@", formattedHrs, formattedMins, formattedSecs];
    } else {
        // timeSeconds is Nil so return default value.
        return @"00:00";
    }
}

#pragma mark - Activity
- (void)busy:(BOOL)show
{
    if (show == NO)
    {
        self.vwActivityIndicator.hidden = YES;
        [self.vwActivityIndicator stopAnimating];
    }
    else
    {
        self.vwActivityIndicator.hidden = NO;
        [self.vwActivityIndicator startAnimating];
    }
}

#pragma mark - Reset

- (void)reset
{
    ((AVPlayerLayer *)self.vwPlayback.layer).player = nil;
    [self.vwPlayback.layer removeFromSuperlayer];
}

#pragma mark - Popover parent

- (UIView *)popoverParent
{
    return self.scrubber;
}

#pragma mark - ASVideoPlayerDelegate

- (void)videoPlayer:(ASVideoPlayer *)videoPlayer event:(ASVideoEvent *)event
{
    switch ([event.class type])
    {
        case ASVideoEventType_Playing:
            
            break;
            
        case ASVideoEventType_Pause:
            
            break;
            
        case ASVideoEventType_End:
            
            break;
            
        default:
            break;
    }
}

- (AVPlayerLayer *)outputViewForVideoPlayer:(ASVideoPlayer *)videoPlayer
{
    return (AVPlayerLayer *)self.vwPlayback.layer;
}

- (void)videoPlayer:(ASVideoPlayer *)videoPlayer currentTime:(double)currentTime timeLeft:(double)timeLeft duration:(double)duration
{
    float minValue = self.scrubberMinValue;
    float maxValue = self.scrubberMaxValue;

    [self setScrubberValue:(maxValue - minValue) * currentTime / duration + minValue];

    [self updatePlayedTimeLabel:currentTime];
    [self updateLeftTimeLabel:duration - currentTime];
}

#pragma mark - Add New Item

- (void)addNewPlaylistItem:(NSURL *)playlistItemURL
{
    if (playlistItemURL)
    {
        [self.player addItemsToPlaylist:@[playlistItemURL]];
    }
}

@end

#pragma mark - ASPlaybackView

@implementation ASPlaybackView

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
