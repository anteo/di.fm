//
//  LoginViewController.swift
//  di.fm
//
//  Created by Charles Magahern on 5/8/16.
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
    
    private var _containerView:     UIView = UIView()
    private var _emailTextField:    UITextField = UITextField()
    private var _passwordTextField: UITextField = UITextField()
    private var _loginButton:       UIButton = UIButton(type: .System)
    
    // MARK: UIViewController
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let theme = Theme.defaultTheme()
        
        _containerView.backgroundColor = theme.secondaryColor
        _containerView.clipsToBounds = true
        _containerView.layer.cornerRadius = 6.0
        self.view.addSubview(_containerView)
        
        _emailTextField.placeholder = NSLocalizedString("LOGIN_EMAIL_PLACEHOLDER_TEXT", comment: "")
        _emailTextField.keyboardType = .EmailAddress
        _emailTextField.autocorrectionType = .No
        _emailTextField.autocapitalizationType = .None
        _containerView.addSubview(_emailTextField)
        
        _passwordTextField.placeholder = NSLocalizedString("LOGIN_PASSWORD_PLACEHOLDER_TEXT", comment: "")
        _passwordTextField.secureTextEntry = true
        _passwordTextField.autocorrectionType = .No
        _passwordTextField.autocapitalizationType = .None
        _containerView.addSubview(_passwordTextField)
        
        _loginButton.setTitle(NSLocalizedString("LOGIN_BUTTON_TEXT", comment: ""), forState: .Normal)
        _loginButton.addTarget(self, action: #selector(_loginButtonSelected), forControlEvents: .PrimaryActionTriggered)
        _containerView.addSubview(_loginButton)
    }
    
    override func viewWillLayoutSubviews()
    {
        super.viewWillLayoutSubviews()
        
        let bounds = self.view.bounds
        let containerViewDimensions = bounds.size.height / 2.0
        let textFieldsPadding = CGFloat(30.0)
        let loginButtonMarginTop = CGFloat(50.0)
        
        let emailFieldSize = _emailTextField.sizeThatFits(bounds.size)
        let passwordFieldSize = _passwordTextField.sizeThatFits(bounds.size)
        let loginButtonSize = _loginButton.sizeThatFits(bounds.size)
        let totalFieldsHeight = emailFieldSize.height + textFieldsPadding + passwordFieldSize.height + loginButtonMarginTop + loginButtonSize.height
        let textFieldsWidth = bounds.size.width / 5.0
        
        let containerFrame = CGRect(
            x: rint(bounds.size.width / 2.0 - containerViewDimensions / 2.0),
            y: rint(bounds.size.height / 2.0 - containerViewDimensions / 2.0),
            width: containerViewDimensions,
            height: containerViewDimensions
        )
        _containerView.frame = containerFrame
        
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
    }
    
    // MARK: Actions
    
    func _loginButtonSelected(sender: UIButton)
    {
        let email = _emailTextField.text!
        let password = _passwordTextField.text!
        
        self.delegate?.loginViewControllerDidSubmitCredentials(self,
                                                               email: email,
                                                               password: password,
                                                               completion:
        { (error: NSError?) -> (Void) in
            dispatch_async(dispatch_get_main_queue()) {
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
}
