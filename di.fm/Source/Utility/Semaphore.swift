//
//  Semaphore.swift
//  XIONControlPanel
//
//  Created by Charles Magahern on 1/18/16.
//  Copyright © 2016 XION. All rights reserved.
//

import Foundation

class Semaphore
{
    fileprivate var _semaphore: DispatchSemaphore
    
    init(value: Int)
    {
        _semaphore = DispatchSemaphore(value: value)
    }
    
    func wait()
    {
        self.wait(nil)
    }
    
    func wait(_ untilDate: Date?)
    {
        var time: DispatchTime = DispatchTime.distantFuture
        if let untilDate = untilDate {
            time = DispatchTime(uptimeNanoseconds: UInt64(untilDate.timeIntervalSinceNow) * NSEC_PER_SEC)
        }
        
        _ = _semaphore.wait(timeout: time)
    }
    
    func signal()
    {
        _semaphore.signal()
    }
}
