//
//  ASQueueVideoPlayer.h
//
//  Created by Alexey Stoyanov on 11/30/15.
//  Copyright © 2015 Alexey Stoyanov. All rights reserved.
//

#import "ASBaseVideoPlayer.h"
#import "ASQueuePlayerItem.h"

@interface ASQueueVideoPlayer : ASBaseVideoPlayer

@property (nonatomic, strong, readonly) ASQueuePlayerItem                   *currentItem;

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

/**
 *  Playing the previous item in the current playlist.
 *
 *  @return NO if the current item was the first in the current playlist.
 */
- (BOOL)prevItem;

/**
 *  Playing the next item in the current playlist.
 *
 *  @return NO if the current item was the last in the current playlist.
 */
- (BOOL)nextItem;

/**
 *  Plays the item at "itemIndex".
 *
 *  @param itemIndex
 *
 *  @return NO if the index is out of bounds or already playing that item.
 */
- (BOOL)playItemAtIndex:(NSUInteger)itemIndex;

@end
