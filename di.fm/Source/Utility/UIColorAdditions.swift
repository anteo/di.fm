//
//  UIColorAdditions.swift
//  di.fm
//
//  Created by Charles Magahern on 7/10/16.
//  Copyright © 2016 zanneth. All rights reserved.
//

import Foundation
import UIKit

extension UIColor
{
    func lighterColor() -> UIColor
    {
        var h: CGFloat = 0.0
        var s: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 0.0
        
        self.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: s, brightness: (b + 0.25), alpha: a)
    }
}
