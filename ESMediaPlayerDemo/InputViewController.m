//
//  InputViewController.m
//  ESMediaPlayer
//
//  Created by Elf Sundae on 8/17/13.
//  Copyright (c) 2013 www.0x123.com. All rights reserved.
//

#import "InputViewController.h"
#import "VideoViewController.h"

@interface InputViewController ()
@property (nonatomic, strong) UITextField *urlTextField;
@end

@implementation InputViewController

- (void)viewDidLoad
{
        [super viewDidLoad];
        
        self.title = @"Media Player Demo";
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *url = [userDefaults stringForKey:@"url"];
        if (!url.length) {
                url = [[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Together" ofType:@"flv"]] absoluteString];
        }
        
        self.urlTextField = [[UITextField alloc] initWithFrame:CGRectMake(10, 15.0, 300.0, 30.0)];
        self.urlTextField.font = [UIFont systemFontOfSize:16.0];
        self.urlTextField.borderStyle = UITextBorderStyleRoundedRect;
        self.urlTextField.clearButtonMode = UITextFieldViewModeAlways;
        self.urlTextField.text = url;
        [self.view addSubview:self.urlTextField];
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                                  initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                                                  target:self
                                                  action:@selector(playAction:)];
}

- (void)playAction:(id)sender
{
        NSString *urlString = [self.urlTextField.text stringByTrimmingCharactersInSet:
                               [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (urlString.length) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                        [[NSUserDefaults standardUserDefaults] setObject:urlString forKey:@"url"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                });
        }
        VideoViewController *video = [[VideoViewController alloc] initWithMediaURL:
                                      [NSURL URLWithString:urlString]];
        [self.navigationController pushViewController:video animated:YES];
}

@end
