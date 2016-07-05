//
//  AudioTapProcessor.h
//  DigitallyImportedVisualizer
//
//  Created by Charles Magahern on 6/26/16.
//  Copyright © 2016 zanneth. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class FFTProcessor;

@protocol FFTProcessorDelegate <NSObject>

- (void)processor:(FFTProcessor *)processor didProcessFrequencyData:(NSData *)data;

@end

// -----------------------------------------------------------------------------

@interface FFTProcessor : NSObject

@property (nonatomic, weak, nullable) id<FFTProcessorDelegate> delegate;

- (AVAudioMix *)audioMixWithAssetTrack:(AVAssetTrack *)track;
- (void)processAudioData:(NSData *)data withFramesCount:(NSUInteger)framesCount;

@end

NS_ASSUME_NONNULL_END
