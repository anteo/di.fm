//
//  StationCollectionViewCell.swift
//  di.fm
//
//  Created by Charles Magahern on 4/26/16.
//

import Foundation
import UIKit

class StationCollectionViewCell : UICollectionViewCell
{
    private var _imageView: UIImageView = UIImageView()
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        _imageView.adjustsImageWhenAncestorFocused = true
        self.addSubview(_imageView)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("unsupported")
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        _imageView.frame = self.bounds
    }
    
    // MARK: Accessors
    
    var station: Station?
    {
        didSet
        {
            var stationImage: UIImage? = nil
            
            if (self.station != nil) {
                stationImage = _generateStationImage(self.station!)
            }
            
            _imageView.image = stationImage
        }
    }
    
    // MARK: Internal
    
    internal func _generateStationImage(station: Station) -> UIImage
    {
        let imageSize = CGSize(width: 250.0, height: 250.0)
        UIGraphicsBeginImageContextWithOptions(imageSize, true, self.traitCollection.displayScale)
        
        UIColor.blackColor().setFill()
        UIRectFill(CGRect(origin: CGPointZero, size: imageSize))
        
        let stationNameString = NSString(string: station.name)
        let attributes = [
            NSFontAttributeName : UIFont.boldSystemFontOfSize(42.0),
            NSForegroundColorAttributeName : UIColor.whiteColor()
        ]
        
        UIColor.whiteColor().setFill()
        stationNameString.drawInRect(CGRect(origin: CGPointZero, size: imageSize), withAttributes: attributes)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
}
