//
//  Track.swift
//  di.fm
//
//  Created by Charles Magahern on 6/19/16.
//

import AVFoundation
import Foundation

struct Track
{
    var title:      String = ""
    var artist:     String = ""
    var album:      String = ""
    var playerItem: AVPlayerItem
    var assetTrack: AVAssetTrack?
    
    init(_ playerItem: AVPlayerItem)
    {
        self.playerItem = playerItem
        
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
            let titleString = self.title as NSString
            let regex = try! NSRegularExpression(pattern: "(.*) - (.*)", options: NSRegularExpressionOptions())
            let fullRange = NSRange(location: 0, length: titleString.length)
            let matches = regex.matchesInString(titleString as String, options: NSMatchingOptions(), range: fullRange)
            
            if let match = matches.first {
                let artistRange = match.rangeAtIndex(1)
                self.artist = titleString.substringWithRange(artistRange) as String
                
                let titleRange = match.rangeAtIndex(2)
                self.title = titleString.substringWithRange(titleRange) as String
            }
        }
    
        // search for asset track
        for track in playerItem.tracks {
            if (track.assetTrack.mediaType == AVMediaTypeAudio) {
                self.assetTrack = track.assetTrack
                break
            }
        }
    }
}

func ==(left: Track?, right: Track?) -> Bool
{
    var equal: Bool = false
    if let left = left, let right = right {
        equal = (
            left.title == right.title &&
            left.artist == right.artist &&
            left.album == right.album &&
            left.playerItem == right.playerItem &&
            left.assetTrack == right.assetTrack
        )
    }
    return equal
}

func !=(left: Track?, right: Track?) -> Bool
{
    return !(left == right)
}
