//
//  LoadingViewController.swift
//  di.fm
//
//  Created by Charles Magahern on 5/11/16.
//  Copyright © 2016 zanneth. All rights reserved.
//

import Foundation
import UIKit

class LoadingViewController : UIViewController
{
    fileprivate var _logoImageView: UIImageView = UIImageView()
    fileprivate var _spinner:       UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        _logoImageView.image = UIImage(named: "di_logo")
        self.view.addSubview(_logoImageView)
        
        _spinner.startAnimating()
        self.view.addSubview(_spinner)
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        
        let bounds = self.view.bounds
        let logoSpinnerPadding = CGFloat(80.0)
        let logoImageViewHeight = CGFloat(120.0)
        
        let logoImageSize = _logoImageView.image!.size
        let logoImageViewSize = CGSize(width: rint((logoImageViewHeight / logoImageSize.height) * logoImageSize.width), height: logoImageViewHeight)
        let spinnerSize = _spinner.sizeThatFits(bounds.size)
        let totalViewsHeight = logoImageViewSize.height + logoSpinnerPadding + logoImageViewSize.height
        
        let logoImageViewFrame = CGRect(
            x: rint(bounds.size.width / 2.0 - logoImageViewSize.width / 2.0),
            y: rint(bounds.size.height / 2.0 - totalViewsHeight / 2.0),
            width: logoImageViewSize.width,
            height: logoImageViewSize.height
        )
        _logoImageView.frame = logoImageViewFrame
        
        let spinnerFrame = CGRect(
            x: rint(bounds.size.width / 2.0 - spinnerSize.width / 2.0),
            y: logoImageViewFrame.maxY + logoSpinnerPadding,
            width: spinnerSize.width,
            height: spinnerSize.height
        )
        _spinner.frame = spinnerFrame
    }
}
