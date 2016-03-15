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
        self.title              = title;
        self.asset              = [AVURLAsset assetWithURL:[NSURL URLWithString:url]];
        self.userInfo           = userInfo;
    }
    
    return self;
}

- (void)updatePlaylistIndex:(NSUInteger)playlistIndex
{
    _playlistIndex = playlistIndex;
}

- (void)updateStatus:(ASQueuePlayerItemState)status error:(NSError *)error
{
    _state = status;
    _error = error;
}

- (void)prepareItem:(void (^)(NSError *error))completion
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
    
    if (self.state == ASQueuePlayerItemStatePrepared)
    {
        if (completion)
        {
            completion(nil);
        }
        
        return;
    }
    
    NSArray *requestedKeys = @[kASVP_PlayableKey];
    
    if (self.state == ASQueuePlayerItemStateFailed)
    {
        if (completion)
        {
            completion(self.error);
        }
        
        return;
    }
    
    /* Tells the asset to load the values of any of the specified keys that are not already loaded. */
    __weak __typeof(self) weakSelf = self;
    [self.asset loadValuesAsynchronouslyForKeys:requestedKeys
                              completionHandler:
     ^{
         if (weakSelf == nil)
         {
             return;
         }
         
         NSError *error = [ASQueuePlayerItem validateAsset:weakSelf.asset
                                                  withKeys:requestedKeys];
         
         __strong typeof(weakSelf) sSelf        = weakSelf;
         if (error == nil)
         {
             sSelf->_state                      = ASQueuePlayerItemStatePrepared;
         }
         else
         {
             sSelf->_state                      = ASQueuePlayerItemStateFailed;
         }
         
         if (completion)
         {
             completion(error);
         }
     }];
}

- (void)cancelPreparing
{
    [self.asset cancelLoading];
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
