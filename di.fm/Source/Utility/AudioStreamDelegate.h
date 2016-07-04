//
//  AudioStreamDataSource.h
//  di.fm
//
//  Created by Charles Magahern on 7/3/16.
//  Copyright © 2016 zanneth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudioTypes.h>

@protocol AudioStreamDelegate <NSObject>

- (void)audioStreamDidDecodeAudioData:(NSData *)data framesCount:(NSUInteger)framesCount;

@end
