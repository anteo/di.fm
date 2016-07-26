//
//  TVSupport.swift
//  di.fm
//
//  Created by Charles Magahern on 4/26/16.
//  Copyright © 2016 zanneth. All rights reserved.
//

import Foundation
import UIKit

/* Values from https://developer.apple.com/tvos/human-interface-guidelines/visual-design/ */

let TVContentSafeZoneInsets = UIEdgeInsets(top: 60.0, left: 90.0, bottom: 60.0, right: 90.0)

struct TVLayoutTemplate {
    var unfocusedContentWidth:      CGFloat
    var horizontalSpacing:          CGFloat
    var minimumVerticalSpacing:     CGFloat
}

let TVThreeColumnGridTemplate   = TVLayoutTemplate(unfocusedContentWidth: 548.0, horizontalSpacing: 48.0, minimumVerticalSpacing: 100.0)
let TVFourColumnGridTemplate    = TVLayoutTemplate(unfocusedContentWidth: 375.0, horizontalSpacing: 80.0, minimumVerticalSpacing: 100.0)
let TVFiveColumnGridTemplate    = TVLayoutTemplate(unfocusedContentWidth: 308.0, horizontalSpacing: 50.0, minimumVerticalSpacing: 100.0)
let TVSixColumnGridTemplate     = TVLayoutTemplate(unfocusedContentWidth: 250.0, horizontalSpacing: 48.0, minimumVerticalSpacing: 100.0)
let TVSevenColumnGridTemplate   = TVLayoutTemplate(unfocusedContentWidth: 204.0, horizontalSpacing: 52.0, minimumVerticalSpacing: 100.0)
let TVEightColumnGridTemplate   = TVLayoutTemplate(unfocusedContentWidth: 172.0, horizontalSpacing: 52.0, minimumVerticalSpacing: 100.0)
let TVNineColumnGridTemplate    = TVLayoutTemplate(unfocusedContentWidth: 148.0, horizontalSpacing: 51.0, minimumVerticalSpacing: 100.0)
