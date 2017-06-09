//
//  Track.swift
//  di.fm
//
//  Created by Charles Magahern on 6/19/16.
//  Copyright © 2016 zanneth. All rights reserved.
//

import AVFoundation
import Foundation

struct Track
{
    var title:      String = ""
    var artist:     String = ""
    var album:      String = ""
    
    init()
    {}
    
    init(_ metadataDictionary: [String : String])
    {
        if let concatenatedTitle = metadataDictionary["StreamTitle"] {
            (self.title, self.artist) = _titleArtistFromConcatenatedMetadata(concatenatedTitle)
        }
    }
    
    init(_ playerItem: AVPlayerItem)
    {
        // parse player item metadata
        if let metadata = playerItem.timedMetadata {
            for metadataItem in metadata {
                if let key = metadataItem.commonKey {
                    switch key {
                    case AVMetadataCommonKeyTitle:
                        self.title = metadataItem.value as? String ?? ""
                    case AVMetadataCommonKeyArtist:
                        self.artist = metadataItem.value as? String ?? ""
                    case AVMetadataCommonKeyAlbumName:
                        self.album = metadataItem.value as? String ?? ""
                    default:
                        break
                    }
                }
            }
        }
        
        /* di.fm streams seem to provide the metadata in the form:
            title = "Artist - Track Name"
            artist = nil
           so in that case, we must parse the artist name from the title
        */
        if (self.artist.isEmpty) {
            (self.title, self.artist) = _titleArtistFromConcatenatedMetadata(self.title)
        }
    }
    
    internal func _titleArtistFromConcatenatedMetadata(_ string: String) -> (String, String)
    {
        let titleString = string as NSString
        let regex = try! NSRegularExpression(pattern: "(.*) - (.*)", options: NSRegularExpression.Options())
        let fullRange = NSRange(location: 0, length: titleString.length)
        let matches = regex.matches(in: titleString as String, options: NSRegularExpression.MatchingOptions(), range: fullRange)
        
        var title: String = ""
        var artist: String = ""
        
        if let match = matches.first {
            let artistRange = match.rangeAt(1)
            artist = titleString.substring(with: artistRange) as String
            
            let titleRange = match.rangeAt(2)
            title = titleString.substring(with: titleRange) as String
        }
        
        return (title, artist)
    }
}

func ==(left: Track?, right: Track?) -> Bool
{
    var equal: Bool = false
    if let left = left, let right = right {
        equal = (
            left.title == right.title &&
            left.artist == right.artist &&
            left.album == right.album
        )
    }
    return equal
}

func !=(left: Track?, right: Track?) -> Bool
{
    return !(left == right)
}
