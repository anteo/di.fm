//
//  AudioAddictServer.swift
//  di.fm
//
//  Created by Charles Magahern on 5/7/16.
//

import CoreGraphics
import Foundation

class AudioAddictServer
{
    private var _urlSession:        NSURLSession
    private var _operationQueue:    NSOperationQueue = NSOperationQueue()
    private var _errorStream:       StandardErrorOutputStream = StandardErrorOutputStream()
    private var _authenticatedUser: AuthenticatedUser?
    
    private static let _BaseURL = NSURL(string: "http://api.audioaddict.com/v1/di/")!
    private static let _APIKey = "ZXBoZW1lcm9uOmRheWVpcGgwbmVAcHA="
    
    init()
    {
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        _urlSession = NSURLSession(configuration: config)
    }
    
    func authenticate(username: String, password: String, completion: (AuthenticatedUser?, NSError?) -> (Void))
    {
        let operation = AuthenticationOperation(baseURL: AudioAddictServer._BaseURL, session: _urlSession)
        operation.username = username
        operation.password = password
        
        weak var weakOp = operation
        operation.completionBlock = {
            guard let strongOp = weakOp else { completion(nil, nil) ; return }
            
            if (strongOp.error != nil) {
                self._logError("authentication failure", error: strongOp.error!)
            }
            
            if (strongOp.newAuthenticatedUser != nil) {
                self._authenticatedUser = strongOp.newAuthenticatedUser
            }
            
            completion(strongOp.newAuthenticatedUser, strongOp.error)
        }
        
        _operationQueue.addOperation(operation)
    }
    
    func fetchBatchUpdate(streamQuality: Stream.Quality, completion: (BatchUpdate?, NSError?) -> (Void))
    {
        let operation = BatchUpdateOperation(baseURL: AudioAddictServer._BaseURL, session: _urlSession)
        operation.authenticatedUser = _authenticatedUser
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
    
    func loadChannelArtwork(channelImage: ChannelImage, size: CGSize, completion: (NSData?, NSError?) -> (Void))
    {
        let operation = LoadChannelArtworkOperation(baseURL: AudioAddictServer._BaseURL, session: _urlSession)
        operation.channelImage = channelImage
        operation.sizeHint = size
        
        weak var weakOp = operation
        operation.completionBlock = {
            guard let strongOp = weakOp else { completion(nil, nil) ; return }
            if (strongOp.error != nil) {
                self._logError("could not fetch artwork data", error: strongOp.error!)
            }
            
            completion(strongOp.imageData, strongOp.error)
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
    var baseURL:             NSURL
    var session:             NSURLSession
    var authenticatedUser:   AuthenticatedUser?
    internal(set) var error: NSError?
    
    init(baseURL: NSURL, session: NSURLSession)
    {
        self.baseURL = baseURL
        self.session = session
    }
    
    func requiresAuthentication() -> Bool
    {
        return false
    }
    
    func fetchData(url: NSURL) -> NSData?
    {
        var fetchedData: NSData?
        
        if (self.authenticatedUser != nil || !self.requiresAuthentication()) {
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
        } else {
            self.error = NSError.difmError(.AuthenticationError, description: NSLocalizedString("AUTH_ERROR_NOT_AUTHENTICATED", comment: ""))
        }
        
        return fetchedData
    }
    
    func fetchResponse(request: NSURLRequest) -> (NSData?, NSURLResponse?)
    {
        var fetchedData: NSData?
        var fetchedResponse: NSURLResponse?
        
        if (self.authenticatedUser != nil || !self.requiresAuthentication()) {
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
        } else {
            self.error = NSError.difmError(.AuthenticationError, description: NSLocalizedString("AUTH_ERROR_NOT_AUTHENTICATED", comment: ""))
        }
        
        return (fetchedData, fetchedResponse)
    }
}

internal class AuthenticationOperation : ServerOperation
{
    var username: String = ""
    var password: String = ""
    internal(set) var newAuthenticatedUser: AuthenticatedUser?
    
    override func main()
    {
        let url = self.baseURL.URLByAppendingPathComponent("members/authenticate")
        let urlComponents = NSURLComponents(URL: url, resolvingAgainstBaseURL: false)!
        urlComponents.scheme = "https"
        
        let request = NSMutableURLRequest(URL: urlComponents.URL!)
        let httpBody = NSString(format: "username=%@&password=%@", self.username, self.password)
        request.HTTPBody = NSData(bytes: httpBody.UTF8String, length: httpBody.length)
        request.HTTPMethod = "POST"
        
        let (data, response) = self.fetchResponse(request)
        var successfulResponse = false
        if let httpResponse = response as? NSHTTPURLResponse {
            successfulResponse = (httpResponse.statusCode == 200)
        }
        
        if (data != nil && successfulResponse) {
            if let jsonDict = (try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions()) as? NSDictionary) {
                self.newAuthenticatedUser = AuthenticatedUser(jsonDict!)
            }
        } else {
            self.error = NSError.difmError(.AuthenticationError, description: NSLocalizedString("AUTH_ERROR_USERNAME_OR_PASSWORD", comment: ""))
        }
    }
}

internal class BatchUpdateOperation : ServerOperation
{
    var streamQuality: Stream.Quality = .Public1
    internal(set) var batchUpdate: BatchUpdate? = nil
    
    override func requiresAuthentication() -> Bool
    {
        return true
    }
    
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

internal class LoadChannelArtworkOperation : ServerOperation
{
    var sizeHint:       CGSize = CGSize(width: 300.0, height: 300.0)
    var channelImage:   ChannelImage = ChannelImage()
    
    internal(set) var imageData: NSData? = nil
    
    override func main()
    {
        let urlParams = ["width" : "\(self.sizeHint.width)", "height" : "\(self.sizeHint.height)"]
        let artworkURL = self.channelImage.defaultURL.url(urlParams)
        self.imageData = self.fetchData(artworkURL)
    }
}
