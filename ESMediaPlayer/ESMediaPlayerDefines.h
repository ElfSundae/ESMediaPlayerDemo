//
//  ESMediaPlayerDefines.h
//  ESMediaPlayer
//
//  Created by Elf Sundae on 8/21/13.
//  Copyright (c) 2013 www.0x123.com. All rights reserved.
//

#ifndef __ESMP_ESMediaPlayerDefines_H
#define __ESMP_ESMediaPlayerDefines_H

/** Enable console log */
#define __ESMP_ENABLE_LOG       1

/** Error Domain */
extern NSString *const ESMPErrorDomain;
/** Error Code */
typedef NS_ENUM(NSInteger, ESMPErrorCode) {
        ESMPErrorCodeUnknown = -1,
        
        ESMPErrorCodeCanNotOpenVideoFile        = 10,
        ESMPErrorCodeCanNotFindStreamInformation = 11,
        ESMPErrorCodeCanNotFindTheFirstVideoNorAudioStream = 12,
        ESMPErrorCodeCanNotSetupVideoNorAudioCodec = 13,
};

/** Video Size */
typedef struct _ESMPVideoSize {
        int width;
        int height;
} ESMPVideoSize;

ESMPVideoSize ESMPVideoSizeMake(int width, int height);
extern ESMPVideoSize const ESMPVideoSizeZero;


/** Playback state */
typedef NS_ENUM(NSInteger, ESMPPlaybackState) {
        ESMPPlaybackStateStopped,
        ESMPPlaybackStatePlaying,
        ESMPPlaybackStatePaused,
        ESMPPlaybackStateInterrupted,
        ESMPPlaybackStateSeekingForward,
        ESMPPlaybackStateSeekingBackward,
};

#endif
