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
    var server:                 AudioAddictServer = AudioAddictServer()
    var player:                 Player = Player()
    var tabBarController:       UITabBarController = UITabBarController()
    var credentialsStore:       CredentialsStore = CredentialsStore()
    var nowPlayingController:   NowPlayingViewController = NowPlayingViewController()
    var remoteController:       RemoteController!
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
    {
        application.idleTimerDisabled = true
        
        var initialRootViewController: UIViewController? = nil
        if (self.credentialsStore.hasCredentials()) {
            initialRootViewController = LoadingViewController()
            
            let username = self.credentialsStore.username ?? ""
            let password = self.credentialsStore.password ?? ""
            self.server.authenticate(username, password: password, completion: { (user: AuthenticatedUser?, err: NSError?) -> (Void) in
                if (user != nil) {
                    self._handleSuccessfulAuthentication(user!)
                } else {
                    // show login screen
                    let loginViewController = LoginViewController()
                    loginViewController.delegate = self
                    
                    self.window?.rootViewController = loginViewController
                }
            })
        } else {
            let loginViewController = LoginViewController()
            loginViewController.delegate = self
            initialRootViewController = loginViewController
        }
        
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window?.backgroundColor = Theme.defaultTheme().backgroundColor
        self.window?.rootViewController = initialRootViewController
        self.window?.makeKeyAndVisible()
        
        let playPauseButtonRecognizer = UITapGestureRecognizer(target: self, action: #selector(_playPauseButtonPressed))
        playPauseButtonRecognizer.allowedPressTypes = [NSNumber(integer: UIPressType.PlayPause.rawValue)];
        self.window?.addGestureRecognizer(playPauseButtonRecognizer)
        
        self.player.delegate = self
        self.player.streamProcessor = self.nowPlayingController.visualizationViewController
        self.nowPlayingController.server = self.server
        self.remoteController = RemoteController(player: self.player)
        self.remoteController.player = self.player
        
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
    
    func playerCurrentTrackDidChange(player: Player, newTrack: Track?)
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
            
            if (authenticatedUser != nil) {
                dispatch_async(dispatch_get_main_queue(), {
                    self.credentialsStore.username = email
                    self.credentialsStore.password = password
                    self._handleSuccessfulAuthentication(authenticatedUser!)
                })
            }
        }
    }
    
    // MARK: Internal
    
    internal func _handleSuccessfulAuthentication(authenticatedUser: AuthenticatedUser)
    {
        self.player.listenKey = authenticatedUser.listenKey
        self.window?.rootViewController = LoadingViewController()
        _reloadData()
    }
    
    internal func _reloadData()
    {
        // TODO: read stream quality from user settings
        self.server.fetchBatchUpdate(.PremiumHigh) { (update: BatchUpdate?, error: NSError?) -> (Void) in
            dispatch_async(dispatch_get_main_queue(), {
                self.tabBarController.viewControllers = nil
                
                if let update = update {
                    self._configureTabs(update)
                    self._configurePlayer(update)
                    self.window?.rootViewController = self.tabBarController
                } else {
                    let errorDescription = error?.localizedDescription ?? NSLocalizedString("UNKNOWN_ERROR", comment: "")
                    let alertMessage = NSString(format: NSLocalizedString("CONNECTION_ERROR_FORMAT_%@", comment: ""), errorDescription) as String
                    let alertTitle = NSLocalizedString("LOADING_FAILED_MESSAGE_TITLE", comment: "")
                    let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .Default, handler: { (action: UIAlertAction) in
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
        self.nowPlayingController.currentTrack = self.player.currentTrack
        
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
                let channelFilterViewController = ChannelFilterViewController()
                channelFilterViewController.channelListViewController.delegate = self
                channelFilterViewController.server = self.server
                channelFilterViewController.channelFilter = channelFilter
                
                viewControllers.append(channelFilterViewController)
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
    
    internal func _playPauseButtonPressed(sender: UITapGestureRecognizer)
    {
        if (self.player.isPlaying()) {
            self.player.pause()
        }
        else {
            self.player.play()
        }
    }
}
