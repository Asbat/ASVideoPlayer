//
//  ASVideoEvent.m
//
//  Created by Alexey Stoyanov on 12/7/15.
//  Copyright © 2015 Alexey Stoyanov. All rights reserved.
//

#import "ASVideoEvent.h"

@implementation ASVideoEvent

+ (instancetype)eventWithTimePlayed:(NSNumber *)timePlayed
                           position:(NSNumber *)position
{
    ASVideoEvent *event = [[ASVideoEvent alloc] initWithTimePlayed:timePlayed
                                                          position:position];
    
    event.event         = [self typeString];
    
    return event;
}

+ (ASVideoEventType)type
{
    return ASVideoEventType_Unknown;
}

+ (NSString *)typeString
{
    return nil;
}

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

@end

@implementation ASVideoEventPlaying

+ (ASVideoEventType)type
{
    return ASVideoEventType_Playing;
}

+ (NSString *)typeString
{
    return @"playing";
}

@end

@implementation ASVideoEventPause

+ (ASVideoEventType)type
{
    return ASVideoEventType_Pause;
}

+ (NSString *)typeString
{
    return @"pause";
}

@end

@implementation ASVideoEventEnd

+ (ASVideoEventType)type
{
    return ASVideoEventType_End;
}

+ (NSString *)typeString
{
    return @"end";
}

@end
