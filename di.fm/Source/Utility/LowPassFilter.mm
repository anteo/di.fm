//
//  LowPassFilter.cpp
//  DigitallyImportedVisualizer
//
//  Created by Charles Magahern on 6/26/16.
//  Copyright © 2016 zanneth. All rights reserved.
//

#import "LowPassFilter.h"
#import <deque>

@implementation LowPassFilter
{
    std::deque<float> _deque;
}

- (instancetype)initWithLength:(NSUInteger)length
{
    self = [super init];
    if (self) {
        _length = length;
    }
    return self;
}

- (void)updateWithSignalValue:(float)signal
{
    _deque.push_front(signal);
    if (_deque.size() > _length) {
        _deque.pop_back();
    }
}

- (float)movingAverage
{
    float sum = 0.0;
    for (const float &v : _deque) {
        sum += v;
    }
    return (sum / _deque.size());
}

@end
