//
//  LoginViewController.swift
//  di.fm
//
//  Created by Charles Magahern on 5/8/16.
//  Copyright © 2016 zanneth. All rights reserved.
//

import Foundation
import UIKit

protocol LoginViewControllerDelegate: class
{
    func loginViewControllerDidSubmitCredentials(controller: LoginViewController,
                                                 email: String,
                                                 password: String,
                                                 completion: (NSError?) -> (Void))
}

class LoginViewController : UIViewController
{
    weak var delegate:              LoginViewControllerDelegate?
    
    private var _logoImageView:     UIImageView = UIImageView()
    private var _formContainerView: UIView = UIView()
    private var _emailTextField:    UITextField = UITextField()
    private var _passwordTextField: UITextField = UITextField()
    private var _loginButton:       UIButton = UIButton(type: .System)
    private var _spinner:           UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .White)
    
    // MARK: UIViewController
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let theme = Theme.defaultTheme()
        
        _logoImageView.image = UIImage(named: "di_logo_title")
        _logoImageView.contentMode = .ScaleAspectFit
        self.view.addSubview(_logoImageView)
        
        _formContainerView.backgroundColor = theme.secondaryColor
        _formContainerView.clipsToBounds = true
        _formContainerView.layer.cornerRadius = 24.0
        self.view.addSubview(_formContainerView)
        
        _emailTextField.placeholder = NSLocalizedString("LOGIN_EMAIL_PLACEHOLDER_TEXT", comment: "")
        _emailTextField.keyboardType = .EmailAddress
        _emailTextField.autocorrectionType = .No
        _emailTextField.autocapitalizationType = .None
        _emailTextField.addTarget(self, action: #selector(_textFieldValueChanged), forControlEvents: .EditingChanged)
        _formContainerView.addSubview(_emailTextField)
        
        _passwordTextField.placeholder = NSLocalizedString("LOGIN_PASSWORD_PLACEHOLDER_TEXT", comment: "")
        _passwordTextField.secureTextEntry = true
        _passwordTextField.autocorrectionType = .No
        _passwordTextField.autocapitalizationType = .None
        _passwordTextField.addTarget(self, action: #selector(_textFieldValueChanged), forControlEvents: .EditingChanged)
        _formContainerView.addSubview(_passwordTextField)
        
        _loginButton.enabled = false
        _loginButton.setTitle(NSLocalizedString("LOGIN_BUTTON_TEXT", comment: ""), forState: .Normal)
        _loginButton.addTarget(self, action: #selector(_loginButtonSelected), forControlEvents: .PrimaryActionTriggered)
        _formContainerView.addSubview(_loginButton)
        
        _spinner.stopAnimating()
        _spinner.hidesWhenStopped = true
        _formContainerView.addSubview(_spinner)
    }
    
    override func viewWillLayoutSubviews()
    {
        super.viewWillLayoutSubviews()
        
        let bounds = self.view.bounds
        let containerViewDimensions = bounds.size.height / 2.0
        let headerFormPadding = CGFloat(50.0)
        let textFieldsPadding = CGFloat(40.0)
        let loginButtonMarginTop = CGFloat(60.0)
        let spinnerMarginTop = CGFloat(40.0)
        
        let logoViewHeight = containerViewDimensions / 8.0
        let logoViewImageSize = _logoImageView.image!.size
        let logoViewSize = CGSize(width: rint((logoViewHeight / logoViewImageSize.height) * logoViewImageSize.width), height: logoViewHeight)
        let emailFieldSize = _emailTextField.sizeThatFits(bounds.size)
        let passwordFieldSize = _passwordTextField.sizeThatFits(bounds.size)
        let loginButtonSize = _loginButton.sizeThatFits(bounds.size)
        let textFieldsWidth = bounds.size.width / 5.0
        let totalViewsHeight = logoViewSize.height + headerFormPadding + containerViewDimensions
        let totalFieldsHeight = emailFieldSize.height + textFieldsPadding + passwordFieldSize.height + loginButtonMarginTop + loginButtonSize.height
        
        let logoViewFrame = CGRect(
            x: rint(bounds.size.width / 2.0 - logoViewSize.width / 2.0),
            y: rint(bounds.size.height / 2.0 - totalViewsHeight / 2.0),
            width: logoViewSize.width,
            height: logoViewSize.height
        )
        _logoImageView.frame = logoViewFrame
        
        let containerFrame = CGRect(
            x: rint(bounds.size.width / 2.0 - containerViewDimensions / 2.0),
            y: CGRectGetMaxY(logoViewFrame) + headerFormPadding,
            width: containerViewDimensions,
            height: containerViewDimensions
        )
        _formContainerView.frame = containerFrame
        
        let emailFrame = CGRect(
            x: rint(containerViewDimensions / 2.0 - textFieldsWidth / 2.0),
            y: rint(containerViewDimensions / 2.0 - totalFieldsHeight / 2.0),
            width: textFieldsWidth,
            height: emailFieldSize.height
        )
        _emailTextField.frame = emailFrame
        
        let passwordFrame = CGRect(
            x: rint(containerViewDimensions / 2.0 - textFieldsWidth / 2.0),
            y: CGRectGetMaxY(emailFrame) + textFieldsPadding,
            width: textFieldsWidth,
            height: passwordFieldSize.height
        )
        _passwordTextField.frame = passwordFrame
        
        let loginButtonFrame = CGRect(
            x: rint(containerViewDimensions / 2.0 - loginButtonSize.width / 2.0),
            y: CGRectGetMaxY(passwordFrame) + loginButtonMarginTop,
            width: loginButtonSize.width,
            height: loginButtonSize.height
        )
        _loginButton.frame = loginButtonFrame
        
        let spinnerSize = _spinner.sizeThatFits(bounds.size)
        let spinnerFrame = CGRect(
            x: rint(containerViewDimensions / 2.0 - spinnerSize.width / 2.0),
            y: CGRectGetMaxY(loginButtonFrame) + spinnerMarginTop,
            width: spinnerSize.width,
            height: spinnerSize.height
        )
        _spinner.frame = spinnerFrame
    }
    
    // MARK: Actions
    
    internal func _textFieldValueChanged(sender: UITextField)
    {
        let email = _emailTextField.text!
        let password = _passwordTextField.text!
        if (email.characters.count > 0 && password.characters.count > 0) {
            _loginButton.enabled = true
        } else {
            _loginButton.enabled = false
        }
    }
    
    internal func _loginButtonSelected(sender: UIButton)
    {
        _setLoadingStateVisible(true)
        
        let email = _emailTextField.text!
        let password = _passwordTextField.text!
        
        self.delegate?.loginViewControllerDidSubmitCredentials(self,
                                                               email: email,
                                                               password: password,
                                                               completion:
        { (error: NSError?) -> (Void) in
            dispatch_async(dispatch_get_main_queue()) {
                self._setLoadingStateVisible(false)
                
                if (error != nil) {
                    let alertTitle = NSLocalizedString("LOGIN_FAILED_MESSAGE_TITLE", comment: "")
                    let alertMessage = error!.localizedDescription
                    let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .Default, handler: { (action: UIAlertAction) in
                        self.dismissViewControllerAnimated(true, completion: nil)
                    }))
                    self.presentViewController(alert, animated: true, completion: {
                        // clear password field
                        self._passwordTextField.text = ""
                    })
                }
            }
        })
    }
    
    // MARK: Internal
    
    internal func _setLoadingStateVisible(visible: Bool)
    {
        if (visible) {
            _spinner.startAnimating()
            _loginButton.enabled = false
        } else {
            _spinner.stopAnimating()
            _loginButton.enabled = true
        }
    }
}
