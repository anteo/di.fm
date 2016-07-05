//
//  ZANStreamPlayer.m
//  StreamPlayer
//
//  Created by Charles Magahern on 7/4/16.
//  Copyright © 2016 zanneth. All rights reserved.
//

#import "ZANStreamPlayer.h"
#import <AudioToolbox/AudioToolbox.h>
#import <pthread.h>

#if !__has_feature(objc_arc)
#error ARC is required for this file
#endif

#define DEFAULT_BUFFER_SIZE         2048
#define AUDIO_QUEUE_BUFFERS_COUNT   16
#define MAX_PACKET_DESCRIPTIONS     512

// -----------------------------------------------------------------------------

typedef NS_ENUM(NSUInteger, ZANStreamPlaybackState)
{
    ZANStreamPlaybackStateStopped = 0,
    ZANStreamPlaybackStatePaused,
    ZANStreamPlaybackStatePlaying,
};

// -----------------------------------------------------------------------------

static void _ZANPropertyListenerCallback(void *clientData,
                                         AudioFileStreamID fileStream,
                                         AudioFileStreamPropertyID propertyID,
                                         UInt32 *flags);

static void _ZANPacketsAvailableCallback(void *clientData,
                                         UInt32 bytesLength,
                                         UInt32 packetsCount,
                                         const void *data,
                                         AudioStreamPacketDescription *packetDescriptions);

static void _ZANAudioQueuePropertyListenerCallback(void *clientData,
                                                   AudioQueueRef audioQueue,
                                                   AudioQueuePropertyID propertyID);

static void _ZANAudioQueueOutputCallback(void *clientData,
                                         AudioQueueRef audioQueue,
                                         AudioQueueBufferRef buffer);

static void _ZANAudioQueueProcessingTapCallback(void *clientData,
                                                AudioQueueProcessingTapRef tap,
                                                UInt32 framesCount,
                                                AudioTimeStamp *timestamp,
                                                AudioQueueProcessingTapFlags *flags,
                                                UInt32 *outFramesCount,
                                                AudioBufferList *data);

// -----------------------------------------------------------------------------

@interface ZANURLSessionDelegateWeakForwarder : NSObject <NSURLSessionDataDelegate>

@property (nonatomic, weak) id<NSURLSessionDataDelegate> forwardedDelegate;

@end

// -----------------------------------------------------------------------------

@interface ZANStreamPlayer () <NSURLSessionDataDelegate>

@property (nonatomic, assign) ZANStreamPlaybackState playbackState;

@end

@implementation ZANStreamPlayer
{
    NSURLSession                *_urlSession;
    NSURLSessionDataTask        *_dataTask;
    NSUInteger                   _metaInterval;
    NSUInteger                   _bytesReadSinceMeta;
    NSMutableData               *_currentMetaPayload;
    NSUInteger                   _currentMetaLength;
    
    AudioFileStreamID            _audioFileStream;
    AudioQueueRef                _audioQueue;
    AudioQueueBufferRef          _audioQueueBuffers[AUDIO_QUEUE_BUFFERS_COUNT];
    AudioStreamPacketDescription _packetDescriptions[MAX_PACKET_DESCRIPTIONS];
    AudioQueueProcessingTapRef   _processingTap;
    AudioStreamBasicDescription  _processingFormat;
    
    NSOperationQueue            *_inputQueue;
    BOOL                         _queueBuffersUsageStates[AUDIO_QUEUE_BUFFERS_COUNT];
    pthread_mutex_t              _queueBuffersMutex;
    pthread_cond_t               _queueBufferReadyCondition;
    
    NSUInteger                   _dataOffset;
    NSUInteger                   _packetBufferSize;
    NSUInteger                   _bytesFilled;
    NSUInteger                   _packetsFilled;
    NSUInteger                   _audioFileLength;
    NSUInteger                   _currentBufferIndex;
    AudioStreamBasicDescription  _audioStreamDescription;
}

- (instancetype)initWithURL:(NSURL *)url options:(ZANStreamPlayerOptions)options
{
    self = [super init];
    if (self) {
        _url = [url copy];
        _options = options;
        
        _currentMetaPayload = [[NSMutableData alloc] init];
        
        _inputQueue = [[NSOperationQueue alloc] init];
        _inputQueue.maxConcurrentOperationCount = 1;
        
        pthread_mutex_init(&_queueBuffersMutex, NULL);
        pthread_cond_init(&_queueBufferReadyCondition, NULL);
        
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        ZANURLSessionDelegateWeakForwarder *urlSessionDelegate = [[ZANURLSessionDelegateWeakForwarder alloc] init];
        urlSessionDelegate.forwardedDelegate = self;
        _urlSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:urlSessionDelegate delegateQueue:_inputQueue];
    }
    return self;
}

