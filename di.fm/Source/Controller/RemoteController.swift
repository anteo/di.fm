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
        
        let commandCenter = MPRemoteCommandCenter.sharedCommandCenter()
        commandCenter.playCommand.addTargetWithHandler(self._playCommandReceived)
        commandCenter.pauseCommand.addTargetWithHandler(self._pauseCommandReceived)
        commandCenter.togglePlayPauseCommand.addTargetWithHandler(self._togglePlayPauseCommandReceived)
    }
    
    // MARK: Command Handlers
    
    internal func _playCommandReceived(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus
    {
        self.player.play()
        return .Success
    }
    
    internal func _pauseCommandReceived(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus
    {
        self.player.pause()
        return .Success
    }
    
    internal func _togglePlayPauseCommandReceived(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus
    {
        if (self.player.isPlaying()) {
            self.player.pause()
        }
        else {
            self.player.play()
        }
        
        return .Success
    }
}
