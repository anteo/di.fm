//
//  Player.swift
//  di.fm
//
//  Created by Charles Magahern on 4/26/16.
//  Copyright © 2016 zanneth. All rights reserved.
//

import AVFoundation
import Foundation

protocol PlayerDelegate: class
{
    func playerDidStartPlayingChannel(_ player: Player, channel: Channel)
    func playerDidPausePlayback(_ player: Player)
    func playerDidStopPlayback(_ player: Player)
    func playerCurrentTrackDidChange(_ player: Player, newTrack: Track?)
}

protocol PlayerStreamProcessor: class
{
    func playerStreamDidDecodeAudioData(_ player: Player, data: Data, framesCount: UInt)
}

class Player : NSObject, ZANStreamPlayerDelegate
{
    var listenKey:                  String?
    var streamSet:                  StreamSet?
    weak var delegate:              PlayerDelegate?
    weak var streamProcessor:       PlayerStreamProcessor?
    
    fileprivate var _streamPlayer:  ZANStreamPlayer?
    fileprivate var _errorStream:   StandardErrorOutputStream = StandardErrorOutputStream()
    
    var currentChannel: Channel?
    {
        didSet
        {
            self.currentTrack = nil
            _reloadStream()
        }
    }
    
    fileprivate(set) var currentTrack: Track?
    {
        didSet
        {
            self.delegate?.playerCurrentTrackDidChange(self, newTrack: nil)
        }
    }
    
    func play()
    {
        #if (os(iOS) || os(tvOS))
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        }
        catch let error as NSError {
            _logError("error setting audio category", error: error)
        }
        #endif
        
        _streamPlayer?.play()
        
        if let currentChannel = self.currentChannel {
            self.delegate?.playerDidStartPlayingChannel(self, channel: currentChannel)
        }
    }
    
    func pause()
    {
        _streamPlayer?.pause()
    }
    
    func isPlaying() -> Bool
    {
        var playing: Bool = false
        if let streamPlayer = _streamPlayer {
            playing = streamPlayer.isPlaying
        }
        return playing
    }
    
    // MARK: ZANStreamPlayerDelegate
    
    func streamPlayerPlaybackStateDidChange(_ player: ZANStreamPlayer)
    {
        if (player.isStopped) {
            self.delegate?.playerDidStopPlayback(self)
        } else if (!player.isPlaying) {
            self.delegate?.playerDidPausePlayback(self)
        }
    }
    
    func streamPlayer(_ player: ZANStreamPlayer, didReceiveMetadataUpdate metadata: [String : String])
    {
        self.currentTrack = Track(metadata)
    }
    
    func streamPlayer(_ player: ZANStreamPlayer, didDecodeAudioData data: Data, withFramesCount framesCount: UInt, format: UnsafePointer<AudioStreamBasicDescription>)
    {
        self.streamProcessor?.playerStreamDidDecodeAudioData(self, data: data, framesCount: framesCount)
    }
    
    // MARK: Internal
    
    internal func _cachedChannelStream(_ channel: Channel) -> Stream?
    {
        var stream: Stream? = nil
        
        if (self.streamSet != nil) {
            let streamlist = self.streamSet?.streamlist
            let streams = streamlist?.channelIDToStreams[channel.identifier]
            stream = streams?.first
        } else {
            _logError("No stream set initialized on player.", error: nil)
        }
        
        return stream
    }
    
    internal func _reloadStream()
    {
        var newStreamPlayer: ZANStreamPlayer? = nil
        
        // create player item and player for new channel stream
        if (self.currentChannel != nil) {
            if let stream = _cachedChannelStream(self.currentChannel!), let streamURL = stream.url {
                var streamURLComponents = URLComponents(url: streamURL, resolvingAgainstBaseURL: false)!
                if (self.listenKey != nil) {
                    streamURLComponents.query = "?\(self.listenKey!)"
                }
                
                if let streamURL = streamURLComponents.url {
                    newStreamPlayer = ZANStreamPlayer(url: streamURL, options: [.installProcessingTap, .requestMetadata])
                    newStreamPlayer?.delegate = self
                } else {
                    _logError("Could not parse URL using components: \(streamURLComponents)", error: nil)
                }
            } else {
                _logError("No stream found for channel \(self.currentChannel!.name)", error: nil)
            }
        } else {
            self.delegate?.playerDidStopPlayback(self)
        }
        
        // reset playback state
        let prevPlaying = self.isPlaying()
        self.pause()
        
        // save new stream player
        _streamPlayer = newStreamPlayer
        
        // begin playback if necessary
        if (prevPlaying) {
            self.play()
        }
    }
    
    internal func _logError(_ description: String, error: NSError?)
    {
        #if DEBUG
        let errDescription = error?.localizedDescription ?? "nil"
        _errorStream.write("ERROR: \(description) \(errDescription)\n")
        #endif
    }
}