- (void)dealloc
{
    [self _closeReadStream];
    [self _closeAudioStream];
    [self _destroyAudioOutputQueue];
    
    if (_processingTap) {
        AudioQueueProcessingTapDispose(_processingTap);
        _processingTap = NULL;
    }
    
    pthread_mutex_destroy(&_queueBuffersMutex);
    pthread_cond_destroy(&_queueBufferReadyCondition);
    
    [_urlSession invalidateAndCancel];
}

#pragma mark - Accessors

- (BOOL)isPlaying
{
    return (self.playbackState == ZANStreamPlaybackStatePlaying);
}

- (BOOL)isStopped
{
    return (self.playbackState == ZANStreamPlaybackStateStopped);
}

#pragma mark - API

- (void)play
{
    self.playbackState = ZANStreamPlaybackStatePlaying;
}

- (void)pause
{
    self.playbackState = ZANStreamPlaybackStatePaused;
}

- (void)stop
{
    self.playbackState = ZANStreamPlaybackStateStopped;
}

#pragma mark - Private

- (void)setPlaybackState:(ZANStreamPlaybackState)playbackState
{
    _playbackState = playbackState;
    
    switch (playbackState) {
        case ZANStreamPlaybackStatePlaying: {
            if (_audioQueue) {
                // reset so that we don't hear previously queued buffers
                OSStatus status = AudioQueueReset(_audioQueue);
                if (status != noErr) {
                    [self _logError:@"Failed to reset audio queue (OSStatus = %d)", status];
                    [self _handleError:[self _errorFromOSStatus:status]];
                }
            }
            
            if (!_dataTask) {
                [self _openReadStream];
                // the first couple bytes encountered will start the audio queue again
            }
        } break;
        
        case ZANStreamPlaybackStatePaused: {
            if (_audioQueue) {
                OSStatus status = AudioQueuePause(_audioQueue);
                if (status != noErr) {
                    [self _logError:@"Failed to pause audio queue (OSStatus = %d)", status];
                    [self _handleError:[self _errorFromOSStatus:status]];
                }
            }
            
            if (_dataTask) {
                [self _closeReadStream];
            }
        } break;
            
        case ZANStreamPlaybackStateStopped: {
            if (_audioQueue) {
                OSStatus status = AudioQueueStop(_audioQueue, true);
                if (status != noErr) {
                    [self _logError:@"Failed to stop audio queue (OSStatus = %d)", status];
                    [self _handleError:[self _errorFromOSStatus:status]];
                }
            }
            
            if (_dataTask) {
                [self _closeReadStream];
            }
        } break;
    }
    
    if ([_delegate respondsToSelector:@selector(streamPlayerPlaybackStateDidChange:)]) {
        [_delegate streamPlayerPlaybackStateDidChange:self];
    }
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error && error.code != NSURLErrorCancelled) {
        [self _logError:@"URL session data task failed to complete. %@", error];
        [self _handleError:error];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    NSError *error = nil;
    
    do {
        // make sure audio stream is open first
        if (!_audioFileStream) {
            [self _openAudioStreamWithError:&error];
        }
        if (error) {
            [self _logError:@"Failed to open audio stream: %@", error];
            break;
        }
        
        // read the meta interval out of the response, if necessary
        if (_options & ZANStreamPlayerOptionRequestMetadata && _metaInterval == 0) {
            NSHTTPURLResponse *response = (NSHTTPURLResponse *)dataTask.response;
            NSString *metaIntervalString = [[response allHeaderFields] objectForKey:@"icy-metaint"];
            _metaInterval = (NSUInteger)[metaIntervalString integerValue];
        }
        
        // if we are getting metadata with the stream, we need to parse that out
        NSData *audioData = nil;
        if (_metaInterval > 0) {
            NSMutableData *mutableAudioData = [[NSMutableData alloc] initWithCapacity:data.length];
            [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
                NSUInteger bytesRead = 0;
                
                while (bytesRead < byteRange.length) {
                    const NSUInteger remainingBytes = byteRange.length - bytesRead;
                    const void *currentPtr = bytes + bytesRead;
                    
                    if (_currentMetaLength > 0) { // currently reading metadata
                        const NSUInteger remainingMetaBytes = _currentMetaLength - [_currentMetaPayload length];
                        const NSUInteger bytesToAppend = MIN(remainingMetaBytes, remainingBytes);
                        [_currentMetaPayload appendBytes:currentPtr length:bytesToAppend];
                        
                        if (_currentMetaPayload.length == _currentMetaLength) {
                            [self _processMetadataUpdate:_currentMetaPayload];
                            
                            _currentMetaPayload.length = 0;
                            _currentMetaLength = 0;
                            _bytesReadSinceMeta = 0;
                        }
                        
                        bytesRead += bytesToAppend;
                    } else if (_bytesReadSinceMeta == _metaInterval) { // currently reading metaint
                        uint8_t metaLength = *(uint8_t *)currentPtr * 16;
                        if (metaLength > 0) {
                            _currentMetaLength = (NSUInteger)metaLength;
                        } else {
                            _bytesReadSinceMeta = 0;
                        }
                        
                        bytesRead += 1;
                    } else { // currently reading audio data
                        const NSUInteger audioBytesToRead = MIN(_metaInterval - _bytesReadSinceMeta, remainingBytes);
                        [mutableAudioData appendBytes:currentPtr length:audioBytesToRead];
                        
                        _bytesReadSinceMeta += audioBytesToRead;
                        bytesRead += audioBytesToRead;
                    }
                }
            }];
            
            audioData = mutableAudioData;
        } else {
            audioData = data;
        }
        
        // write the data to the audio stream
        OSStatus status = AudioFileStreamParseBytes(_audioFileStream, (UInt32)audioData.length, audioData.bytes, 0);
        if (status != noErr) {
            [self _logError:@"Failed to write data to audio stream (OSStatus = %d)", status];
            error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
            break;
        }
    } while (0);
    
    if (error) {
        [self _handleError:error];
        [self _closeReadStream];
    }
}

