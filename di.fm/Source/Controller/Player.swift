//
//  Player.swift
//  di.fm
//
//  Created by Charles Magahern on 4/26/16.
//

import AVFoundation
import Foundation

protocol PlayerDelegate: class
{
    func playerDidStartPlayingChannel(player: Player, channel: Channel)
    func playerDidPausePlayback(player: Player)
    func playerDidStopPlayback(player: Player)
    func playerCurrentTrackDidChange(player: Player, newTrack: Track?)
}

protocol PlayerStreamProcessor: class
{
    func playerStreamDidDecodeAudioData(player: Player, data: NSData, framesCount: UInt)
}

class Player : NSObject, ZANStreamPlayerDelegate
{
    var listenKey:                  String?
    var streamSet:                  StreamSet?
    weak var delegate:              PlayerDelegate?
    weak var streamProcessor:       PlayerStreamProcessor?
    
    private var _streamPlayer:      ZANStreamPlayer?
    private var _errorStream:       StandardErrorOutputStream = StandardErrorOutputStream()
    
    var currentChannel: Channel?
    {
        didSet
        {
            self.currentTrack = nil
            _reloadStream()
        }
    }
    
    private(set) var currentTrack: Track?
    {
        didSet
        {
            self.delegate?.playerCurrentTrackDidChange(self, newTrack: nil)
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
        
        _streamPlayer?.play()
        
        if (self.currentChannel != nil) {
            self.delegate?.playerDidStartPlayingChannel(self, channel: self.currentChannel!)
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
            playing = streamPlayer.playing
        }
        return playing
    }
    
    // MARK: ZANStreamPlayerDelegate
    
    func streamPlayerPlaybackStateDidChange(player: ZANStreamPlayer)
    {
        if (player.stopped) {
            self.delegate?.playerDidStopPlayback(self)
        } else if (!player.playing) {
            self.delegate?.playerDidPausePlayback(self)
        }
    }
    
    func streamPlayer(player: ZANStreamPlayer, didReceiveMetadataUpdate metadata: [String : String])
    {
        self.currentTrack = Track(metadata)
    }
    
    func streamPlayer(player: ZANStreamPlayer, didDecodeAudioData data: NSData, withFramesCount framesCount: UInt, format: UnsafePointer<AudioStreamBasicDescription>)
    {
        self.streamProcessor?.playerStreamDidDecodeAudioData(self, data: data, framesCount: framesCount)
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
        var newStreamPlayer: ZANStreamPlayer? = nil
        
        // create player item and player for new channel stream
        if (self.currentChannel != nil) {
            if let stream = _cachedChannelStream(self.currentChannel!) {
                let streamURLComponents = NSURLComponents(URL: stream.url, resolvingAgainstBaseURL: false)!
                if (self.listenKey != nil) {
                    streamURLComponents.query = "?\(self.listenKey!)"
                }
                
                if let streamURL = streamURLComponents.URL {
                    newStreamPlayer = ZANStreamPlayer(URL: streamURL, options: [.InstallProcessingTap, .RequestMetadata])
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
    
    internal func _logError(description: String, error: NSError?)
    {
        print("ERROR: \(description) \(error)", toStream: &_errorStream)
    }
}
