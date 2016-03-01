//
//  ASQueuePlayerItem.h
//
//  Created by Alexey Stoyanov on 11/30/15.
//  Copyright © 2015 Alexey Stoyanov. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface ASQueuePlayerItem : NSObject

/**
 *  Player item's title.
 */
@property (nonatomic, strong, readonly) NSString        *title;

/**
 *  Additional user data.
 */
@property (nonatomic, strong, readonly) NSDictionary    *userInfo;

/**
 *  AVURLAsset
 */
@property (nonatomic, strong, readonly) AVURLAsset      *asset;

@property (nonatomic, assign, readonly) BOOL            isPrepared;
@property (nonatomic, assign, readonly) NSUInteger      playlistIndex;

- (instancetype)initWithTitle:(NSString *)title
                          url:(NSString *)url
                     userInfo:(NSDictionary *)userInfo
                playlistIndex:(NSUInteger)playlistIndex;

- (void)prepareItem:(void (^)(NSError *error))completion;

- (void)cancelPreparing;

+ (NSError *)validateAsset:(AVURLAsset *)asset
                  withKeys:(NSArray *)requestedKeys;

@end
