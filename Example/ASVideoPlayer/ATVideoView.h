//
//  ATVideoView.h
//  AcornTV
//
//  Created by Alexey Stoyanov on 12/3/15.
//  Copyright © 2015 Qello. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ASVideoPlayer.h"

@interface ATVideoView : UIView

@property (nonatomic, strong, readonly) ASVideoPlayer               *player;
@property (nonatomic, assign) CGFloat                               scrubberMinValue;
@property (nonatomic, assign) CGFloat                               scrubberMaxValue;
@property (nonatomic, assign) CGFloat                               scrubberValue;
@property (nonatomic, strong) UIView                                *popoverParent;

@property (nonatomic, copy) void (^closeHandler)();

+ (instancetype)create;

#pragma mark - Play, Pause buttons
- (void)showPauseButton;
- (void)showPlayButton;
- (void)syncPlayPauseButtons;
- (void)enablePlayerButtons;
- (void)disablePlayerButtons;

#pragma mark - Scrubber
- (void)enableScrubber;
- (void)disableScrubber;
- (void)scrubberColor:(UIColor *)color;

#pragma mark - Title
- (void)updateTitle:(NSString *)title;

#pragma mark - Update Time Labels
- (void)updatePlayedTimeLabel:(double)seconds;
- (void)updateLeftTimeLabel:(double)seconds;

#pragma mark - Reset
- (void)reset;

#pragma mark - Activity
- (void)showActivity:(BOOL)show;

#pragma mark - Enable Done Button
- (void)enableDoneButton;

@end
