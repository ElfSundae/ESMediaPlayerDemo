//
//  ESMediaPlayerController.m
//  ESMediaPlayer
//
//  Created by Elf Sundae on 8/16/13.
//  Copyright (c) 2013 www.0x123.com. All rights reserved.
//

#import "ESMediaPlayerController.h"
#import "ESMPUtilities.h"
#import "libswscale/swscale.h"
#import "libavformat/avformat.h"

#define kDefault_FrameRate          25.0

NSString *const ESMPErrorDomain = @"ESMPErrorDomain";

ESMPVideoSize const ESMPVideoSizeZero = { 0, 0 };
ESMPVideoSize ESMPVideoSizeMake(int width, int height)
{
        ESMPVideoSize size;
        size.width = (int)width;
        size.height = (int)height;
        return size;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface ESMediaPlayerController ()
{
        AVFormatContext *_formatContext;
        AVCodecContext *_codecContext;
        AVFrame *_avFrame;
        AVPacket _framePacket;
        AVPicture _rgbPicture;
        struct SwsContext *_image_convert_context;
        int _videoStreamIndex; // can be used to check if the video is playable
        int _audioStreamIndex; // can be used to check if the audio is playable
        double _frameRate;
        
        // audio
        
        // other
        BOOL _isPreparedToPlay;
}

/* Last decoded picture as UIImage */
@property (nonatomic, strong, readwrite) UIImage *currentImage;
@property (nonatomic, assign, readwrite) ESMPVideoSize videoSourceSize;

@property (nonatomic, strong, readwrite) UIView *view;
@property (nonatomic, strong, readwrite) UIView *backgroundView;
@property (nonatomic, strong) UIImageView *imageView; // to display images of video frames

@property (nonatomic, strong) NSTimer *videoPlayingTimer;
@property (nonatomic, assign) ESMPPlaybackState videoPlaybackState;

@end

@implementation ESMediaPlayerController

- (void)dealloc
{
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [self cleanUp];
}

static BOOL _shared_is_registered = NO;
+ (void)registerCodecAndNetwork
{
        // Set ffmpeg log level
#if __ESMP_ENABLE_LOG
        av_log_set_level(AV_LOG_VERBOSE);
#else
        av_log_set_level(AV_LOG_QUIET);
#endif
        // Register all formats, codecs
        avcodec_register_all();
        av_register_all();
        // Initialized network
        avformat_network_init();
        
        _shared_is_registered = YES;
        esmp_log(@"Registered all codec and initialized network.");
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private Methods
/**
 * Clean up and initialization
 */
- (void)cleanUp
{
        [self stop];
        
        if (_codecContext) {
                avcodec_close(_codecContext);
                _codecContext = NULL;
        }
        
        // Free scaler
        if (_image_convert_context) {
                sws_freeContext(_image_convert_context);
                _image_convert_context = NULL;
        }
        // Free RGB picture
        if (&_rgbPicture) {
                avpicture_free(&_rgbPicture);
        }
        
        // Free the YUV frame
        if (&_avFrame) {
                avcodec_free_frame(&_avFrame);
        }
        
        // Free the packet that was allocated by av_read_frame
        if (&_framePacket) {
                av_free_packet(&_framePacket);
        }
        
        if (_formatContext) {
                avformat_close_input(&_formatContext);
        }
        
        //av_free(_audioBuffer);
        //av_free_packet(_audioPacket);
        
        self.currentImage = nil;
        _isPreparedToPlay = NO;
        _audioStreamIndex = -1;
        _videoStreamIndex = -1;
        _videoSourceSize = ESMPVideoSizeZero;
        _videoOutputSize = ESMPVideoSizeZero;
        _frameRate = kDefault_FrameRate;
}

- (void)didReceiveMemoryWarning
{
        [self stop];
        self.view = nil;
        self.backgroundView = nil;
        self.imageView = nil;
}

- (void)startPlayingTimer
{
        [self stopPlayingTimer];
        if (self.isPreparedToPlay && _videoStreamIndex > -1) {
                double interval = 1.0 / kDefault_FrameRate;
                if (_frameRate > 0.0) {
                        interval = 1.0 / _frameRate;
                }
                self.videoPlayingTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                                          target:self
                                                                        selector:@selector(playingTimerTask)
                                                                        userInfo:nil
                                                                         repeats:YES];
                //esmp_log(@"Start playingTimer.");
                [self.videoPlayingTimer fire];
        }
}

- (void)stopPlayingTimer
{
        //esmp_log(@"Stop playingTimer.");
        if (self.videoPlayingTimer) {
                [self.videoPlayingTimer invalidate];
                self.videoPlayingTimer = nil;
        }
}

- (void)playingTimerTask
{
        //esmp_log(@"playingTimerTask");
        if (![self stepFrame]) {
                [self playingFinished];
        } else {
                @autoreleasepool {
                        UIImage *image = self.currentImage;
                        if (self.imageView) {
                                self.imageView.image = image;
                        }
                }
        }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Playback

- (BOOL)_prepareToPlay:(__autoreleasing NSError **)error
{
        if (!_shared_is_registered) {
                [[self class] registerCodecAndNetwork];
        }
        
        if (_formatContext) {
                [self cleanUp];
        }
        
        // Reset status
        _isPreparedToPlay = NO;
        
        if (!self.contentURL) {
                if (error) {
                        *error = esmp_error(ESMPErrorCodeCanNotOpenVideoFile,
                                            @"The contentURL should not be nil.");
                }
                return NO;
        }
        
        // Set the options if its streaming video
        AVDictionary *rtmp_options = 0;
        NSString *urlScheme = self.contentURL.scheme.lowercaseString;
        if ([urlScheme isEqualToString:@"rtsp"] ||
            [urlScheme isEqualToString:@"rtmp"]) {
                av_dict_set(&rtmp_options, "rtsp_transport", "tcp", 0);
        }
        
        NSString *filePath = self.contentURL.absoluteString;
        if ([self.contentURL isFileURL]) {
                filePath = self.contentURL.path;
        }
        
        // Open video file
        if (avformat_open_input(&_formatContext,
                                [filePath UTF8String],
                                NULL, &rtmp_options) != 0) {
                if (error) {
                        *error = esmp_error(ESMPErrorCodeCanNotOpenVideoFile,
                                            @"Could not open video file: %@.", self.contentURL);
                }
                return NO;
        }
        
        // Retrieve stream information
        if (avformat_find_stream_info(_formatContext, NULL) < 0) {
                if (error) {
                        *error = esmp_error(ESMPErrorCodeCanNotFindStreamInformation,
                                            @"Could not find stream information.");
                }
                return NO;
        }
        
#if __ESMP_ENABLE_LOG
        esmp_log(@"av_dump_format for %@", self.contentURL);
        av_dump_format(_formatContext, 0, [self.contentURL.absoluteString UTF8String], false);
#endif
        
        // Find the first video stream
        _videoStreamIndex = _audioStreamIndex = -1;
        for (int i = 0; i < _formatContext->nb_streams; i++) {
                if (_formatContext->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO) {
                        _videoStreamIndex = i;
                        esmp_log(@"Found the first video stream.");
                        // Get frame rate(fps) for playingTimer interval
                        AVStream *st = _formatContext->streams[i];
                        if (st->avg_frame_rate.den &&
                            st->avg_frame_rate.num) {
                                _frameRate = av_q2d(st->avg_frame_rate);
                        }
#if FF_API_R_FRAME_RATE
                        else if (st->r_frame_rate.den &&
                                 st->r_frame_rate.num) {
                                _frameRate = av_q2d(st->r_frame_rate);
                        }
#endif
                        else {
                                _frameRate = kDefault_FrameRate;
                        }
                        esmp_log(@"Video frame rate: %f fps.", _frameRate);
                }
                if (_formatContext->streams[i]->codec->codec_type == AVMEDIA_TYPE_AUDIO) {
                        _audioStreamIndex = i;
                        esmp_log(@"Found the first audio stream.");
                }
        }
        
        
        if (_videoStreamIndex == -1 && _audioStreamIndex == -1) {
                if (error) {
                        *error = esmp_error(ESMPErrorCodeCanNotFindTheFirstVideoNorAudioStream,
                                            @"Could not find the first video or audio stream.");
                }
                return NO;
        }
        
        BOOL setupVideo = [self setupVideoDecoder];
        BOOL setupAudio = [self setupAudioDecoder];
        if (!setupVideo && !setupAudio) {
                if (error) {
                        *error = esmp_error(ESMPErrorCodeCanNotSetupVideoNorAudioCodec,
                                            @"Could not setup video nor audio codec.");
                }
                return NO;
        }
        
        _isPreparedToPlay = YES;
        return YES;
}

/**
 * Read the next frame from the video stream. Returns false if no frame read (video over).
 */
- (BOOL)stepFrame
{
        int frameFinished = 0;
        
        while ( !frameFinished &&
               av_read_frame(_formatContext, &_framePacket) >= 0 ) {
                // Is this a packet from the video stream ?
                if (_framePacket.stream_index == _videoStreamIndex) {
                        // Decode video frame
                        avcodec_get_frame_defaults(_avFrame);
                        if (avcodec_decode_video2(_codecContext, _avFrame, &frameFinished, &_framePacket) < 0) {
                                esmp_log(@"Error: avcodec_decode_video2 failed.");
                                break;
                        }
                }
                
                if (_framePacket.stream_index == _audioStreamIndex) {
                       
                }
        }
        
        return !!frameFinished;
}

- (void)playingFinished
{
        [self stopPlayingTimer];
        //TODO: notify finished if it's playing...
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Video

- (BOOL)setupVideoDecoder
{
        if (_videoStreamIndex <= -1) {
                esmp_log(@"Could not find the first video stream.");
                return NO;
        }
        
        // Get a pointer to the codec context for the video stream
        _codecContext = _formatContext->streams[_videoStreamIndex]->codec;
        
        // Find the decoder for the video stream
        AVCodec *avCodec = avcodec_find_decoder(_codecContext->codec_id);
        if (avCodec == NULL) {
                esmp_log(@"Could not find the video codec.");
                return NO;
        }
        
        // Inform the codec that we can handle truncated bitstreams -- i.e.,
        // bitstreams where frame boundaries can fall in the middle of packets
        if(avCodec->capabilities & CODEC_CAP_TRUNCATED) {
                _codecContext->flags |= CODEC_FLAG_TRUNCATED;
        }
        
        // Open codec
        if (avcodec_open2(_codecContext, avCodec, NULL) < 0) {
                esmp_log(@"Could not open video codec.");
                return NO;
        }
        
        // Allocate a video frame to store the decoded images in:
        _avFrame = avcodec_alloc_frame();
        if (!_avFrame) {
                esmp_log(@"Could not alloc avFrame.");
                return NO;
        }
        
        // Set the default output size of video frame
        self.videoSourceSize = ESMPVideoSizeMake(_codecContext->width,
                                                 _codecContext->height);
        self.videoOutputSize = self.videoSourceSize;
        
        return YES;
}

- (NSTimeInterval)duration
{
        if (self.isPreparedToPlay) {
                return (NSTimeInterval)((double)_formatContext->duration / AV_TIME_BASE);
        }
        return 0.0;
}

- (NSTimeInterval)currentPlaybackTime
{
        if (!self.isPreparedToPlay) {
                return 0.0;
        }
        
        int index = (_videoStreamIndex > -1 ?
                     _videoStreamIndex :
                     (_audioStreamIndex > -1 ? _audioStreamIndex : -1));
        if (index <= -1) {
                return 0.0;
        }
        
        AVRational timeBase = _formatContext->streams[index]->time_base;
        return (NSTimeInterval)(_framePacket.pts * (double)timeBase.num / timeBase.den);
}

- (void)setCurrentPlaybackTime:(NSTimeInterval)currentPlaybackTime
{
        if (!self.isPreparedToPlay) {
                [self prepareToPlay:NULL];
        }
        
        if (!_codecContext /*&& !_audioCodecContext */) {
                esmp_log(@"Error: Media is not playable.");
                return;
        }
                
        if (_videoStreamIndex > -1) {
                AVRational timeBase = _formatContext->streams[_videoStreamIndex]->time_base;
                int64_t targetFrame = (int64_t)((double)timeBase.den / timeBase.num * currentPlaybackTime);
                avformat_seek_file(_formatContext, _videoStreamIndex,
                                   targetFrame, targetFrame, targetFrame, AVSEEK_FLAG_FRAME);
                avcodec_flush_buffers(_codecContext);
        } else if (_audioStreamIndex > -1) {
                
        }
}

- (void)setVideoOutputSize:(ESMPVideoSize)size
{
        if (size.width != _videoOutputSize.width ||
            size.height != _videoOutputSize.height) {
                _videoOutputSize = size;
                [self setupScaler];
                [self resizeView];
        }
}

- (void)setupScaler
{
        if (!_codecContext) {
                return;
        }
	// Release old picture and scaler
	avpicture_free(&_rgbPicture);
	sws_freeContext(_image_convert_context);
        _image_convert_context = NULL;
	
	// Allocate RGB picture
	avpicture_alloc(&_rgbPicture, PIX_FMT_RGB24,
                        self.videoOutputSize.width,
                        self.videoOutputSize.height);
	
	// Setup scaler
        _image_convert_context = sws_getCachedContext(NULL,
                                                      _codecContext->width,
                                                      _codecContext->height,
                                                      _codecContext->pix_fmt,
                                                      self.videoOutputSize.width,
                                                      self.videoOutputSize.height,
                                                      PIX_FMT_RGB24,
                                                      SWS_FAST_BILINEAR,
                                                      NULL, NULL, NULL);
}



- (UIImage *)currentImage
{
        if (!_image_convert_context) {
                return nil;
        }
        if (!_avFrame ||
            !_avFrame->data[0]) {
                return nil;
        }
        
        // Convert frame to RGB
        sws_scale(_image_convert_context,
                  (const uint8_t *const *)_avFrame->data, _avFrame->linesize,
                  0,
                  _codecContext->height,
                  _rgbPicture.data,
                  _rgbPicture.linesize);
        return esmp_imageFromAVPicture(_rgbPicture,
                                       self.videoOutputSize.width,
                                       self.videoOutputSize.height);
}



//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Audio

- (BOOL)setupAudioDecoder
{
        if (_audioStreamIndex <= -1) {
                _audioStreamIndex = -1;
                esmp_log(@"Cannot find the first audio stream.");
                return NO;
        }
        
        //...
        
        //TODO: Interrupting any active (non-mixible) audio sessions.
        
        // AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        // [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
        
        return YES;
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Audio callback


//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public Methods

- (id)init
{
        return [self initWithContentURL:nil];
}

- (id)initWithContentURL:(NSURL *)url
{
        self = [super init];
        if (self) {
                self.contentURL = url;
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(didReceiveMemoryWarning)
                                                             name:UIApplicationDidReceiveMemoryWarningNotification
                                                           object:nil];
                _frameRate = kDefault_FrameRate;
        }
        return self;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UI

- (UIView *)view
{
        if (!_view) {
                [self setupUI];
        }
        return _view;
}

- (UIView *)backgroundView
{
        if (!_backgroundView) {
                [self setupUI];
        }
        return _backgroundView;
}
- (UIImageView *)imageView
{
        if (!_imageView) {
                [self setupUI];
        }
        return _imageView;
}
- (void)setupUI
{
        UIViewAutoresizing autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                               UIViewAutoresizingFlexibleHeight);
        
        self.view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 240.0)];
        self.view.autoresizesSubviews = YES;
        self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.view.backgroundColor = [UIColor blackColor];
        
        self.imageView = [[UIImageView alloc] initWithFrame:self.view.frame];
        self.imageView.backgroundColor = [UIColor blackColor];
        self.imageView.autoresizingMask = autoresizingMask;
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.view addSubview:self.imageView];
        
        self.backgroundView = [[UIView alloc] initWithFrame:self.view.frame];
        self.backgroundView.autoresizingMask = autoresizingMask;
        self.backgroundView.autoresizesSubviews = YES;
        self.backgroundView.backgroundColor = [UIColor blackColor];
        [self.view addSubview:self.backgroundView];
        [self.view sendSubviewToBack:self.backgroundView];
}


- (void)resizeView
{
        if (!self.view) {
                [self setupUI];
        }
        
        self.view.frame = CGRectMake(self.view.frame.origin.x,
                                     self.view.frame.origin.y,
                                     self.videoOutputSize.width,
                                     self.videoOutputSize.height);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - ESMediaPlayback Delegate

- (BOOL)prepareToPlay:(NSError *__autoreleasing *)error
{
        BOOL ret = [self _prepareToPlay:error];
        if (!ret) {
                [self cleanUp];
        }
        return ret;
}

- (BOOL)isPreparedToPlay
{
        return _isPreparedToPlay;
}

- (void)play
{
        //TODO: resume if it's paused.
        [self setCurrentPlaybackTime:0.0];
        [self startPlayingTimer];
}

- (void)pause
{
        [self stop];
}

- (void)stop
{
        [self playingFinished];
}
@end
