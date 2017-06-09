//
//  ChannelArtworkImageDataSource.swift
//  di.fm
//
//  Created by Charles Magahern on 5/8/16.
//  Copyright © 2016 zanneth. All rights reserved.
//

import Foundation
import UIKit

class ChannelArtworkImageDataSource
{
    typealias ChannelArtworkCallback = (UIImage?, Error?) -> (Void)
    
    var server: AudioAddictServer?
    
    fileprivate var _cache:                      [Int : UIImage] = [:] // channel identifiers -> images
    fileprivate var _pendingCallbacks:           [Int : [ChannelArtworkCallback]] = [:] // channel identifiers -> callbacks
    fileprivate var _serialQueue:                DispatchQueue
    
    init()
    {
        _serialQueue = DispatchQueue(label: "ChannelArtworkImageDataSource", attributes: [])
    }
    
    func loadChannelArtworkImage(_ channel: Channel, size: CGSize, completion: @escaping ChannelArtworkCallback)
    {
        _serialQueue.async {
            if let cachedImage = self._cache[channel.identifier] {
                completion(cachedImage, nil)
            } else if (self._pendingCallbacks[channel.identifier] != nil) {
                self._pendingCallbacks[channel.identifier]!.append(completion)
            } else {
                self._onQueueBeginLoad(channel, size: size, completion: completion)
            }
        }
    }
    
    // MARK: Internal
    
    internal func _onQueueBeginLoad(_ channel: Channel, size: CGSize, completion: @escaping ChannelArtworkCallback)
    {
        guard let server = self.server else {
            var err = DIError(code: .configurationError)
            err.debugDescription = "no server configured for artwork data source"
            completion(nil, err)
            return
        }
        
        _pendingCallbacks[channel.identifier] = [completion]
        
        server.loadChannelArtwork(channel.image, size: size) { (imageData: Data?, error: Error?) -> (Void) in
            self._serialQueue.async(execute: {
                var loadedImage: UIImage? = nil
                
                if (imageData != nil) {
                    loadedImage = UIImage(data: imageData!)
                    self._cache[channel.identifier] = loadedImage
                }
                
                for callback in self._pendingCallbacks[channel.identifier]! {
                    callback(loadedImage, error)
                }
                
                self._pendingCallbacks.removeValue(forKey: channel.identifier)
            })
        }
    }
}
