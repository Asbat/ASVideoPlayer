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
 *  Appends items to the end of the playlist.
 *
 *  @param items
 */
- (void)appendItemsToPlaylist:(NSArray<ASQueuePlayerItem *> *)items;

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
 *  Stops the player.
 */
- (void)stop;

/**
 *  Plays the item at "itemIndex".
 *
 *  @param itemIndex
 *
 *  @return NO if the index is out of bounds or already playing that item.
 */
- (BOOL)playItemAtIndex:(NSUInteger)itemIndex;

/**
 *  Retrieves the index of item that matches "itemURL".
 *
 *  @param itemURL
 *
 *  @return -1 if the item does not exist in the playlist.
 */
- (NSInteger)indexForItemURL:(NSString *)itemURL;

/**
 *  Delete item at index.
 *
 *  @param index Index
 *
 *  @return NO if the item was not deleted.
 */
- (BOOL)deleteItemAtIndex:(NSUInteger)index;

@end
