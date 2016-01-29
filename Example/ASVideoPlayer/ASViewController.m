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

#pragma mark - Test Cell

@interface ASTestCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel            *lblItem;

@end

@interface ASViewController ()

// IBOutlets
//[
@property (nonatomic, weak) IBOutlet UIView         *vwToolbarContainer;
@property (nonatomic, weak) IBOutlet UIView         *vwPlayback;

@property (nonatomic, weak) IBOutlet UITableView    *tbVwPlaylist;
//]

@property (nonatomic, strong) ASVideoView           *videoView;

@end

@implementation ASViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.videoView = [ASVideoView create];
    
    [self.videoView setFrame:self.vwPlayback.bounds];
    [self.vwPlayback addSubview:self.videoView];
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
    if (step % 2 == 0)
    {
        item = [[ASQueuePlayerItem alloc] initWithTitle:@"Mother Instinct - Gazoon"
                                                    url:@"https://api.qkids.com/broker/?token=PT_NLM9CMF_q6VyDHbdvZpGdETCi2i_Ph3ORotsGmLONKbpSpIEz4-2rQzb-MYXIoVE4mddNpuEWNDap7Km-WSZHGzb&asset_id=2691&codec=HLS"
                                               userInfo:@{}];
    }
    else if (step % 3 == 0)
    {
        item = [[ASQueuePlayerItem alloc] initWithTitle:@"Levers - Hippothesis"
                                                    url:@"https://api.qkids.com/broker/?token=PT_NLM9CMF_q6VyDHbdvZpGdETCi2i_Ph3ORotsGmLONKbpSpIEz4-2rQzb-MYXIoVE4mddNpuEWNDap7Km-WSZHGzb&asset_id=2669&codec=HLS"
                                               userInfo:@{}];
    }
    else
    {
        item = [[ASQueuePlayerItem alloc] initWithTitle:@"Colibri"
                                                    url:@"https://devimages.apple.com.edgekey.net/samplecode/avfoundationMedia/AVFoundationQueuePlayer_HLS2/master.m3u8"
                                               userInfo:@{}];
    }
    
    __weak typeof (self) weakSelf = self;
    [self.videoView addNewPlaylistItem:item
                            completion:^
    {
        [weakSelf.tbVwPlaylist beginUpdates];
        
        NSIndexPath *newItemPath = [NSIndexPath indexPathForRow:weakSelf.videoView.player.playlist.count - 1
                                                      inSection:0];
        
        [weakSelf.tbVwPlaylist insertRowsAtIndexPaths:@[newItemPath]
                                     withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [weakSelf.tbVwPlaylist endUpdates];
        
        [weakSelf.tbVwPlaylist scrollToRowAtIndexPath:newItemPath
                                     atScrollPosition:UITableViewScrollPositionMiddle
                                             animated:YES];
    }];
    
    step++;
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
    
}

@end

@implementation ASTestCell



@end
