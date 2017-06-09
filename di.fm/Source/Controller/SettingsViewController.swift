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
    func settingsViewControllerDidConfirmLogout(_ viewController: SettingsViewController)
}

internal struct Setting
{
    var title: String = ""
    var action: () -> () = {}
}

class SettingsViewController : UIViewController, UITableViewDelegate, UITableViewDataSource
{
    weak var delegate:                        SettingsViewControllerDelegate?
    
    fileprivate var _splitViewController:         UISplitViewController = UISplitViewController()
    fileprivate var _navigationController:        UINavigationController!
    fileprivate var _settingsTableViewController: UITableViewController = UITableViewController()
    fileprivate var _logoViewController:          UIViewController = UIViewController()
    fileprivate var _settings:                    [Setting] = []
    
    static fileprivate let _SettingCellIdentifier = "SettingsCellIdentifier"
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
    {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.title = NSLocalizedString("SETTINGS_TITLE", comment: "")
        
        _settings = [
            Setting(title: NSLocalizedString("SETTING_QUALITY", comment: ""), action: _streamQualityAction),
            Setting(title: NSLocalizedString("SETTING_LOGOUT", comment: ""), action: _logoutAction),
        ]
        
        let theme = Theme.defaultTheme()
        let tableView = _settingsTableViewController.tableView
        tableView?.delegate = self
        tableView?.dataSource = self
        tableView?.register(UITableViewCell.self, forCellReuseIdentifier: SettingsViewController._SettingCellIdentifier)
        _settingsTableViewController.title = self.title
        
        let logoView = _logoViewController.view
        let logoImage = UIImage(named: "di_logo")
        let logoImageView = UIImageView(image: logoImage)
        logoImageView.contentMode = .center
        logoView?.addSubview(logoImageView)
        
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
        let logoViewBounds = logoView?.bounds
        let logoImageView = logoView?.subviews.first
        logoImageView?.frame = logoViewBounds!
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return _settings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsViewController._SettingCellIdentifier, for: indexPath)
        let setting = _settings[indexPath.row]
        cell.textLabel?.text = setting.title
        cell.textLabel?.textColor = UIColor.white
        cell.selectionStyle = .none
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let setting = _settings[indexPath.row]
        setting.action()
    }
    
    func tableView(_ tableView: UITableView, didUpdateFocusIn context: UITableViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator)
    {
        if let prevIndexPath = context.previouslyFocusedIndexPath {
            let prevCell = tableView.cellForRow(at: prevIndexPath)
            prevCell?.textLabel?.textColor = UIColor.white
        }
        
        if let nextIndexPath = context.nextFocusedIndexPath {
            let nextCell = tableView.cellForRow(at: nextIndexPath)
            nextCell?.textLabel?.textColor = UIColor.black
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
        
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: alertConfirmTitle, style: .destructive, handler: { (_: UIAlertAction) in
            self.delegate?.settingsViewControllerDidConfirmLogout(self)
        }))
        alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
}

internal class StreamQualitySelectionViewController : UITableViewController
{
    static fileprivate let _CellReuseIdentifier = "StreamQualityCellReuseIdentifier"
    static fileprivate let _AvailableQualitySettings = [
        ("STREAM_QUALITY_LOW", Stream.Quality.PremiumLow),
        ("STREAM_QUALITY_MEDIUM", Stream.Quality.PremiumMedium),
        ("STREAM_QUALITY_HIGH", Stream.Quality.PremiumHigh)
    ]
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
    {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.title = NSLocalizedString("SETTING_QUALITY", comment: "")
        
        let tableView = self.tableView
        tableView?.register(UITableViewCell.self, forCellReuseIdentifier: StreamQualitySelectionViewController._CellReuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("unsupported")
    }
    
    // MARK: UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return StreamQualitySelectionViewController._AvailableQualitySettings.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: StreamQualitySelectionViewController._CellReuseIdentifier,
                                                               for: indexPath)
        let qualitySetting = StreamQualitySelectionViewController._AvailableQualitySettings[indexPath.row]
        cell.textLabel?.text = NSLocalizedString(qualitySetting.0, comment: "")
        cell.textLabel?.textColor = UIColor.white
        cell.selectionStyle = .none
        
        if (qualitySetting.1 == Settings.sharedSettings.streamQuality) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let selectedQualitySetting = StreamQualitySelectionViewController._AvailableQualitySettings[indexPath.row]
        let settings = Settings.sharedSettings
        settings.streamQuality = selectedQualitySetting.1
        self.tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView,
                            didUpdateFocusIn context: UITableViewFocusUpdateContext,
                            with coordinator: UIFocusAnimationCoordinator)
    {
        if let prevIndexPath = context.previouslyFocusedIndexPath {
            let prevCell = tableView.cellForRow(at: prevIndexPath)
            prevCell?.textLabel?.textColor = UIColor.white
        }
        
        if let nextIndexPath = context.nextFocusedIndexPath {
            let nextCell = tableView.cellForRow(at: nextIndexPath)
            nextCell?.textLabel?.textColor = UIColor.black
        }
    }
}
