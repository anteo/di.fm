//
//  AppDelegate.swift
//  di.fm
//
//  Created by Charles Magahern on 4/26/16.
//

import UIKit

@UIApplicationMain
class AppDelegate : UIResponder,
    UIApplicationDelegate,
    ChannelListViewControllerDelegate,
    PlayerDelegate,
    LoginViewControllerDelegate
{
    var window:                 UIWindow?
    var tabBarController:       UITabBarController = UITabBarController()
    var nowPlayingController:   NowPlayingViewController = NowPlayingViewController()
    var server:                 AudioAddictServer = AudioAddictServer()
    var player:                 Player = Player()
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
    {
        let loginViewController = LoginViewController()
        loginViewController.delegate = self
        
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window?.rootViewController = loginViewController
        self.window?.makeKeyAndVisible()
        
        self.player.delegate = self
        self.nowPlayingController.server = self.server
        
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
    
    // MARK: LoginViewControllerDelegate
    
    func loginViewControllerDidSubmitCredentials(controller: LoginViewController,
                                                 email: String,
                                                 password: String,
                                                 completion: (NSError?) -> (Void))
    {
        self.server.authenticate(email, password: password) { (authenticatedUser: AuthenticatedUser?, error: NSError?) -> (Void) in
            completion(error)
            
            dispatch_async(dispatch_get_main_queue()) {
                if (authenticatedUser != nil) {
                    self.player.listenKey = authenticatedUser?.listenKey
                    self.window?.rootViewController = self.tabBarController
                    self._reloadData()
                }
            }
        }
    }
    
    // MARK: Internal
    
    internal func _reloadData()
    {
        // TODO: read stream quality from user settings
        self.server.fetchBatchUpdate(.PremiumHigh) { (update: BatchUpdate?, error: NSError?) -> (Void) in
            dispatch_async(dispatch_get_main_queue(), {
                self.tabBarController.viewControllers = nil
                
                if (update != nil) {
                    self._configureTabs(update!)
                    self._configurePlayer(update!)
                } else {
                    let errorDescription = error?.localizedDescription ?? NSLocalizedString("UNKNOWN_ERROR", comment: "")
                    let alertMessage = "Cannot connect to server. \(errorDescription)"
                    let alert = UIAlertController(title: "Loading Failed", message: alertMessage, preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (action: UIAlertAction) in
                        self.tabBarController.dismissViewControllerAnimated(true, completion: nil)
                    }))
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
