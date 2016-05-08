//
//  Player.swift
//  di.fm
//
//  Created by Charles Magahern on 4/26/16.
//

import Foundation
import AVFoundation

class Player
{
    var listenKey:          String?
    private var _avPlayer:  AVPlayer?
    
    /*
    var currentStation: Station?
    {
        didSet
        {
            var newAVPlayer: AVPlayer? = nil
            
            if (self.currentStation != nil) {
                var stationURL = self.currentStation!.playlistURL
                if (self.listenKey != nil) {
                    var stationURLString = stationURL.absoluteString
                    stationURLString += "?\(self.listenKey!)"
                    stationURL = NSURL(string: stationURLString)!
                }
                
                newAVPlayer = AVPlayer(URL: stationURL)
            }
            
            if (_avPlayer != nil) {
                _avPlayer?.pause()
            }
            _avPlayer = newAVPlayer
        }
    }
 */
    
    func play()
    {
        _avPlayer?.play()
    }
    
    func pause()
    {
        _avPlayer?.pause()
    }
}
