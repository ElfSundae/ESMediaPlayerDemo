//
//  ESMPUtilities.h
//  ESMediaPlayer
//
//  Created by Elf Sundae on 8/16/13.
//  Copyright (c) 2013 www.0x123.com. All rights reserved.
//

#ifndef __ESMP_ESMPUtilities_H
#define __ESMP_ESMPUtilities_H

#import <Foundation/Foundation.h>
#import "ESMediaPlayerDefines.h"
#import "libavcodec/avcodec.h"
#import <UIKit/UIKit.h>

void esmp_dispatch_sync_on_main_thread(dispatch_block_t block);
void esmp_dispatch_async_on_main_thread(dispatch_block_t block);
void esmp_dispatch_async_on_global_queue(dispatch_queue_priority_t priority, dispatch_block_t block);

NSError *esmp_error(ESMPErrorCode code, NSString *description, ...);
void esmp_log(NSString *format, ...);

UIImage *esmp_imageFromAVPicture(AVPicture picture, int width, int height);

#endif