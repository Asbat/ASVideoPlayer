//
//  ASViewController.m
//  ASVideoPlayer
//
//  Created by Alexey Stoyanov on 01/19/2016.
//  Copyright (c) 2016 Alexey Stoyanov. All rights reserved.
//

#import "ASViewController.h"
#import "ASVideoView.h"
#import "ASQueueVideoPlayer.h"

static void *ASVC_ContextCurrentPlayerItemObservation           = &ASVC_ContextCurrentPlayerItemObservation;

#pragma mark - Test Cell

@interface ASTestCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel                    *lblItem;

@end

@interface ASViewController ()

// IBOutlets
//[
@property (nonatomic, weak) IBOutlet UIView                     *vwToolbarContainer;
@property (nonatomic, weak) IBOutlet UIView                     *vwPlayback;

@property (nonatomic, weak) IBOutlet UITableView                *tbVwPlaylist;
//]

@property (nonatomic, strong) ASVideoView                       *videoView;

@end

@implementation ASViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.videoView = [ASVideoView create];
    
    [self.videoView setFrame:self.vwPlayback.bounds];
    [self.vwPlayback addSubview:self.videoView];
    
    [self addObserver:self
           forKeyPath:@"videoView.player.currentItem"
              options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
              context:ASVC_ContextCurrentPlayerItemObservation];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    [self.videoView setFrame:self.vwPlayback.bounds];
}

#pragma mark - IBActions

- (IBAction)onClearPlaylistTapped:(id)sender
{
    [self.videoView.player clearPlaylist];
    
    [self.tbVwPlaylist reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (IBAction)onAddNewPlaylistItemTapped:(id)sender
{
    static NSUInteger step = 0;
    
    ASQueuePlayerItem *item = nil;
    NSMutableArray *items = [NSMutableArray array];
    NSMutableArray *paths = [NSMutableArray array];
//    if (step % 2 == 0)
    {
        item = [[ASQueuePlayerItem alloc] initWithTitle:@"Mother Instinct - Gazoon"
                                                    url:@"https://api.rlje.us/broker/?token=GT_orHiPSoTgrTKhBrTZ_ENBS-ykO9fIwIEAihXGxJDDFAZfP79O97jj2IADIp5tXTPZqD7jxbNOhnIfQ==&asset_id=645&codec=HLS"
                                               userInfo:@{}];
        
        [items addObject:item];
        
        [paths addObject:[NSIndexPath indexPathForRow:self.videoView.player.playlist.count
                                           inSection:0]];
    }
//    else if (step % 3 == 0)
    {
        item = [[ASQueuePlayerItem alloc] initWithTitle:@"Mystery"
                                                    url:@"https://api.rlje.us/broker/?token=GT_orHiPSoTgrTKhBrTZ_ENBS-ykO9fIwIEAihXGxJDDFAZfP79O97jj2IADIp5tXTPZqD7jxbNOhnIfQ==&asset_id=5925&codec=HLS"
                                               userInfo:@{}];
        
        [items addObject:item];
        
        [paths addObject:[NSIndexPath indexPathForRow:[paths.firstObject row] + 1
                                            inSection:0]];
    }
//    else
    {
        item = [[ASQueuePlayerItem alloc] initWithTitle:@"Colibri"
                                                    url:@"https://devimages.apple.com.edgekey.net/samplecode/avfoundationMedia/AVFoundationQueuePlayer_HLS2/master.m3u8"
                                               userInfo:@{}];
        
        [items addObject:item];
        
        [paths addObject:[NSIndexPath indexPathForRow:[paths.firstObject row] + 2
                                            inSection:0]];
    }
    
    __weak typeof (self) weakSelf = self;
    
    [self.videoView.player addItemsToPlaylist:items
                                   completion:^
    {
        [weakSelf.tbVwPlaylist beginUpdates];
        
        [weakSelf.tbVwPlaylist insertRowsAtIndexPaths:paths
                                     withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [weakSelf.tbVwPlaylist endUpdates];
        
        [weakSelf.tbVwPlaylist scrollToRowAtIndexPath:paths.lastObject
                                     atScrollPosition:UITableViewScrollPositionMiddle
                                             animated:YES];
    }];
    
    step++;
}

- (IBAction)onPrevItemButtonTapped:(id)sender
{
    [self.videoView.player prevItem];
}

- (IBAction)onNextItemButtonTapped:(id)sender
{
    [self.videoView.player nextItem];
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.videoView.player.playlist.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static ASTestCell *cell = nil;
    
    cell = (ASTestCell *)[tableView dequeueReusableCellWithIdentifier:@"ASTestCell" forIndexPath:indexPath];
    
    cell.lblItem.text = [self.videoView.player.playlist[indexPath.row] title];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.videoView.player playItemAtIndex:indexPath.row];
}


#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString*)path
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
{
    if (context == ASVC_ContextCurrentPlayerItemObservation)
    {
        if (self.videoView.player.currentItem)
        {
            if ([self.tbVwPlaylist numberOfRowsInSection:0] > self.videoView.player.currentItem.playlistIndex)
            {
                [self.tbVwPlaylist selectRowAtIndexPath:[NSIndexPath indexPathForRow:self.videoView.player.currentItem.playlistIndex inSection:0]
                                               animated:YES
                                         scrollPosition:UITableViewScrollPositionMiddle];
            }
        }
    }
    else
    {
        [super observeValueForKeyPath:path
                             ofObject:object
                               change:change
                              context:context];
    }
}

@end

@implementation ASTestCell



@end
