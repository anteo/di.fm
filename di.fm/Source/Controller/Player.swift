//
//  Player.swift
//  di.fm
//
//  Created by Charles Magahern on 4/26/16.
//

import Foundation
import AVFoundation

protocol PlayerDelegate: class
{
    func playerDidStartPlayingChannel(player: Player, channel: Channel)
    func playerDidPausePlayback(player: Player)
    func playerDidStopPlayback(player: Player)
}

class Player
{
    var listenKey:              String?
    var streamSet:              StreamSet?
    weak var delegate:          PlayerDelegate?
    
    private var _avPlayer:      AVPlayer?
    private var _errorStream:   StandardErrorOutputStream = StandardErrorOutputStream()
    
    var currentChannel: Channel?
    {
        didSet
        {
            _reloadStream()
        }
    }
    
    func play()
    {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        }
        catch let error as NSError {
            _logError("error setting audio category", error: error)
        }
        
        _avPlayer?.play()
        
        if (self.currentChannel != nil) {
            self.delegate?.playerDidStartPlayingChannel(self, channel: self.currentChannel!)
        }
    }
    
    func pause()
    {
        if (_avPlayer?.rate > 0.0) {
            _avPlayer?.pause()
            self.delegate?.playerDidPausePlayback(self)
        }
    }
    
    func isPlaying() -> Bool
    {
        return (_avPlayer?.rate > 0.0)
    }
    
    // MARK: Internal
    
    internal func _cachedChannelStream(channel: Channel) -> Stream?
    {
        var stream: Stream? = nil
        
        if (self.streamSet != nil) {
            let streamlist = self.streamSet?.streamlist
            let streams = streamlist?.channelIDToStreams[channel.identifier]
            if (streams?.count > 0) {
                stream = streams?.first
            }
        } else {
            _logError("No stream set initialized on player.", error: nil)
        }
        
        return stream
    }
    
    internal func _reloadStream()
    {
        var newAVPlayer: AVPlayer? = nil
        
        if (self.currentChannel != nil) {
            if let stream = _cachedChannelStream(self.currentChannel!) {
                let streamURLComponents = NSURLComponents(URL: stream.url, resolvingAgainstBaseURL: false)!
                if (self.listenKey != nil) {
                    streamURLComponents.query = "?\(self.listenKey!)"
                }
                
                newAVPlayer = AVPlayer(URL: streamURLComponents.URL!)
            } else {
                _logError("No stream found for channel \(self.currentChannel!.name)", error: nil)
            }
        } else {
            self.delegate?.playerDidStopPlayback(self)
        }
        
        let prevPlaying = self.isPlaying()
        self.pause()
        
        _avPlayer = newAVPlayer
        
        if (prevPlaying) {
            self.play()
        }
    }
    
    internal func _logError(description: String, error: NSError?)
    {
        print("ERROR: \(description) \(error)", toStream: &_errorStream)
    }
}
