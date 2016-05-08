//
//  AudioAddictServer.swift
//  di.fm
//
//  Created by Charles Magahern on 5/7/16.
//

import Foundation

class AudioAddictServer
{
    private var _urlSession:        NSURLSession
    private var _operationQueue:    NSOperationQueue = NSOperationQueue()
    private var _errorStream:       StandardErrorOutputStream = StandardErrorOutputStream()
    
    init()
    {
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        _urlSession = NSURLSession(configuration: config)
        _operationQueue.maxConcurrentOperationCount = 1
    }
    
    // MARK: Internal
    
    internal func _logError(description: String, error: NSError)
    {
        print("ERROR: \(description) \(error)", toStream: &_errorStream)
    }
}

internal class ServerOperation : NSOperation
{
    var baseURL:    NSURL
    var session:    NSURLSession
    internal(set) var error: NSError?
    
    init(baseURL: NSURL, session: NSURLSession)
    {
        self.baseURL = baseURL
        self.session = session
    }
    
    func fetchData(url: NSURL) -> NSData?
    {
        var fetchedData: NSData?
        let semaphore = Semaphore(value: 0)
        
        let task = self.session.dataTaskWithURL(url) { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            if (data != nil) {
                fetchedData = data
            } else {
                self.error = NSError.difmError(.ConnectionError, underlying: error)
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
        
        return fetchedData
    }
}
