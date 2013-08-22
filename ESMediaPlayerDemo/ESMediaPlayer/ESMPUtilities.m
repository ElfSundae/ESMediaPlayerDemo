//
//  ESMPUtilities.m
//  ESMediaPlayer
//
//  Created by Elf Sundae on 8/16/13.
//  Copyright (c) 2013 www.0x123.com. All rights reserved.
//

#import "ESMPUtilities.h"

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Dispatch
void esmp_dispatch_sync_on_main_thread(dispatch_block_t block)
{
        if ([NSThread isMainThread]) {
                block();
        } else {
                dispatch_sync(dispatch_get_main_queue(), block);
        }
}

void esmp_dispatch_async_on_main_thread(dispatch_block_t block)
{
        if ([NSThread isMainThread]) {
                block();
        } else {
                dispatch_async(dispatch_get_main_queue(), block);
        }
}

void esmp_dispatch_async_on_global_queue(dispatch_queue_priority_t priority, dispatch_block_t block)
{
        dispatch_async(dispatch_get_global_queue(priority, 0), block);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - 
NSError *esmp_error(ESMPErrorCode code, NSString *description, ...)
{
        va_list args;
        va_start(args, description);
        NSString *des = [[NSString alloc] initWithFormat:description arguments:args];
        va_end(args);
        
        return [NSError errorWithDomain:ESMPErrorDomain
                                   code:code
                               userInfo:@{NSLocalizedDescriptionKey: des}];
}

void esmp_log(NSString *format, ...)
{
#if __ESMP_ENABLE_LOG
        va_list args;
        va_start(args, format);
        NSString *log = [[NSString alloc] initWithFormat:format arguments:args];
        va_end(args);
        
        static NSDateFormatter *dateFormatter = nil;
        if (nil == dateFormatter) {
                dateFormatter = [[NSDateFormatter alloc] init];
                dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
                dateFormatter.locale = [NSLocale currentLocale];
        }
        NSString *nowDateString = [dateFormatter stringFromDate:[NSDate date]];
        
        printf("%s <ESMediaPlayer> : %s\n",
               [nowDateString UTF8String],
               [log UTF8String] );
#endif
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - MediaPlayer Helper

UIImage *esmp_imageFromAVPicture(AVPicture picture, int width, int height)
{
	CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
	CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault,
                                                     picture.data[0],
                                                     picture.linesize[0]*height,
                                                     kCFAllocatorNull);
	CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGImageRef cgImage = CGImageCreate(width,
                                           height,
                                           8,
                                           24,
                                           picture.linesize[0],
                                           colorSpace,
                                           bitmapInfo,
                                           provider,
                                           NULL,
                                           NO,
                                           kCGRenderingIntentDefault);
	CGColorSpaceRelease(colorSpace);
	UIImage *image = [UIImage imageWithCGImage:cgImage];
	CGImageRelease(cgImage);
	CGDataProviderRelease(provider);
	CFRelease(data);
	
	return image;
}