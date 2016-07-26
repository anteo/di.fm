//
//  SettingsViewController.swift
//  di.fm
//
//  Created by Charles Magahern on 7/24/16.
//  Copyright © 2016 zanneth. All rights reserved.
//

import Foundation
import UIKit

protocol SettingsViewControllerDelegate : class
{
    func settingsViewControllerDidConfirmLogout(viewController: SettingsViewController)
}

internal struct Setting
{
    var title: String = ""
    var action: () -> () = {}
}

class SettingsViewController : UIViewController, UITableViewDelegate, UITableViewDataSource
{
    weak var delegate:                        SettingsViewControllerDelegate?
    
    private var _splitViewController:         UISplitViewController = UISplitViewController()
    private var _navigationController:        UINavigationController!
    private var _settingsTableViewController: UITableViewController = UITableViewController()
    private var _logoViewController:          UIViewController = UIViewController()
    private var _settings:                    [Setting] = []
    
    static private let _SettingCellIdentifier = "SettingsCellIdentifier"
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?)
    {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.title = NSLocalizedString("SETTINGS_TITLE", comment: "")
        
        _settings = [
            Setting(title: NSLocalizedString("SETTING_QUALITY", comment: ""), action: _streamQualityAction),
            Setting(title: NSLocalizedString("SETTING_LOGOUT", comment: ""), action: _logoutAction),
        ]
        
        let theme = Theme.defaultTheme()
        let tableView = _settingsTableViewController.tableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: SettingsViewController._SettingCellIdentifier)
        _settingsTableViewController.title = self.title
        
        let logoView = _logoViewController.view
        let logoImage = UIImage(named: "di_logo")
        let logoImageView = UIImageView(image: logoImage)
        logoImageView.contentMode = .Center
        logoView.addSubview(logoImageView)
        
        _navigationController = UINavigationController(rootViewController: _settingsTableViewController)
        _navigationController.view.backgroundColor = theme.tertiaryColor
        _splitViewController.viewControllers = [_navigationController, _logoViewController]
        
        self.addChildViewController(_splitViewController)
        self.view.addSubview(_splitViewController.view)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("unsupported")
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        _splitViewController.view.frame = self.view.bounds
        
        let logoView = _logoViewController.view
        let logoViewBounds = logoView.bounds
        let logoImageView = logoView.subviews.first
        logoImageView?.frame = logoViewBounds
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return _settings.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier(SettingsViewController._SettingCellIdentifier, forIndexPath: indexPath)
        let setting = _settings[indexPath.row]
        cell.textLabel?.text = setting.title
        cell.textLabel?.textColor = UIColor.whiteColor()
        cell.selectionStyle = .None
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let setting = _settings[indexPath.row]
        setting.action()
    }
    
    func tableView(tableView: UITableView, didUpdateFocusInContext context: UITableViewFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator)
    {
        if let prevIndexPath = context.previouslyFocusedIndexPath {
            let prevCell = tableView.cellForRowAtIndexPath(prevIndexPath)
            prevCell?.textLabel?.textColor = UIColor.whiteColor()
        }
        
        if let nextIndexPath = context.nextFocusedIndexPath {
            let nextCell = tableView.cellForRowAtIndexPath(nextIndexPath)
            nextCell?.textLabel?.textColor = UIColor.blackColor()
        }
    }
    
    // MARK: Internal
    
    internal func _streamQualityAction()
    {
        let streamQualitySelectionVC = StreamQualitySelectionViewController(nibName: nil, bundle: nil)
        _navigationController.pushViewController(streamQualitySelectionVC, animated: true)
    }
    
    internal func _logoutAction()
    {
        let alertTitle = NSLocalizedString("LOGOUT_TITLE", comment: "")
        let alertMessage = NSLocalizedString("LOGOUT_DIALOG_MESSAGE", comment: "")
        let alertConfirmTitle = NSLocalizedString("LOGOUT_DIALOG_CONFIRM_ACTION", comment: "")
        let cancelTitle = NSLocalizedString("CANCEL", comment: "")
        
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .ActionSheet)
        alert.addAction(UIAlertAction(title: alertConfirmTitle, style: .Destructive, handler: { (_: UIAlertAction) in
            self.delegate?.settingsViewControllerDidConfirmLogout(self)
        }))
        alert.addAction(UIAlertAction(title: cancelTitle, style: .Cancel, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
}

internal class StreamQualitySelectionViewController : UITableViewController
{
    static private let _CellReuseIdentifier = "StreamQualityCellReuseIdentifier"
    static private let _AvailableQualitySettings = [
        ("STREAM_QUALITY_LOW", Stream.Quality.PremiumLow),
        ("STREAM_QUALITY_MEDIUM", Stream.Quality.PremiumMedium),
        ("STREAM_QUALITY_HIGH", Stream.Quality.PremiumHigh)
    ]
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?)
    {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.title = NSLocalizedString("SETTING_QUALITY", comment: "")
        
        let tableView = self.tableView
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: StreamQualitySelectionViewController._CellReuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("unsupported")
    }
    
    // MARK: UITableViewDataSource
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return StreamQualitySelectionViewController._AvailableQualitySettings.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier(StreamQualitySelectionViewController._CellReuseIdentifier,
                                                               forIndexPath: indexPath)
        let qualitySetting = StreamQualitySelectionViewController._AvailableQualitySettings[indexPath.row]
        cell.textLabel?.text = NSLocalizedString(qualitySetting.0, comment: "")
        cell.textLabel?.textColor = UIColor.whiteColor()
        cell.selectionStyle = .None
        
        if (qualitySetting.1 == Settings.sharedSettings.streamQuality) {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let selectedQualitySetting = StreamQualitySelectionViewController._AvailableQualitySettings[indexPath.row]
        let settings = Settings.sharedSettings
        settings.streamQuality = selectedQualitySetting.1
        self.tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView,
                            didUpdateFocusInContext context: UITableViewFocusUpdateContext,
                            withAnimationCoordinator coordinator: UIFocusAnimationCoordinator)
    {
        if let prevIndexPath = context.previouslyFocusedIndexPath {
            let prevCell = tableView.cellForRowAtIndexPath(prevIndexPath)
            prevCell?.textLabel?.textColor = UIColor.whiteColor()
        }
        
        if let nextIndexPath = context.nextFocusedIndexPath {
            let nextCell = tableView.cellForRowAtIndexPath(nextIndexPath)
            nextCell?.textLabel?.textColor = UIColor.blackColor()
        }
    }
}
