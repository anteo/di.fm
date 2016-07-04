//
//  FFTProcessor.m
//  DigitallyImportedVisualizer
//
//  Created by Charles Magahern on 6/26/16.
//  Copyright © 2016 zanneth. All rights reserved.
//

#import "FFTProcessor.h"
#import <Accelerate/Accelerate.h>

static void _DIFMTapInitCallback(MTAudioProcessingTapRef tap, void *info, void **storageOut);
static void _DIFMTapFinalizeCallback(MTAudioProcessingTapRef tap);
static void _DIFMTapProcessCallback(MTAudioProcessingTapRef tap,
                                    CMItemCount numberFrames,
                                    MTAudioProcessingTapFlags flags,
                                    AudioBufferList *bufferListInOut,
                                    CMItemCount *numberFramesOut,
                                    MTAudioProcessingTapFlags *flagsOut);

@implementation FFTProcessor

- (AVAudioMix *)audioMixWithAssetTrack:(AVAssetTrack *)track
{
    AVMutableAudioMix *audioMix = [[AVMutableAudioMix alloc] init];
    AVMutableAudioMixInputParameters *inputParams = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:track];
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
    } else {
        fprintf(stderr, "failed to create audio processing tap (status = %d)", status);
    }
    
    return audioMix;
}

- (void)processAudioData:(NSData *)data withFramesCount:(NSUInteger)framesCount
{
    const int bufferLog2 = round(log2(framesCount));
    const float fftNorm = (1.0 / (2 * framesCount));
    const long halfFrameCount = (framesCount / 2);
    float outReal[halfFrameCount];
    float outImaginary[halfFrameCount];
    
    // allocate memory for FFT and prepare input
    FFTSetup fft = vDSP_create_fftsetup(bufferLog2, kFFTRadix2);
    COMPLEX_SPLIT fftOutput = { .realp = outReal, .imagp = outImaginary };
    
    // put all even elements into real component, and odd elements into the imaginary component
    vDSP_ctoz((COMPLEX *)data.bytes, 2, &fftOutput, 1, halfFrameCount);
    
    // perform fft
    vDSP_fft_zrip(fft, &fftOutput, 1, bufferLog2, FFT_FORWARD);
    
    // scale data
    vDSP_vsmul(fftOutput.realp, 1, &fftNorm, fftOutput.realp, 1, halfFrameCount);
    vDSP_vsmul(fftOutput.imagp, 1, &fftNorm, fftOutput.imagp, 1, halfFrameCount);
    
    // read absolute value from data
    NSMutableData *frequencyData = [[NSMutableData alloc] initWithLength:(halfFrameCount * sizeof(float))];
    vDSP_zvabs(&fftOutput, 1, frequencyData.mutableBytes, 1, halfFrameCount);
    
    // call delegate
    [_delegate processor:self didProcessFrequencyData:frequencyData];
    
    vDSP_destroy_fftsetup(fft);
}

#pragma mark - Tap Callbacks

void _DIFMTapInitCallback(MTAudioProcessingTapRef tap, void *info, void **storageOut)
{
    *storageOut = info;
}

void _DIFMTapFinalizeCallback(MTAudioProcessingTapRef tap)
{}

void _DIFMTapProcessCallback(MTAudioProcessingTapRef tap,
                             CMItemCount numberFrames,
                             MTAudioProcessingTapFlags flags,
                             AudioBufferList *bufferListInOut,
                             CMItemCount *numberFramesOut,
                             MTAudioProcessingTapFlags *flagsOut)
{
    OSStatus status = MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, NULL, numberFramesOut);
    if (status == noErr) {
        FFTProcessor *processor = (__bridge FFTProcessor *)MTAudioProcessingTapGetStorage(tap);
        AudioBuffer *buffer = &bufferListInOut->mBuffers[0];
        NSData *audioData = [NSData dataWithBytesNoCopy:buffer->mData length:buffer->mDataByteSize freeWhenDone:NO];
        [processor processAudioData:audioData withFramesCount:(NSUInteger)numberFrames];
    } else {
        fprintf(stderr, "failed to read audio data from tap (status = %d)", status);
    }
}

@end