#pragma mark - Callbacks

- (void)_handlePropertyChangeForFileStream:(AudioFileStreamID)stream
                            withPropertyID:(AudioFileStreamPropertyID)propertyID
                                     flags:(UInt32 *)flags
{
    OSStatus status = noErr;
    
    switch (propertyID) {
        case kAudioFileStreamProperty_DataOffset: {
            SInt64 offset = 0;
            UInt32 propertySize = sizeof(SInt64);
            status = AudioFileStreamGetProperty(stream, kAudioFileStreamProperty_DataOffset, &propertySize, &offset);
            if (status == noErr) {
                _dataOffset = (NSUInteger)offset;
            }
        } break;
        
        case kAudioFileStreamProperty_AudioDataByteCount: {
            UInt64 byteCount = 0;
            UInt32 propertySize = sizeof(UInt64);
            status = AudioFileStreamGetProperty(stream, kAudioFileStreamProperty_AudioDataByteCount, &propertySize, &byteCount);
            if (status == noErr) {
                _audioFileLength = (NSUInteger)byteCount;
            }
        } break;
        
        case kAudioFileStreamProperty_DataFormat: {
            AudioStreamBasicDescription format = {0};
            UInt32 propertySize = sizeof(AudioStreamBasicDescription);
            status = AudioFileStreamGetProperty(stream, kAudioFileStreamProperty_DataFormat, &propertySize, &format);
            if (status == noErr) {
                _audioStreamDescription = format;
            }
        } break;
        
        case kAudioFileStreamProperty_FormatList: {
            AudioFormatListItem *formatList = NULL;
            
            do {
                // get the size of the format list
                UInt32 formatListSize = 0;
                status = AudioFileStreamGetPropertyInfo(stream, kAudioFileStreamProperty_FormatList, &formatListSize, NULL);
                if (status != noErr) {
                    [self _logError:@"Failed to get format list size (OSStatus = %d)", status];
                    break;
                }
                
                // get the new list of formats
                formatList = (AudioFormatListItem *)malloc(formatListSize);
                status = AudioFileStreamGetProperty(stream, kAudioFileStreamProperty_FormatList, &formatListSize, formatList);
                if (status != noErr) {
                    [self _logError:@"Failed to get format list data (OSStatus = %d)", status];
                    break;
                }
                
                // find the AAC format that we're interested in parsing
                unsigned formatListCount = formatListSize / sizeof(AudioFormatListItem);
                for (unsigned i = 0; i < formatListCount; ++i) {
                    AudioFormatListItem formatItem = formatList[i];
                    AudioStreamBasicDescription format = formatItem.mASBD;
                    if (format.mFormatID == kAudioFormatMPEG4AAC_HE || format.mFormatID == kAudioFormatMPEG4AAC_HE_V2) {
                        _audioStreamDescription = format;
                        break;
                    }
                }
            } while (0);
            
            if (formatList) {
                free(formatList);
            }
        } break;
    }
    
    if (status != noErr) {
        [self _handleError:[NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil]];
    }
}

