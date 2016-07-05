//
//  ZANStreamPlayer.h
//  StreamPlayer
//
//  Created by Charles Magahern on 7/4/16.
//  Copyright © 2016 zanneth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudioTypes.h>

NS_ASSUME_NONNULL_BEGIN

@class ZANStreamPlayer;

@protocol ZANStreamPlayerDelegate <NSObject>
@optional

- (void)streamPlayerPlaybackStateDidChange:(ZANStreamPlayer *)player;
- (void)streamPlayer:(ZANStreamPlayer *)player didEncounterError:(NSError *)error;

// must initialize stream player with ZANStreamPlayerOptionInstallProcessingTap
- (void)streamPlayer:(ZANStreamPlayer *)player
  didDecodeAudioData:(NSData *)data
     withFramesCount:(NSUInteger)framesCount
              format:(const AudioStreamBasicDescription *)format;

// must initialize stream player with ZANStreamPlayerOptionRequestMetadata
- (void)streamPlayer:(ZANStreamPlayer *)player didReceiveMetadataUpdate:(NSDictionary<NSString *, NSString *> *)metadata;

@end

// -----------------------------------------------------------------------------

typedef NS_OPTIONS(NSUInteger, ZANStreamPlayerOptions)
{
    ZANStreamPlayerOptionNone                   = 0,
    ZANStreamPlayerOptionInstallProcessingTap   = (1 << 0),
    ZANStreamPlayerOptionRequestMetadata        = (1 << 1),
};

// -----------------------------------------------------------------------------

@interface ZANStreamPlayer : NSObject

@property (nonatomic, weak) id<ZANStreamPlayerDelegate> delegate;

@property (nonatomic, readonly) NSURL *url;
@property (nonatomic, readonly) ZANStreamPlayerOptions options;
@property (nonatomic, readonly) NSDictionary *currentMetadata;
@property (nonatomic, readonly, getter=isPlaying) BOOL playing;
@property (nonatomic, readonly, getter=isStopped) BOOL stopped;

- (instancetype)initWithURL:(NSURL *)url options:(ZANStreamPlayerOptions)options;

- (void)play;
- (void)pause;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
