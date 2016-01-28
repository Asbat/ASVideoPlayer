//
//  ASQueueVideoPlayer.h
//
//  Created by Alexey Stoyanov on 11/30/15.
//  Copyright © 2015 Alexey Stoyanov. All rights reserved.
//

#import "ASBaseVideoPlayer.h"

@interface ASQueueVideoPlayer : ASBaseVideoPlayer

@property (nonatomic, strong, readonly) NSMutableArray<AVURLAsset *>                *playlist;

- (void)setup;

- (void)addItemsToPlaylist:(NSArray<NSURL *> *)items;

@end
