//
//  ChannelCollectionViewCell.swift
//  di.fm
//
//  Created by Charles Magahern on 4/26/16.
//

import Foundation
import UIKit

class ChannelCollectionViewCell : UICollectionViewCell
{
    private var _imageView: UIImageView = UIImageView()
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        _imageView.adjustsImageWhenAncestorFocused = true
        _imageView.image = _placeholderArtworkImage()
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
    
    var channel: Channel? {
        didSet
        {
            self.channelImage = nil
        }
    }
    
    var channelImage: UIImage? {
        didSet
        {
            if (self.channelImage != nil) {
                _imageView.image = self.channelImage
            } else {
                _imageView.image = _placeholderArtworkImage()
            }
        }
    }
    
    // MARK: Internal
    
    func _placeholderArtworkImage() -> UIImage
    {
        return UIImage(named: "placeholder-artwork")!
    }
}
