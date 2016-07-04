//
//  LowPassFilter.h
//  DigitallyImportedVisualizer
//
//  Created by Charles Magahern on 6/26/16.
//  Copyright © 2016 zanneth. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LowPassFilter : NSObject

@property (nonatomic, readonly) NSUInteger length;

- (instancetype)initWithLength:(NSUInteger)length NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)updateWithSignalValue:(float)signal;
- (float)movingAverage;

@end
