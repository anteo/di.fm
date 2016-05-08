//
//  AudioAddictServer.swift
//  di.fm
//
//  Created by Charles Magahern on 5/7/16.
//

import Foundation

class AudioAddictServer
{
    static let sharedServer = AudioAddictServer()
    
    private var _urlSession:        NSURLSession
    private var _operationQueue:    NSOperationQueue = NSOperationQueue()
    private var _errorStream:       StandardErrorOutputStream = StandardErrorOutputStream()
    
    private static let _BaseURL = NSURL(string: "http://api.audioaddict.com/v1/di/")!
    private static let _APIKey = "ZXBoZW1lcm9uOmRheWVpcGgwbmVAcHA="
    
    init()
    {
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        _urlSession = NSURLSession(configuration: config)
        _operationQueue.maxConcurrentOperationCount = 1
    }
    
    func fetchBatchUpdate(streamQuality: Stream.Quality, completion: (BatchUpdate?, NSError?) -> (Void))
    {
        let operation = BatchUpdateOperation(baseURL: AudioAddictServer._BaseURL, session: _urlSession)
        operation.streamQuality = streamQuality
        
        weak var weakOp = operation
        operation.completionBlock = {
            guard let strongOp = weakOp else { completion(nil, nil) ; return }
            if (strongOp.error != nil) {
                self._logError("could not fetch batch update", error: strongOp.error!)
            }
            
            completion(strongOp.batchUpdate, strongOp.error)
        }
        
        _operationQueue.addOperation(operation)
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
    
    func fetchResponse(request: NSURLRequest) -> (NSData?, NSURLResponse?)
    {
        var fetchedData: NSData?
        var fetchedResponse: NSURLResponse?
        let semaphore = Semaphore(value: 0)
        
        let task = self.session.dataTaskWithRequest(request) { (data: NSData?, response: NSURLResponse?, error: NSError?) in
            fetchedResponse = response
            if (data != nil) {
                fetchedData = data
            } else {
                self.error = NSError.difmError(.ConnectionError, underlying: error)
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
        
        return (fetchedData, fetchedResponse)
    }
}

internal class BatchUpdateOperation : ServerOperation
{
    var streamQuality: Stream.Quality = .Public1
    
    internal(set) var batchUpdate: BatchUpdate? = nil
    
    override func main()
    {
        let batchUpdateURL = self.baseURL.URLByAppendingPathComponent("mobile/batch_update")
        let urlComponents = NSURLComponents(URL: batchUpdateURL, resolvingAgainstBaseURL: false)!
        urlComponents.query = "stream_set_key=\(self.streamQuality.rawValue)"
        
        let request = NSMutableURLRequest(URL: urlComponents.URL!)
        request.addValue("Basic: \(AudioAddictServer._APIKey)", forHTTPHeaderField: "Authorization")
        
        let data = self.fetchResponse(request).0
        if (data != nil) {
            if let jsonDict = (try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions()) as? NSDictionary) {
                self.batchUpdate = BatchUpdate(jsonDict!)
            }
        }
    }
}
