//
//  ESMediaPlayerController.h
//  ESMediaPlayer
//
//  Created by Elf Sundae on 8/16/13.
//  Copyright (c) 2013 www.0x123.com. All rights reserved.
//

/**!
 * Media Player.
 *
 * See ESMediaPlayback.h for the playback methods.
 *
 * TODO:
        1. Async `preparedToPlay:` in queue, and note thread safely
        2. Support audio
        3. UI: view, backgroundView
        4. UI rotate supports
        5. Increase performances with GPU to render video images.(OpenGL ES, CoreImage, AVFoundation)
        6. Remove unnecessary ffmpge libraries and iOS Frameworks, such as libavfilter, libswresample, to decrease the binary size.
        7. Support URL changes (should re-`preparedToPlay`)
                
 * Testing:
        1. Weak netwrok connection
        2. Only video without audio, only audio without video.
        3. Lower memory...
 */


/**!
 * NOTE: Call any other methods After `-preparedToPlay:` method.
 */

#import <Foundation/Foundation.h>
#import "ESMediaPlayerDefines.h"
#import "ESMediaPlayback.h"

@interface ESMediaPlayerController : NSObject <ESMediaPlayback>

- (id)initWithContentURL:(NSURL *)url;
// It can be local file:// or remote URL, including video file or streaming video.
@property(nonatomic, copy) NSURL *contentURL;
// The view in which the media is displayed.
@property(nonatomic, strong, readonly) UIView *view;
// A view for customization which is always displayed behind movie content.
@property(nonatomic, strong, readonly) UIView *backgroundView;
// Length of media in seconds 
@property (nonatomic, readonly) NSTimeInterval duration;
/* Size of video frame */
@property (nonatomic, assign, readonly) ESMPVideoSize videoSourceSize;
/* Output image size. Set to the source size by default. */
@property (nonatomic, assign) ESMPVideoSize videoOutputSize;
/* Playback state */
@property (nonatomic, assign, readonly) ESMPPlaybackState playbackState;

@end
