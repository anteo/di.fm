//
//  FFTProcessor.m
//  DigitallyImportedVisualizer
//
//  Created by Charles Magahern on 6/26/16.
//  Copyright © 2016 zanneth. All rights reserved.
//

#import "FFTProcessor.h"
#import <Accelerate/Accelerate.h>

typedef struct
{
    void *userInfo;
} DIFMAudioProcessingContext;

static void _DIFMTapInitCallback(MTAudioProcessingTapRef tap, void *info, void **storageOut);
static void _DIFMTapFinalizeCallback(MTAudioProcessingTapRef tap);
static void _DIFMTapProcessCallback(MTAudioProcessingTapRef tap,
                                    CMItemCount numberFrames,
                                    MTAudioProcessingTapFlags flags,
                                    AudioBufferList *bufferListInOut,
                                    CMItemCount *numberFramesOut,
                                    MTAudioProcessingTapFlags *flagsOut);

@implementation FFTProcessor
{
    AVAudioMix *_audioMix;
}

- (instancetype)initWithTrack:(AVAssetTrack *)track
{
    self = [super init];
    if (self) {
        _track = track;
    }
    return self;
}

#pragma mark - Accessors

- (AVAudioMix *)audioMix
{
    if (!_audioMix) {
        AVMutableAudioMix *audioMix = [[AVMutableAudioMix alloc] init];
        AVMutableAudioMixInputParameters *inputParams = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:_track];
        MTAudioProcessingTapCallbacks callbacks = {
            .version = kMTAudioProcessingTapCallbacksVersion_0,
            .clientInfo = (__bridge void *)self,
            .init = _DIFMTapInitCallback,
            .finalize = _DIFMTapFinalizeCallback,
            .prepare = NULL,
            .unprepare = NULL,
            .process = _DIFMTapProcessCallback
        };
        
        MTAudioProcessingTapRef tap = NULL;
        OSStatus status = MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks, kMTAudioProcessingTapCreationFlag_PreEffects, &tap);
        if (status == noErr) {
            inputParams.audioTapProcessor = tap;
            CFRelease(tap);
            
            audioMix.inputParameters = @[inputParams];
            _audioMix = audioMix;
        } else {
            fprintf(stderr, "failed to create audio processing tap (status = %d)", status);
        }
    }
    
    return _audioMix;
}

#pragma mark - Tap Callbacks

void _DIFMTapInitCallback(MTAudioProcessingTapRef tap, void *info, void **storageOut)
{
    DIFMAudioProcessingContext *ctx = malloc(sizeof(DIFMAudioProcessingContext));
    ctx->userInfo = info;
    *storageOut = ctx;
}

void _DIFMTapFinalizeCallback(MTAudioProcessingTapRef tap)
{
    DIFMAudioProcessingContext *ctx = (DIFMAudioProcessingContext *)MTAudioProcessingTapGetStorage(tap);
    ctx->userInfo = NULL;
    free(ctx);
}

void _DIFMTapProcessCallback(MTAudioProcessingTapRef tap,
                             CMItemCount numberFrames,
                             MTAudioProcessingTapFlags flags,
                             AudioBufferList *bufferListInOut,
                             CMItemCount *numberFramesOut,
                             MTAudioProcessingTapFlags *flagsOut)
{
    const int bufferLog2 = round(log2(numberFrames));
    const float fftNorm = (1.0 / (2 * numberFrames));
    const long halfFrameCount = (numberFrames / 2);
    float outReal[halfFrameCount];
    float outImaginary[halfFrameCount];
    COMPLEX_SPLIT fftOutput = { .realp = outReal, .imagp = outImaginary };
    
    FFTSetup fft = vDSP_create_fftsetup(bufferLog2, kFFTRadix2);
    OSStatus status = MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, NULL, numberFramesOut);
    if (status == noErr) {
        AudioBuffer *buffer = &bufferListInOut->mBuffers[0];
        
        // put all even elements into real component, and odd elements into the imaginary component
        vDSP_ctoz((COMPLEX *)buffer->mData, 2, &fftOutput, 1, halfFrameCount);
        
        // perform fft
        vDSP_fft_zrip(fft, &fftOutput, 1, bufferLog2, FFT_FORWARD);
        
        // scale data
        vDSP_vsmul(fftOutput.realp, 1, &fftNorm, fftOutput.realp, 1, halfFrameCount);
        vDSP_vsmul(fftOutput.imagp, 1, &fftNorm, fftOutput.imagp, 1, halfFrameCount);
        
        // read absolute value from data
        NSMutableData *frequencyData = [[NSMutableData alloc] initWithLength:(halfFrameCount * sizeof(float))];
        vDSP_zvabs(&fftOutput, 1, frequencyData.mutableBytes, 1, halfFrameCount);
        
        // call delegate
        DIFMAudioProcessingContext *ctx = (DIFMAudioProcessingContext *)MTAudioProcessingTapGetStorage(tap);
        FFTProcessor *processor = (__bridge FFTProcessor *)ctx->userInfo;
        [processor.delegate processor:processor didProcessFrequencyData:frequencyData];
    } else {
        fprintf(stderr, "failed to read audio data from tap (status = %d)", status);
    }
    
    vDSP_destroy_fftsetup(fft);
}

@end
