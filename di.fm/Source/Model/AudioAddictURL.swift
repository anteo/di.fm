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
    var rawString:      String = ""
    
    func isQueryItemComponent() -> Bool
    {
        return self.delimiter == "?"
    }
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
    
    func url(parameters: [String : String]?) -> NSURL
    {
        var urlString = self.rawString
        let components = self.components
        
        for component in components {
            var strValueToInsert = ""
            
            if (component.isQueryItemComponent()) {
                var queryItems: [NSURLQueryItem] = []
                
                if (parameters != nil) {
                    for parameterKey in component.parameterKeys {
                        if let parameterValue = parameters![parameterKey] {
                            let queryItem = NSURLQueryItem(name: parameterKey, value: parameterValue)
                            queryItems.append(queryItem)
                        }
                    }
                }
                
                if (queryItems.count > 0) {
                    let urlComponents = NSURLComponents()
                    urlComponents.queryItems = queryItems
                    
                    if (urlComponents.query != nil) {
                        strValueToInsert = "?\(urlComponents.query!)"
                    }
                }
            } else {
                assert(component.parameterKeys.count <= 1, "cannot have a non-query item component contain more than one parameter")
                
                if (parameters != nil && component.parameterKeys.count > 0) {
                    if let parameterValue = parameters![component.parameterKeys[0]] {
                        if (component.delimiter != nil) {
                            strValueToInsert = String(component.delimiter!) + parameterValue
                        } else {
                            strValueToInsert = parameterValue
                        }
                    }
                }
            }
            
            urlString = urlString.stringByReplacingOccurrencesOfString(component.rawString, withString: strValueToInsert)
        }
        
        let urlComponents = NSURLComponents(string: urlString)!
        if (urlComponents.scheme == nil) {
            urlComponents.scheme = "http"
        }
        
        return urlComponents.URL ?? NSURL()
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
            
            // store complete match
            component.rawString = foundationString.substringWithRange(result.rangeAtIndex(0))
            
            // append
            components.append(component)
        }
        
        return components
    }
}
