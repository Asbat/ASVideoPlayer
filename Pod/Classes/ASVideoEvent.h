//
//  ASVideoEvent.h
//
//  Created by Alexey Stoyanov on 12/7/15.
//  Copyright © 2015 Alexey Stoyanov. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ASVideoEventType)
{
    ASVideoEventType_Unknown        = -1,
    
    ASVideoEventType_Playing,
    ASVideoEventType_Pause,
    ASVideoEventType_End,
};

@interface ASVideoEvent : NSObject

@property (nonatomic, strong) NSString                  *event;
@property (nonatomic, strong) NSNumber                  *asset_id;
@property (nonatomic, strong) NSNumber                  *time_played;
@property (nonatomic, strong) NSNumber                  *position;

+ (instancetype)eventWithTimePlayed:(NSNumber *)timePlayed
                           position:(NSNumber *)position;

+ (ASVideoEventType)type;

+ (NSString *)typeString;

@end

@interface ASVideoEventPlaying : ASVideoEvent

@end

@interface ASVideoEventPause : ASVideoEvent

@end

@interface ASVideoEventEnd : ASVideoEvent

@end