- (void)_handleAudioPacketsAvailableWithData:(NSData *)audioData
                                packetsCount:(NSUInteger)packetsCount
                          packetDescriptions:(AudioStreamPacketDescription *)packetDescriptions
{
    NSError *error = nil;
    
    do {
        // make sure we have an audio queue initialized first
        if (!_audioQueue) {
            [self _createAudioOutputQueueWithError:&error];
        }
        if (error) {
            [self _logError:@"Failed to create output queue. %@", error];
            break;
        }
        
        // parse packets
        for (unsigned i = 0; i < packetsCount; ++i) {
            SInt64 packetOffset = packetDescriptions[i].mStartOffset;
            SInt64 packetSize = packetDescriptions[i].mDataByteSize;
            size_t spaceRemaining = _packetBufferSize - _bytesFilled;
            
            if (spaceRemaining < packetSize) {
                [self _enqueueAudioBuffer];
            }
            
            // wait until the current buffer is available
            pthread_mutex_lock(&_queueBuffersMutex);
            while (_queueBuffersUsageStates[_currentBufferIndex]) {
                pthread_cond_wait(&_queueBufferReadyCondition, &_queueBuffersMutex);
            }
            pthread_mutex_unlock(&_queueBuffersMutex);
            
            // copy audio data into buffer
            AudioQueueBufferRef buffer = _audioQueueBuffers[_currentBufferIndex];
            memcpy(buffer->mAudioData + _bytesFilled, audioData.bytes + packetOffset, packetSize);
            
            // store packet description
            AudioStreamPacketDescription packetDescription = packetDescriptions[i];
            packetDescription.mStartOffset = _bytesFilled;
            _packetDescriptions[_packetsFilled] = packetDescription;
            
            _bytesFilled += packetSize;
            _packetsFilled += 1;
            
            NSUInteger packetsRemaining = MAX_PACKET_DESCRIPTIONS - _packetsFilled;
            if (packetsRemaining == 0) {
                [self _enqueueAudioBuffer];
            }
        }
    } while (0);
    
    if (error) {
        [self _logError:@"Error encountered while handling audio packets. %@", error];
        [self _handleError:error];
    }
}

- (void)_handleAudioQueue:(AudioQueueRef)queue propertyDidChange:(AudioQueuePropertyID)property
{
    NSAssert(queue == _audioQueue, @"Incorrect audio queue input for property change");
    
    if (property == kAudioQueueProperty_IsRunning) {
        UInt32 isRunning = 0;
        UInt32 propertySize = sizeof(UInt32);
        AudioQueueGetProperty(_audioQueue, kAudioQueueProperty_IsRunning, &isRunning, &propertySize);
        
        [self _logMessage:@"Received IsRunning property state change for queue %p. New value = %u", queue, isRunning];
        
        if (self.playing && !isRunning) {
            self.playbackState = ZANStreamPlaybackStateStopped;
        }
    }
}

- (void)_handleBufferCompleteFromQueue:(AudioQueueRef)queue buffer:(AudioQueueBufferRef)buffer
{
    NSInteger bufferIdx = NSNotFound;
    for (unsigned i = 0; i < AUDIO_QUEUE_BUFFERS_COUNT; ++i) {
        if (buffer == _audioQueueBuffers[i]) {
            bufferIdx = i;
            break;
        }
    }
    
    NSAssert(bufferIdx != NSNotFound, @"An unknown audio buffer was completed");
    
    pthread_mutex_lock(&_queueBuffersMutex);
    _queueBuffersUsageStates[bufferIdx] = NO;
    pthread_cond_signal(&_queueBufferReadyCondition);
    pthread_mutex_unlock(&_queueBuffersMutex);
}

