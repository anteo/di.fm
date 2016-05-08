//
//  AudioAddictURL.swift
//  di.fm
//
//  Created by Charles Magahern on 4/26/16.
//

import Foundation

struct AudioAddictURLComponent
{
    var delimiter:      Character?
    var parameterKeys:  [String] = []
    var position:       String.Index?
}

class AudioAddictURL
{
    private(set) var rawString:  String
    private(set) var components: [AudioAddictURLComponent]
    
    init()
    {
        self.rawString = ""
        self.components = []
    }
    
    init(_ rawString: String)
    {
        self.rawString = rawString
        self.components = AudioAddictURL._parseURLComponents(rawString)
    }
    
    // MARK: Internal
    internal class func _parseURLComponents(string: String) -> [AudioAddictURLComponent]
    {
        var components: [AudioAddictURLComponent] = []
        
        let foundationString = string as NSString
        let pattern = "\\{((.)([\\w,]+)+)\\}"
        let regex = try! NSRegularExpression(pattern: pattern, options: NSRegularExpressionOptions())
        let fullRange = NSMakeRange(0, string.characters.count)
        let matches = regex.matchesInString(string, options: NSMatchingOptions(), range: fullRange)
        
        for result in matches {
            var component = AudioAddictURLComponent()
            
            // store position
            let from16 = string.utf16.startIndex.advancedBy(result.range.location)
            component.position = String.Index(from16, within: string)
            
            // parse delimiter
            let delimiterString = foundationString.substringWithRange(result.rangeAtIndex(2))
            if (delimiterString.characters.count > 0) {
                component.delimiter = delimiterString[delimiterString.startIndex]
            }
            
            // parse parameter keys
            let paramsString = foundationString.substringWithRange(result.rangeAtIndex(3))
            component.parameterKeys = paramsString.componentsSeparatedByString(",")
            
            // append
            components.append(component)
        }
        
        return components
    }
}
