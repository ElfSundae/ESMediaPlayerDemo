//
//  VideoViewController.m
//  ESMediaPlayer
//
//  Created by Elf Sundae on 8/17/13.
//  Copyright (c) 2013 www.0x123.com. All rights reserved.
//

#import "VideoViewController.h"
#import "ESMediaPlayer.h"

@interface VideoViewController ()
@property (nonatomic, copy) NSURL *videoURL;
@property (nonatomic, strong) ESMediaPlayerController *player;
@end

@implementation VideoViewController

- (void)dealloc
{
        if (self.player) {
                [self.player stop];
        }
}

- (id)initWithMediaURL:(NSURL *)url
{
        self = [super init];
        if (self) {
                self.videoURL = url;
        }
        return self;
}

- (void)viewDidLoad
{
        [super viewDidLoad];
        self.title = @"Player";
        [self performSelector:@selector(play:) withObject:nil afterDelay:0.01];
}

- (void)pause:(id)sender
{
        if (self.player) {
                [self.player pause];
                self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(play:)];
        }
}

- (void)play:(id)sender
{
        if (!self.player) {
                self.player = [[ESMediaPlayerController alloc] initWithContentURL:self.videoURL];
                NSError *error = nil;
                if (![self.player prepareToPlay:&error]) {
                        /*
                        [UIAlertView alertViewWithTitle:@"Error Preparing Video"
                                                message:[error localizedDescription]
                                      cancelButtonTitle:@"OK"
                                     customizationBlock:nil dismissBlock:nil cancelBlock:nil otherButtonTitles:nil, nil];
                         */
                        NSLog(@"Error preparing video: %@", [error localizedDescription]);
                        self.player = nil;
                } else {
                        NSLog(@"Video loading OK.");
                        self.player.videoOutputSize = ESMPVideoSizeMake(self.view.frame.size.width,
                                                                        (self.view.frame.size.width / self.player.videoSourceSize.width * self.player.videoSourceSize.height) );
                        [self.view addSubview:self.player.view];
                }
        }
        
        if (self.player) {
                [self.player play];
                self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(pause:)];
        }
}

@end