- (void)_handleTapCallbackFromTap:(AudioQueueProcessingTapRef)tap
                  withFramesCount:(UInt32)inNumberFrames
                   audioTimestamp:(AudioTimeStamp *)ioTimeStamp
               processingTapFlags:(AudioQueueProcessingTapFlags *)flags
                   outFramesCount:(UInt32 *)outNumberFrames
                             data:(AudioBufferList *)ioData
{
    OSStatus status = AudioQueueProcessingTapGetSourceAudio(tap, inNumberFrames, ioTimeStamp, flags, outNumberFrames, ioData);
    if (status != noErr) {
        [self _logError:@"Failed to get source audio in processing tap callback (OSStatus = %d)", status];
    } else {
        AudioBuffer *buffer = &ioData->mBuffers[0];
        NSData *audioData = [NSData dataWithBytesNoCopy:buffer->mData length:buffer->mDataByteSize freeWhenDone:NO];
        [_delegate streamPlayer:self didDecodeAudioData:audioData withFramesCount:inNumberFrames format:&_processingFormat];
    }
}

#pragma mark - Internal

- (BOOL)_openReadStream
{
    [self _logMessage:@"Opening read stream with URL %@", _url];
    
    if (_dataTask) {
        [_dataTask cancel];
    }
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:_url];
    if (_options & ZANStreamPlayerOptionRequestMetadata) {
        [request setValue:@"1" forHTTPHeaderField:@"Icy-MetaData"];
    }
    
    _dataTask = [_urlSession dataTaskWithRequest:request];
    [_dataTask resume];
    
    return YES;
}

- (BOOL)_closeReadStream
{
    [self _logMessage:@"Closing read stream"];
    
    [_dataTask cancel];
    _dataTask = nil;
    
    _currentMetaPayload.length = 0;
    _currentMetaLength = 0;
    _bytesReadSinceMeta = 0;
    
    return YES;
}

- (BOOL)_openAudioStreamWithError:(NSError **)outError
{
    OSStatus status = noErr;
    [self _logMessage:@"Opening audio stream"];
    
    do {
        // close existing stream if necessary
        if (_audioFileStream) {
            status = AudioFileStreamClose(_audioFileStream);
        }
        if (status != noErr) {
            [self _logError:@"Could not close existing audio file stream (OSStatus = %d)", status];
            break;
        }
        
        // open new file stream
        status = AudioFileStreamOpen((__bridge void *)self, _ZANPropertyListenerCallback, _ZANPacketsAvailableCallback, 0, &_audioFileStream);
        if (status != noErr) {
            [self _logError:@"Failed to open audio file stream (OSStatus = %d)", status];
            break;
        }
    } while (0);
    
    if (status == noErr) {
        [self _logMessage:@"Successfully opened audio stream"];
    }
    
    if (outError) {
        *outError = [self _errorFromOSStatus:status];
    }
    
    return (status == noErr);
}

- (BOOL)_closeAudioStream
{
    OSStatus status = noErr;
    
    if (_audioFileStream) {
        [self _logMessage:@"Closing audio stream ID %p", _audioFileStream];
        
        status = AudioFileStreamClose(_audioFileStream);
        if (status != noErr) {
            [self _logError:@"Failed to close audio stream %p", _audioFileStream];
        }
    }
    
    return (status == noErr);
}

