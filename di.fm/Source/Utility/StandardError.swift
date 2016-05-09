//
//  StandardError.swift
//  XIONControlPanel
//
//  Created by Charles Magahern on 12/31/15.
//  Copyright © 2015 XION. All rights reserved.
//

import Foundation

class StandardErrorOutputStream : OutputStreamType
{
    private var _stderr = NSFileHandle.fileHandleWithStandardError()
    
    func write(string: String)
    {
        _stderr.writeData(string.dataUsingEncoding(NSUTF8StringEncoding)!)
    }
}
