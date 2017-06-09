//
//  Theme.swift
//  di.fm
//
//  Created by Charles Magahern on 5/11/16.
//  Copyright © 2016 zanneth. All rights reserved.
//

import Foundation
import UIKit

struct Theme
{
    var backgroundColor:    UIColor = UIColor()
    var secondaryColor:     UIColor = UIColor()
    var tertiaryColor:      UIColor = UIColor()
    var foregroundColor:    UIColor = UIColor()
    var titleFont:          UIFont = UIFont()
    var foregroundFont:     UIFont = UIFont()
    
    static func defaultTheme() -> Theme
    {
        var theme = Theme()
        theme.backgroundColor = UIColor(red: 0.08, green: 0.11, blue: 0.15, alpha: 1.00)
        theme.titleFont = UIFont(name: "EnzoOT-Bold", size: 48.0)!
        theme.foregroundFont = UIFont(name: "EnzoOT-Medi", size: 38.0)!
        theme.secondaryColor = UIColor(red: 0.13, green: 0.15, blue: 0.21, alpha: 1.00)
        theme.tertiaryColor = UIColor(red: 0.21, green: 0.24, blue: 0.33, alpha: 1.00)
        theme.foregroundColor = UIColor.white
        
        return theme
    }
}