- (BOOL)_createAudioOutputQueueWithError:(NSError **)outError
{
    OSStatus status = noErr;
    [self _logMessage:@"Creating audio output queue with stream description %p", _audioStreamDescription];
    
    do {
        // create the audio queue
        status = AudioQueueNewOutput(&_audioStreamDescription, _ZANAudioQueueOutputCallback, (__bridge void *)self, NULL, NULL, 0, &_audioQueue);
        if (status != noErr) {
            [self _logError:@"Failed to create new audio queue output (OSStatus = %d)", status];
            break;
        }
        
        // setup property change handler
        status = AudioQueueAddPropertyListener(_audioQueue, kAudioQueueProperty_IsRunning, _ZANAudioQueuePropertyListenerCallback, (__bridge void *)self);
        if (status != noErr) {
            [self _logError:@"Failed to setup property change listener on audio queue (OSStatus = %d)", status];
            break;
        }
        
        // get the packet size, if available
        UInt32 packetBufferSize = 0;
        UInt32 propertySize = sizeof(UInt32);
        status = AudioFileStreamGetProperty(_audioFileStream, kAudioFileStreamProperty_PacketSizeUpperBound, &propertySize, &packetBufferSize);
        if (status != noErr || packetBufferSize == 0) {
            // fallback to maximum packet size property
            status = AudioFileStreamGetProperty(_audioFileStream, kAudioFileStreamProperty_MaximumPacketSize, &propertySize, &packetBufferSize);
            
            if (status != noErr || packetBufferSize == 0) {
                // fallback to default size
                packetBufferSize = DEFAULT_BUFFER_SIZE;
            }
        }
        _packetBufferSize = packetBufferSize;
        
        // allocate audio queue buffers
        for (unsigned i = 0; i < AUDIO_QUEUE_BUFFERS_COUNT; ++i) {
            status = AudioQueueAllocateBuffer(_audioQueue, (UInt32)_packetBufferSize, &_audioQueueBuffers[i]);
            if (status != noErr) {
                [self _logError:@"Failed to allocate audio queue buffer (OSStatus = %d)", status];
                break;
            }
        }
        
        // create processing tap, if requested
        if (_options & ZANStreamPlayerOptionInstallProcessingTap) {
            UInt32 maxFrames = 0;
            status = AudioQueueProcessingTapNew(_audioQueue,
                                                _ZANAudioQueueProcessingTapCallback,
                                                (__bridge void *)self,
                                                kAudioQueueProcessingTap_PostEffects,
                                                &maxFrames,
                                                &_processingFormat,
                                                &_processingTap);
            if (status != noErr) {
                [self _logError:@"Failed to initialize processing tap (OSStatus = %d)", status];
                break;
            }
        }
    } while (0);
    
    if (outError) {
        *outError = [self _errorFromOSStatus:status];
    }
    
    return (status == noErr);
}

- (void)_destroyAudioOutputQueue
{
    if (_audioQueue) {
        for (unsigned i = 0; i < AUDIO_QUEUE_BUFFERS_COUNT; ++i) {
            if (_audioQueueBuffers[i] != NULL) {
                AudioQueueFreeBuffer(_audioQueue, _audioQueueBuffers[i]);
                _audioQueueBuffers[i] = NULL;
            }
        }
        
        AudioQueuePause(_audioQueue);
        AudioQueueDispose(_audioQueue, false);
        _audioQueue = NULL;
    }
}

- (void)_enqueueAudioBuffer
{
    OSStatus status = noErr;
    
    do {
        // mark that this buffer is in use
        pthread_mutex_lock(&_queueBuffersMutex);
        _queueBuffersUsageStates[_currentBufferIndex] = YES;
        pthread_mutex_unlock(&_queueBuffersMutex);
        
        // fill in bytes used
        AudioQueueBufferRef buffer = _audioQueueBuffers[_currentBufferIndex];
        buffer->mAudioDataByteSize = (UInt32)_bytesFilled;
        
        // enqueue buffer
        status = AudioQueueEnqueueBuffer(_audioQueue, buffer, (UInt32)_packetsFilled, _packetDescriptions);
        if (status != noErr) {
            [self _logError:@"Failed to enqueue audio buffer (OSStatus = %d)", status];
            break;
        }
        
        // start the audio queue processing hardware if necessary
        if ([self isPlaying]) {
            status = AudioQueueStart(_audioQueue, NULL);
            if (status != noErr) {
                [self _logError:@"Failed to start audio queue hardware (OSStatus = %d)", status];
                break;
            }
        }
        
        // go to next buffer
        _currentBufferIndex = (_currentBufferIndex + 1) % AUDIO_QUEUE_BUFFERS_COUNT;
        _bytesFilled = 0;
        _packetsFilled = 0;
    } while (0);
}

- (void)_processMetadataUpdate:(NSData *)metadata
{
    /* metadata is in the following format: "StreamTitle='Charmer & Kadenza - Garden of Dreams (HandzUpNightcore Remix)';StreamUrl='';" */
    NSString *metadataString = [[NSString alloc] initWithData:metadata encoding:NSUTF8StringEncoding];
    NSArray<NSString *> *metadataComponents = [metadataString componentsSeparatedByString:@";"];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(\\w+)='(.*)'" options:0 error:nil];
    NSMutableDictionary *metadataDict = [[NSMutableDictionary alloc] init];
    
    for (NSString *metadataComponent in metadataComponents) {
        NSRange range = NSMakeRange(0, metadataComponent.length);
        [regex enumerateMatchesInString:metadataComponent options:0 range:range usingBlock:^(NSTextCheckingResult *result,
                                                                                             NSMatchingFlags flags,
                                                                                             BOOL *stop)
        {
            if (result.numberOfRanges >= 3) {
                NSString *key = [metadataComponent substringWithRange:[result rangeAtIndex:1]];
                NSString *value = [metadataComponent substringWithRange:[result rangeAtIndex:2]];
                [metadataDict setObject:value forKey:key];
            }
        }];
    }
    
    _currentMetadata = metadataDict;
    
    if ([_delegate respondsToSelector:@selector(streamPlayer:didReceiveMetadataUpdate:)]) {
        [_delegate streamPlayer:self didReceiveMetadataUpdate:metadataDict];
    }
}

