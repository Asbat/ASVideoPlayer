//
//  ASQueueVideoPlayer.h
//
//  Created by Alexey Stoyanov on 11/30/15.
//  Copyright © 2015 Alexey Stoyanov. All rights reserved.
//

#import "ASBaseVideoPlayer.h"
#import "ASQueuePlayerItem.h"

@interface ASQueueVideoPlayer : ASBaseVideoPlayer

- (void)setup;

/**
 *  Retrieves the current playlist.
 *
 *  @return Playlist
 */
- (NSArray<ASQueuePlayerItem *> *)playlist;

/**
 *  Adds items to playlist.
 *
 *  @param items ASQueuePlayerItems
 */
- (void)addItemsToPlaylist:(NSArray<ASQueuePlayerItem *> *)items
                completion:(void (^)())completion;

/**
 *  Clears the current playlist.
 */
- (void)clearPlaylist;

@end
