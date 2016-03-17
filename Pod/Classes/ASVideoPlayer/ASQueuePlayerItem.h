//
//  ASQueuePlayerItem.h
//
//  Created by Alexey Stoyanov on 11/30/15.
//  Copyright © 2015 Alexey Stoyanov. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSUInteger, ASQueuePlayerItemState)
{
    ASQueuePlayerItemStateUnprepared,
    ASQueuePlayerItemStatePrepared,
    ASQueuePlayerItemStateFailed
};

@interface ASQueuePlayerItem : NSObject

/**
 *  Player item's title.
 */
@property (nonatomic, strong, readonly) NSString                *title;

/**
 *  Additional user data.
 */
@property (nonatomic, strong, readonly) NSDictionary            *userInfo;

/**
 *  AVURLAsset
 */
@property (nonatomic, strong, readonly) AVURLAsset              *asset;

@property (nonatomic, assign, readonly) ASQueuePlayerItemState  state;
@property (nonatomic, assign, readonly) NSError                 *error;
@property (nonatomic, assign, readonly) NSUInteger              playlistIndex;

- (instancetype)initWithTitle:(NSString *)title
                          url:(NSURL *)url
                     userInfo:(NSDictionary *)userInfo;

- (void)prepareItem:(void (^)(NSError *error))completion;

- (void)cancelPreparing;

- (void)updatePlaylistIndex:(NSUInteger)playlistIndex;
- (void)updateStatus:(ASQueuePlayerItemState)status error:(NSError *)error;

+ (NSError *)validateAsset:(AVURLAsset *)asset
                  withKeys:(NSArray *)requestedKeys;

@end