- (NSError *)_errorFromOSStatus:(OSStatus)status
{
    NSError *error = nil;
    if (status != noErr) {
        error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
    }
    return error;
}

- (void)_handleError:(NSError *)error
{
    [self _logError:@"%@", error];
    
    if ([_delegate respondsToSelector:@selector(streamPlayer:didEncounterError:)]) {
        [_delegate streamPlayer:self didEncounterError:error];
    }
}

- (void)_logMessage:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    NSLog(@"%@: %@", NSStringFromClass([self class]), message);
}

- (void)_logError:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    NSLog(@"%@ ERROR: %@", NSStringFromClass([self class]), message);
}

#pragma mark - AudioFileStream Callbacks

void _ZANPropertyListenerCallback(void *clientData,
                                  AudioFileStreamID fileStream,
                                  AudioFileStreamPropertyID propertyID,
                                  UInt32 *flags)
{
    @autoreleasepool {
        ZANStreamPlayer *player = (__bridge ZANStreamPlayer *)clientData;
        [player _handlePropertyChangeForFileStream:fileStream withPropertyID:propertyID flags:flags];
    }
}

void _ZANPacketsAvailableCallback(void *clientData,
                                  UInt32 bytesLength,
                                  UInt32 packetsCount,
                                  const void *data,
                                  AudioStreamPacketDescription *packetDescriptions)
{
    @autoreleasepool {
        ZANStreamPlayer *player = (__bridge ZANStreamPlayer *)clientData;
        NSData *audioData = [NSData dataWithBytesNoCopy:(void *)data length:bytesLength freeWhenDone:NO];
        [player _handleAudioPacketsAvailableWithData:audioData packetsCount:packetsCount packetDescriptions:packetDescriptions];
    }
}

void _ZANAudioQueuePropertyListenerCallback(void *clientData,
                                            AudioQueueRef audioQueue,
                                            AudioQueuePropertyID propertyID)
{
    @autoreleasepool {
        ZANStreamPlayer *player = (__bridge ZANStreamPlayer *)clientData;
        [player _handleAudioQueue:audioQueue propertyDidChange:propertyID];
    }
}

void _ZANAudioQueueOutputCallback(void *clientData, AudioQueueRef audioQueue, AudioQueueBufferRef buffer)
{
    @autoreleasepool {
        ZANStreamPlayer *player = (__bridge ZANStreamPlayer *)clientData;
        [player _handleBufferCompleteFromQueue:audioQueue buffer:buffer];
    }
}

void _ZANAudioQueueProcessingTapCallback(void *clientData,
                                         AudioQueueProcessingTapRef tap,
                                         UInt32 framesCount,
                                         AudioTimeStamp *timestamp,
                                         AudioQueueProcessingTapFlags *flags,
                                         UInt32 *outFramesCount,
                                         AudioBufferList *data)
{
    @autoreleasepool {
        ZANStreamPlayer *player = (__bridge ZANStreamPlayer *)clientData;
        [player _handleTapCallbackFromTap:tap
                          withFramesCount:framesCount
                           audioTimestamp:timestamp
                       processingTapFlags:flags
                           outFramesCount:outFramesCount
                                     data:data];
    }
}

@end

@implementation ZANURLSessionDelegateWeakForwarder

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if ([_forwardedDelegate respondsToSelector:@selector(URLSession:task:didCompleteWithError:)]) {
        [_forwardedDelegate URLSession:session task:task didCompleteWithError:error];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    if ([_forwardedDelegate respondsToSelector:@selector(URLSession:dataTask:didReceiveData:)]) {
        [_forwardedDelegate URLSession:session dataTask:dataTask didReceiveData:data];
    }
}

@end
