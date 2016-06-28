//
//  ASVideoEvent.m
//
//  Created by Alexey Stoyanov on 12/7/15.
//  Copyright © 2015 Alexey Stoyanov. All rights reserved.
//

#import "ASVideoEvent.h"

@implementation ASVideoEvent

- (instancetype)initWithTimePlayed:(NSNumber *)timePlayed
                          position:(NSNumber *)position
{
    if (self = [super init])
    {
        self.time_played            = timePlayed;
        self.position               = position;
    }
    
    return self;
}

- (ASVideoEventType)type
{
    return ASVideoEventType_Unknown;
}

- (NSString *)event
{
    return nil;
}

@end

@implementation ASVideoEventPlaying

- (ASVideoEventType)type
{
    return ASVideoEventType_Playing;
}

- (NSString *)event
{
    return @"playing";
}

@end

@implementation ASVideoEventPause

- (ASVideoEventType)type
{
    return ASVideoEventType_Pause;
}

- (NSString *)event
{
    return @"pause";
}

@end

@implementation ASVideoEventEnd

- (ASVideoEventType)type
{
    return ASVideoEventType_End;
}

- (NSString *)event
{
    return @"end";
}

@end

@implementation ASVideoEventResignActive

- (ASVideoEventType)type
{
    return ASVideoEventType_ResignActive;
}

- (NSString *)event
{
    return @"resign-active";
}

@end

@implementation ASVideoEventStopped

- (ASVideoEventType)type
{
    return ASVideoEventType_Stopped;
}

- (NSString *)event
{
    return @"stopped";
}

@end
