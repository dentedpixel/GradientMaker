//
//  File.swift
//  
//
//  Created by Russell Savage on 11/14/22.
//

import Foundation
import SwiftUI

extension Gradient {
    
    public func value(at: CGFloat) -> UIColor {
        guard var left = self.stops.first, var right = self.stops.last else { return .magenta }
        
        self.stops.forEach { stop in
            if stop.location < at {
                left = stop
            }
        }
        
        self.stops.reversed().forEach { stop in
            if stop.location > at {
                right = stop
            }
        }
        
        guard right.location > at else { return UIColor(right.color) }
        guard left.location < at else { return UIColor(left.color) }
        
        let diff = right.location - left.location
        let amt = (at - left.location) / diff
        return UIColor(left.color).blend(with: UIColor(right.color), amt: amt)
    }
}

extension UIColor {
    func blend(with color: UIColor, amt: CGFloat) -> UIColor {
        var fromRed :CGFloat = 0
        var fromGreen :CGFloat = 0
        var fromBlue :CGFloat = 0
        var fromAlpha :CGFloat = 0
        self.getRed(&fromRed, green: &fromGreen, blue: &fromBlue, alpha: &fromAlpha)
        
        var toRed :CGFloat = 0
        var toGreen :CGFloat = 0
        var toBlue :CGFloat = 0
        var toAlpha :CGFloat = 0
        color.getRed(&toRed, green: &toGreen, blue: &toBlue, alpha: &toAlpha)
        
        let diffR = toRed - fromRed
        let diffG = toGreen - fromGreen
        let diffB = toBlue - fromBlue
        let diffA = toAlpha - fromAlpha
        
        let r = fromRed + diffR * amt
        let g = fromGreen + diffG * amt
        let b = fromBlue + diffB * amt
        let a = fromAlpha + diffA * amt
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}
