//
//  AppDelegate.swift
//  di.fm
//
//  Created by Charles Magahern on 4/26/16.
//

import UIKit

@UIApplicationMain
class AppDelegate : UIResponder, UIApplicationDelegate, ChannelListViewControllerDelegate, PlayerDelegate
{
    var window:                 UIWindow?
    var tabBarController:       UITabBarController = UITabBarController()
    var nowPlayingController:   NowPlayingViewController = NowPlayingViewController()
    var server:                 AudioAddictServer = AudioAddictServer()
    var player:                 Player = Player()
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
    {
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window?.rootViewController = self.tabBarController
        self.window?.makeKeyAndVisible()
        
        self.player.delegate = self
        self.nowPlayingController.server = self.server
        
        _reloadData()
        
        return true
    }
    
    // MARK: ChannelListViewControllerDelegate
    
    func channelListDidSelectChannel(controller: ChannelListViewController, channel: Channel)
    {
        self.player.currentChannel = channel
        self.player.play()
        
        _reloadNowPlayingState()
        
        if let nowPlayingControllerIndex = self.tabBarController.viewControllers?.indexOf(self.nowPlayingController)! {
            self.tabBarController.selectedIndex = nowPlayingControllerIndex
        }
    }
    
    // MARK: PlayerDelegate
    
    func playerDidStartPlayingChannel(player: Player, channel: Channel)
    {
        _reloadNowPlayingState()
    }
    
    func playerDidPausePlayback(player: Player)
    {
        _reloadNowPlayingState()
    }
    
    func playerDidStopPlayback(player: Player)
    {
        _reloadNowPlayingState()
    }
    
    // MARK: Internal
    
    internal func _reloadData()
    {
        AudioAddictServer.sharedServer.fetchBatchUpdate(.Public1) { (update: BatchUpdate?, error: NSError?) -> (Void) in
            dispatch_async(dispatch_get_main_queue(), {
                self.tabBarController.viewControllers = nil
                
                if (update != nil) {
                    self._configureTabs(update!)
                    self._configurePlayer(update!)
                } else {
                    let alertMessage = "Cannot connect to server. \(error?.localizedDescription)"
                    let alert = UIAlertController(title: "Loading Failed", message: alertMessage, preferredStyle: .Alert)
                    self.tabBarController.presentViewController(alert, animated: true, completion: nil)
                }
            })
        }
    }
    
    internal func _reloadNowPlayingState()
    {
        self.nowPlayingController.currentChannel = self.player.currentChannel
        
        let tabIndexOfNowPlaying = self.tabBarController.viewControllers?.indexOf(self.nowPlayingController)
        if (self.nowPlayingController.currentChannel != nil) {
            // show now playing tab if not already visible
            if (tabIndexOfNowPlaying == nil) {
                self.tabBarController.viewControllers?.append(self.nowPlayingController)
            }
        } else {
            // hide now playing tab if not already hidden
            if (tabIndexOfNowPlaying != nil) {
                self.tabBarController.viewControllers?.removeAtIndex(tabIndexOfNowPlaying!)
            }
        }
    }
    
    internal func _configureTabs(batchUpdate: BatchUpdate)
    {
        var viewControllers: [UIViewController] = []
        let channelFilters = batchUpdate.channelFilters
        
        for channelFilter in channelFilters {
            if (!channelFilter.isStyleFilter() && !channelFilter.isHidden()) {
                let viewController = ChannelFilterViewController()
                viewController.channelListDelegate = self
                viewController.server = self.server
                viewController.channelFilter = channelFilter
                
                viewControllers.append(viewController)
            }
        }
        
        self.tabBarController.viewControllers = viewControllers
    }
    
    internal func _configurePlayer(batchUpdate: BatchUpdate)
    {
        var streamSet: StreamSet? = nil
        
        if (batchUpdate.streamSets.count > 0) {
            streamSet = batchUpdate.streamSets.first!
        }
        
        self.player.streamSet = streamSet
    }
}
