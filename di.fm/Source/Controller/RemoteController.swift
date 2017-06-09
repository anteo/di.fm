//
//  RemoteController.swift
//  di.fm
//
//  Created by Charles Magahern on 5/12/16.
//  Copyright © 2016 zanneth. All rights reserved.
//

import Foundation
import MediaPlayer

class RemoteController
{
    var player: Player
    
    init(player: Player)
    {
        self.player = player
        
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.addTarget(handler: self._playCommandReceived)
        commandCenter.pauseCommand.addTarget(handler: self._pauseCommandReceived)
        commandCenter.togglePlayPauseCommand.addTarget(handler: self._togglePlayPauseCommandReceived)
    }
    
    // MARK: Command Handlers
    
    internal func _playCommandReceived(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus
    {
        self.player.play()
        return .success
    }
    
    internal func _pauseCommandReceived(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus
    {
        self.player.pause()
        return .success
    }
    
    internal func _togglePlayPauseCommandReceived(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus
    {
        if (self.player.isPlaying()) {
            self.player.pause()
        }
        else {
            self.player.play()
        }
        
        return .success
    }
}
