//
//  AppDelegate.swift
//  di.fm
//
//  Created by Charles Magahern on 4/26/16.
//

import UIKit

@UIApplicationMain
class AppDelegate : UIResponder, UIApplicationDelegate
{
    var window:             UIWindow?
    var tabBarController:   UITabBarController = UITabBarController()
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
    {
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window?.rootViewController = self.tabBarController
        self.window?.makeKeyAndVisible()
        
        _reloadData()
        
        return true
    }
    
    // MARK: Internal
    
    internal func _reloadData()
    {
        AudioAddictServer.sharedServer.fetchBatchUpdate(.Public1) { (update: BatchUpdate?, error: NSError?) -> (Void) in
            dispatch_async(dispatch_get_main_queue(), {
                self.tabBarController.viewControllers = nil
                
                if (update != nil) {
                    self._configureTabs(update!)
                } else {
                    let alertMessage = "Cannot connect to server. \(error?.localizedDescription)"
                    let alert = UIAlertController(title: "Loading Failed", message: alertMessage, preferredStyle: .Alert)
                    self.tabBarController.presentViewController(alert, animated: true, completion: nil)
                }
            })
        }
    }
    
    internal func _configureTabs(batchUpdate: BatchUpdate)
    {
        var viewControllers: [UIViewController] = []
        let channelFilters = batchUpdate.channelFilters
        
        for channelFilter in channelFilters {
            if (!channelFilter.isStyleFilter() && !channelFilter.isHidden()) {
                let viewController = ChannelFilterViewController()
                viewController.channelFilter = channelFilter
                viewControllers.append(viewController)
            }
        }
        
        self.tabBarController.viewControllers = viewControllers
    }
}
