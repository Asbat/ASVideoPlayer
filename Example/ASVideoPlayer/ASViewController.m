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

@property (nonatomic, weak) IBOutlet UITextView                 *txtVwLogs;

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
    
    __weak typeof(self) weakSelf = self;
    self.videoView.player.logs = ^(NSString *log)
    {
        dispatch_async(dispatch_get_main_queue(), ^
        {
            [weakSelf logHelper:log];
        });
    };
    
    [self addObserver:self
           forKeyPath:@"videoView.player.currentItem"
              options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
              context:ASVC_ContextCurrentPlayerItemObservation];
    
    self.txtVwLogs.layoutManager.allowsNonContiguousLayout = NO;
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

#pragma mark - Log helper

- (void)logHelper:(NSString *)log
{
    self.txtVwLogs.text = [self.txtVwLogs.text stringByAppendingString:[NSString stringWithFormat:@"\n%@", log]];
    
    [self.txtVwLogs scrollRangeToVisible:NSMakeRange(self.txtVwLogs.text.length - 1, 1)];
}

#pragma mark - Add Item

- (void)addItem:(NSString *)title itemUrl:(NSString *)itemUrl
{
    ASQueuePlayerItem *item = nil;
    NSMutableArray *items = [NSMutableArray array];
    NSMutableArray *paths = [NSMutableArray array];
    
    item = [[ASQueuePlayerItem alloc] initWithTitle:title
                                                url:[NSURL URLWithString:itemUrl]
                                           userInfo:@{}];
    
    [items addObject:item];
    
    [self.videoView.player appendItemsToPlaylist:items];
    
    [paths addObject:[NSIndexPath indexPathForRow:self.videoView.player.playlist.count - 1
                                        inSection:0]];
    
    [self.tbVwPlaylist beginUpdates];
    
    [self.tbVwPlaylist insertRowsAtIndexPaths:paths
                             withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [self.tbVwPlaylist endUpdates];
    
    [self.videoView.player playItemAtIndex:0];
}

#pragma mark - IBActions

- (IBAction)onClearPlaylistTapped:(id)sender
{
    [self.videoView.player clearPlaylist];
    
    [self.tbVwPlaylist reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (IBAction)onAddNewPlaylistItemTapped:(id)sender
{
    [self showInputAlert];
    
//    http://testcontent.qello.com.s3.amazonaws.com/encoding/live/1/2.m3u8
//    http://testcontent.qello.com.s3.amazonaws.com/encoding/live/1/1.m3u8
//    http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/gear1/prog_index.m3u8
//    https://devimages.apple.com.edgekey.net/samplecode/avfoundationMedia/AVFoundationQueuePlayer_HLS2/master.m3u8
}

- (IBAction)onPrevItemButtonTapped:(id)sender
{
    [self.videoView.player prevItem];
}

- (IBAction)onNextItemButtonTapped:(id)sender
{
    [self.videoView.player nextItem];
}

- (IBAction)onDeleteItemButtonTapped:(id)sender
{
    if ([self.videoView.player deleteItemAtIndex:self.videoView.player.currentItem.playlistIndex])
    {
        [self.tbVwPlaylist beginUpdates];
        
        [self.tbVwPlaylist deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.videoView.player.currentItem.playlistIndex inSection:0]]
                                 withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [self.tbVwPlaylist endUpdates];
    }
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
            [self logHelper:[NSString stringWithFormat:@"Current Item:\ntitle: %@\nurl: %@\nerror: %@\n",
                             self.videoView.player.currentItem.title,
                             self.videoView.player.currentItem.asset.URL.absoluteString,
                             self.videoView.player.currentItem.error]];
             
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

#pragma mark - UIAlertController

- (void)showInputAlert
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Append New Item"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    __block UITextField *txtFldItemTitle = nil;
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField)
    {
        txtFldItemTitle = textField;
        txtFldItemTitle.placeholder = @"Title";
    }];
    
    __block UITextField *txtFldItemUrl = nil;
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField)
     {
         txtFldItemUrl = textField;
         txtFldItemUrl.placeholder = @"URL";
     }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"Add" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
    {
        [weakSelf addItem:txtFldItemTitle.text itemUrl:txtFldItemUrl.text];
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

@end

@implementation ASTestCell



@end
