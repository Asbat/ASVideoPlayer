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

- (IBAction)onAddNewPlaylistItemTapped:(id)sender
{
    static NSUInteger step = 0;
    
    if (step % 2 == 0)
    {
        [self.videoView addNewPlaylistItem:[NSURL URLWithString:@"http://api.dev.rlje.us/broker/?token=UT_UsEgnEUpf9p29smcPQxyXb6YCJoKPEnyy5WLeF1_mlK29QkFZHlh_ol_vze4c5RNkAb28GwK4CGj2TRaEojkZXks&asset_id=169&codec=HLS"]];
    }
    else
    {
        [self.videoView addNewPlaylistItem:[NSURL URLWithString:@"https://devimages.apple.com.edgekey.net/samplecode/avfoundationMedia/AVFoundationQueuePlayer_HLS2/master.m3u8"]];
//        [self.videoView addNewPlaylistItem:[NSURL URLWithString:@"http://api.dev.rlje.us/broker/?token=GT_WqQlDqQZmbkm66kPhvAg9WW5Z9dJT0N9DegcL8p-o2noj9jICKePXGXUwJfsDKT4_X1NianzqM5pyA==&asset_id=76&codec=HLS"]];
    }
    
    step++;
    
    [self.tbVwPlaylist reloadData];
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
    
    cell.lblItem.text = [self.videoView.player.playlist[indexPath.row] URL].absoluteString;
    
    return cell;
}

@end

@implementation ASTestCell



@end
