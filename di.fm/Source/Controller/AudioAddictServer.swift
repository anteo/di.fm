//
//  AudioAddictServer.swift
//  di.fm
//
//  Created by Charles Magahern on 5/7/16.
//  Copyright © 2016 zanneth. All rights reserved.
//

import CoreGraphics
import Foundation

class AudioAddictServer
{
    fileprivate var _urlSession:        URLSession
    fileprivate var _operationQueue:    OperationQueue = OperationQueue()
    fileprivate var _errorStream:       StandardErrorOutputStream = StandardErrorOutputStream()
    fileprivate var _authenticatedUser: AuthenticatedUser?
    
    fileprivate static let _BaseURL = URL(string: "http://api.audioaddict.com/v1/di/")!
    fileprivate static let _APIKey = "ZXBoZW1lcm9uOmRheWVpcGgwbmVAcHA="
    
    var authenticatedUser: AuthenticatedUser? {
        get {
            return _authenticatedUser;
        }
    }
    
    init()
    {
        let config = URLSessionConfiguration.default
        _urlSession = URLSession(configuration: config)
    }
    
    func authenticate(username: String, password: String, completion: @escaping (AuthenticatedUser?, Error?) -> (Void))
    {
        let operation = AuthenticationOperation(baseURL: AudioAddictServer._BaseURL, session: _urlSession)
        operation.username = username
        operation.password = password
        
        weak var weakOp = operation
        operation.completionBlock = {
            guard let strongOp = weakOp else { completion(nil, nil) ; return }
            
            if let error = strongOp.error {
                self._logError("authentication failure", error: error)
            }
            
            if (strongOp.newAuthenticatedUser != nil) {
                self._authenticatedUser = strongOp.newAuthenticatedUser
            }
            
            completion(strongOp.newAuthenticatedUser, strongOp.error)
        }
        
        _operationQueue.addOperation(operation)
    }
    
    func fetchBatchUpdate(_ streamQuality: Stream.Quality, completion: @escaping (BatchUpdate?, Error?) -> (Void))
    {
        let operation = BatchUpdateOperation(baseURL: AudioAddictServer._BaseURL, session: _urlSession)
        operation.authenticatedUser = _authenticatedUser
        operation.streamQuality = streamQuality
        
        weak var weakOp = operation
        operation.completionBlock = {
            guard let strongOp = weakOp else { completion(nil, nil) ; return }
            
            if let error = strongOp.error {
                self._logError("could not fetch batch update", error: error)
            }
            
            completion(strongOp.batchUpdate, strongOp.error)
        }
        
        _operationQueue.addOperation(operation)
    }
    
    func loadChannelArtwork(channelImage: ChannelImage, size: CGSize, completion: @escaping (Data?, Error?) -> (Void))
    {
        let operation = LoadChannelArtworkOperation(baseURL: AudioAddictServer._BaseURL, session: _urlSession)
        operation.channelImage = channelImage
        operation.sizeHint = size
        
        weak var weakOp = operation
        operation.completionBlock = {
            guard let strongOp = weakOp else { completion(nil, nil) ; return }
            
            if let error = strongOp.error {
                self._logError("could not fetch artwork data", error: error)
            }
            
            completion(strongOp.imageData, strongOp.error)
        }
        
        _operationQueue.addOperation(operation)
    }
    
    // MARK: Internal
    
    internal func _logError(_ description: String, error: Error)
    {
        #if DEBUG
        _errorStream.write("ERROR: \(description) \(error.localizedDescription)\n")
        #endif
    }
}

internal class ServerOperation : Operation
{
    var baseURL:             URL
    var session:             URLSession
    var authenticatedUser:   AuthenticatedUser?
    internal(set) var error: Error?
    
    init(baseURL: URL, session: URLSession)
    {
        self.baseURL = baseURL
        self.session = session
    }
    
    func requiresAuthentication() -> Bool
    {
        return false
    }
    
    func fetchData(_ url: URL) -> Data?
    {
        var fetchedData: Data?
        
        if (self.authenticatedUser != nil || !self.requiresAuthentication()) {
            let semaphore = Semaphore(value: 0)
            let task = self.session.dataTask(with: url, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
                if (data != nil) {
                    fetchedData = data
                } else {
                    self.error = error
                }
                semaphore.signal()
            })
            task.resume()
            semaphore.wait()
        } else {
            self.error = DIError(.authenticationError)
        }
        
        return fetchedData
    }
    
    func fetchResponse(_ request: URLRequest) -> (Data?, URLResponse?)
    {
        var fetchedData: Data?
        var fetchedResponse: URLResponse?
        
        if (self.authenticatedUser != nil || !self.requiresAuthentication()) {
            let semaphore = Semaphore(value: 0)
            let task = self.session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
                fetchedResponse = response
                if (data != nil) {
                    fetchedData = data
                } else {
                    self.error = error
                }
                semaphore.signal()
            })
            task.resume()
            semaphore.wait()
        } else {
            self.error = DIError(.authenticationError)
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
        let url = self.baseURL.appendingPathComponent("members/authenticate")
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        urlComponents.scheme = "https"
        
        let request = NSMutableURLRequest(url: urlComponents.url!)
        let httpBody = "username=\(self.username)&password=\(self.password)"
        request.httpBody = httpBody.data(using: .utf8)
        request.httpMethod = "POST"
        
        let (data, response) = self.fetchResponse(request as URLRequest)
        var successfulResponse = false
        if let httpResponse = response as? HTTPURLResponse {
            successfulResponse = (httpResponse.statusCode == 200)
        }
        
        if (data != nil && successfulResponse) {
            if let jsonDict = (try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions()) as? NSDictionary) {
                self.newAuthenticatedUser = AuthenticatedUser(jsonDict!)
            }
        } else {
            self.error = DIError(.invalidAuthCredentials)
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
        let batchUpdateURL = self.baseURL.appendingPathComponent("mobile/batch_update")
        var urlComponents = URLComponents(url: batchUpdateURL, resolvingAgainstBaseURL: false)!
        urlComponents.query = "stream_set_key=\(self.streamQuality.rawValue)"
        
        let request = NSMutableURLRequest(url: urlComponents.url!)
        request.addValue("Basic: \(AudioAddictServer._APIKey)", forHTTPHeaderField: "Authorization")
        
        let data = self.fetchResponse(request as URLRequest).0
        if (data != nil) {
            if let jsonDict = (try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions()) as? NSDictionary) {
                self.batchUpdate = BatchUpdate(jsonDict!)
            }
        }
    }
}

internal class LoadChannelArtworkOperation : ServerOperation
{
    var sizeHint:       CGSize = CGSize(width: 300.0, height: 300.0)
    var channelImage:   ChannelImage = ChannelImage()
    
    internal(set) var imageData: Data? = nil
    
    override func main()
    {
        let urlParams = ["width" : "\(Int(self.sizeHint.width))", "height" : "\(Int(self.sizeHint.height))"]
        if let artworkURL = self.channelImage.defaultURL.url(urlParams) {
            self.imageData = self.fetchData(artworkURL)
        }
    }
}
