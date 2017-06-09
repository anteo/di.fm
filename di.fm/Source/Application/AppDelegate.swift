//
//  AppDelegate.swift
//  di.fm
//
//  Created by Charles Magahern on 4/26/16.
//  Copyright © 2016 zanneth. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate : UIResponder,
    UIApplicationDelegate,
    ChannelListViewControllerDelegate,
    PlayerDelegate,
    LoginViewControllerDelegate,
    SettingsViewControllerDelegate
{
    var window:                 UIWindow?
    var server:                 AudioAddictServer = AudioAddictServer()
    var player:                 Player = Player()
    var tabBarController:       UITabBarController = UITabBarController()
    var credentialsStore:       CredentialsStore = CredentialsStore()
    var nowPlayingController:   NowPlayingViewController = NowPlayingViewController()
    var remoteController:       RemoteController!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        application.isIdleTimerDisabled = true
        
        var initialRootViewController: UIViewController? = nil
        if (self.credentialsStore.hasCredentials()) {
            initialRootViewController = LoadingViewController()
            
            let username = self.credentialsStore.username ?? ""
            let password = self.credentialsStore.password ?? ""
            self.server.authenticate(username, password: password, completion: { (user: AuthenticatedUser?, err: Error?) -> (Void) in
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
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.backgroundColor = Theme.defaultTheme().backgroundColor
        self.window?.rootViewController = initialRootViewController
        self.window?.makeKeyAndVisible()
        
        let playPauseButtonRecognizer = UITapGestureRecognizer(target: self, action: #selector(_playPauseButtonPressed))
        playPauseButtonRecognizer.allowedPressTypes = [NSNumber(value: UIPressType.playPause.rawValue as Int)];
        self.window?.addGestureRecognizer(playPauseButtonRecognizer)
        
        self.player.delegate = self
        self.player.streamProcessor = self.nowPlayingController.visualizationViewController
        self.nowPlayingController.server = self.server
        self.remoteController = RemoteController(player: self.player)
        self.remoteController.player = self.player
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(forName: NSNotification.Name(rawValue: Settings.settingsDidChangeNotification), object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?._reloadData()
        }
        
        return true
    }
    
    // MARK: ChannelListViewControllerDelegate
    
    func channelListDidSelectChannel(_ controller: ChannelListViewController, channel: Channel)
    {
        self.player.currentChannel = channel
        self.player.play()
        
        _reloadNowPlayingState()
        
        if let nowPlayingControllerIndex = self.tabBarController.viewControllers?.index(of: self.nowPlayingController)! {
            self.tabBarController.selectedIndex = nowPlayingControllerIndex
        }
    }
    
    // MARK: PlayerDelegate
    
    func playerDidStartPlayingChannel(_ player: Player, channel: Channel)
    {
        _reloadNowPlayingState()
    }
    
    func playerDidPausePlayback(_ player: Player)
    {
        _reloadNowPlayingState()
    }
    
    func playerDidStopPlayback(_ player: Player)
    {
        _reloadNowPlayingState()
    }
    
    func playerCurrentTrackDidChange(_ player: Player, newTrack: Track?)
    {
        _reloadNowPlayingState()
    }
    
    // MARK: LoginViewControllerDelegate
    
    func loginViewControllerDidSubmitCredentials(_ controller: LoginViewController,
                                                 email: String,
                                                 password: String,
                                                 completion: @escaping (Error?) -> (Void))
    {
        self.server.authenticate(email, password: password) { (authenticatedUser: AuthenticatedUser?, error: Error?) -> (Void) in
            completion(error)
            
            if (authenticatedUser != nil) {
                DispatchQueue.main.async(execute: {
                    self.credentialsStore.username = email
                    self.credentialsStore.password = password
                    self._handleSuccessfulAuthentication(authenticatedUser!)
                })
            }
        }
    }
    
    // MARK: SettingsViewControllerDelegate
    
    func settingsViewControllerDidConfirmLogout(_ viewController: SettingsViewController)
    {
        self.credentialsStore.reset()
        self.player.pause()
        
        let loginViewController = LoginViewController()
        loginViewController.delegate = self
        self.window?.rootViewController = loginViewController
    }
    
    // MARK: Internal
    
    internal func _handleSuccessfulAuthentication(_ authenticatedUser: AuthenticatedUser)
    {
        self.player.listenKey = authenticatedUser.listenKey
        self.window?.rootViewController = LoadingViewController()
        _reloadData()
    }
    
    internal func _reloadData()
    {
        let settings = Settings.sharedSettings
        self.server.fetchBatchUpdate(settings.streamQuality) { (update: BatchUpdate?, error: Error?) -> (Void) in
            DispatchQueue.main.async(execute: {
                self.tabBarController.viewControllers = nil
                
                if let update = update {
                    self._configureTabs(update)
                    self._configurePlayer(update)
                    self.window?.rootViewController = self.tabBarController
                } else {
                    let errorDescription = error?.localizedDescription ?? NSLocalizedString("UNKNOWN_ERROR", comment: "")
                    let alertMessage = NSString(format: NSLocalizedString("CONNECTION_ERROR_FORMAT_%@", comment: "") as NSString, errorDescription) as String
                    let alertTitle = NSLocalizedString("LOADING_FAILED_MESSAGE_TITLE", comment: "")
                    let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { (action: UIAlertAction) in
                        self.tabBarController.dismiss(animated: true, completion: nil)
                    }))
                    self.tabBarController.present(alert, animated: true, completion: nil)
                }
            })
        }
    }
    
    internal func _reloadNowPlayingState()
    {
        self.nowPlayingController.currentChannel = self.player.currentChannel
        self.nowPlayingController.currentTrack = self.player.currentTrack
        
        let tabIndexOfNowPlaying = self.tabBarController.viewControllers?.index(of: self.nowPlayingController)
        if (self.nowPlayingController.currentChannel != nil) {
            // show now playing tab if not already visible
            if (tabIndexOfNowPlaying == nil) {
                self.tabBarController.viewControllers?.append(self.nowPlayingController)
            }
        } else {
            // hide now playing tab if not already hidden
            if (tabIndexOfNowPlaying != nil) {
                self.tabBarController.viewControllers?.remove(at: tabIndexOfNowPlaying!)
            }
        }
    }
    
    internal func _configureTabs(_ batchUpdate: BatchUpdate)
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
        
        let settingsViewController = SettingsViewController()
        settingsViewController.delegate = self
        viewControllers.append(settingsViewController)
        
        self.tabBarController.viewControllers = viewControllers
    }
    
    internal func _configurePlayer(_ batchUpdate: BatchUpdate)
    {
        var streamSet: StreamSet? = nil
        
        if (batchUpdate.streamSets.count > 0) {
            streamSet = batchUpdate.streamSets.first!
        }
        
        self.player.streamSet = streamSet
    }
    
    internal func _playPauseButtonPressed(_ sender: UITapGestureRecognizer)
    {
        if (self.player.isPlaying()) {
            self.player.pause()
        }
        else {
            self.player.play()
        }
    }
}
