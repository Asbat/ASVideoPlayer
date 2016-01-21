//
//  ATPlaybackView.h
//  AcornTV
//
//  Created by Alexey Stoyanov on 12/3/15.
//  Copyright © 2015 Qello. All rights reserved.
//

#import <UIKit/UIKit.h>

// Forward
@class AVPlayer;

@interface ATPlaybackView : UIView

- (void)addPlayer:(AVPlayer *)player;
- (AVPlayer *)player;
- (void)setVideoFillMode:(NSString *)fillMode;

@end
