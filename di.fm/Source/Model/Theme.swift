//
//  Theme.swift
//  di.fm
//
//  Created by Charles Magahern on 5/11/16.
//

import Foundation
import UIKit

struct Theme
{
    var backgroundColor:    UIColor = UIColor()
    var secondaryColor:     UIColor = UIColor()
    var tertiaryColor:      UIColor = UIColor()
    var foregroundColor:    UIColor = UIColor()
    var foregroundFont:     UIFont = UIFont()
    
    static func defaultTheme() -> Theme
    {
        var theme = Theme()
        theme.backgroundColor = UIColor(red: 0.08, green: 0.11, blue: 0.15, alpha: 1.00)
        theme.foregroundFont = UIFont(name: "EnzoOT-Medi", size: 14.0)!
        theme.secondaryColor = UIColor(red: 0.13, green: 0.15, blue: 0.21, alpha: 1.00)
        theme.tertiaryColor = UIColor(red: 0.21, green: 0.24, blue: 0.33, alpha: 1.00)
        theme.foregroundColor = UIColor.whiteColor()
        
        return theme
    }
}
