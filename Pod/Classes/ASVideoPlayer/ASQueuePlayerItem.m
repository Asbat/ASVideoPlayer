//
//  ASQueuePlayerItem.m
//
//  Created by Alexey Stoyanov on 11/30/15.
//  Copyright © 2015 Alexey Stoyanov. All rights reserved.
//

#import "ASQueuePlayerItem.h"
#import "ASBaseVideoPlayer.h"

@interface ASQueuePlayerItem ()

@property (nonatomic, strong) NSString        *title;

@property (nonatomic, strong) NSDictionary    *userInfo;

@property (nonatomic, strong) AVURLAsset      *asset;

@end

@implementation ASQueuePlayerItem

- (instancetype)initWithTitle:(NSString *)title
                          url:(NSString *)url
                     userInfo:(NSDictionary *)userInfo
{
    if (self = [super init])
    {
        self.title      = title;
        self.asset      = [AVURLAsset assetWithURL:[NSURL URLWithString:url]];
        self.userInfo   = userInfo;
    }
    
    return self;
}

- (void)prepareForPlaylistIndex:(NSUInteger)playlistIndex
                     completion:(void (^)(NSError *error))completion
{
    if (self.asset == nil)
    {
        if (completion)
        {
            NSError *error = [NSError errorWithDomain:NSStringFromClass(self.class)
                                                 code:-1
                                             userInfo:@{
                                                        NSLocalizedDescriptionKey : @"Missing asset."
                                                        }];
            completion(error);
        }
        
        return;
    }
    
    NSArray *requestedKeys = @[kASVP_PlayableKey];
    
    /* Tells the asset to load the values of any of the specified keys that are not already loaded. */
    __block __typeof(self) weakSelf = self;
    [self.asset loadValuesAsynchronouslyForKeys:requestedKeys
                              completionHandler:
     ^{
         if (weakSelf == nil)
         {
             return;
         }
         
         NSError *error = [ASQueuePlayerItem validateAsset:weakSelf.asset
                                                  withKeys:requestedKeys];
         
         if (error == nil)
         {
             weakSelf->_isPrepared      = YES;
             weakSelf->_playlistIndex   = playlistIndex;
         }
         
         if (completion)
         {
             completion(error);
         }
     }];
}

/*
 Invoked at the completion of the loading of the values for all keys on the asset that we require.
 Checks whether loading was successfull and whether the asset is playable.
 If so, sets up an AVPlayerItem and an AVPlayer to play the asset.
 */
+ (NSError *)validateAsset:(AVURLAsset *)asset
                  withKeys:(NSArray *)requestedKeys
{
    /* Make sure that the value of each key has loaded successfully. */
    for (NSString *thisKey in requestedKeys)
    {
        NSError *error = nil;
        AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
        if (keyStatus == AVKeyValueStatusFailed)
        {
            return error;
        }
    }
    
    /* Use the AVAsset playable property to detect whether the asset can be played. */
    if (!asset.playable)
    {
        return [NSError errorWithDomain:NSStringFromClass(self.class)
                                   code:-1
                               userInfo:@{
                                          NSLocalizedDescriptionKey : @"Asset not playable."
                                          }];
    }
    
    return nil;
}

@end
