//
//  AudioAddictURL.swift
//  di.fm
//
//  Created by Charles Magahern on 4/26/16.
//  Copyright © 2016 zanneth. All rights reserved.
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
    fileprivate(set) var rawString:  String
    fileprivate(set) var components: [AudioAddictURLComponent]
    
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
    
    func url(_ parameters: [String : String]?) -> URL?
    {
        var urlString = self.rawString
        let components = self.components
        
        for component in components {
            var strValueToInsert = ""
            
            if (component.isQueryItemComponent()) {
                var queryItems: [URLQueryItem] = []
                
                if (parameters != nil) {
                    for parameterKey in component.parameterKeys {
                        if let parameterValue = parameters![parameterKey] {
                            let queryItem = URLQueryItem(name: parameterKey, value: parameterValue)
                            queryItems.append(queryItem)
                        }
                    }
                }
                
                if (queryItems.count > 0) {
                    var urlComponents = URLComponents()
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
            
            urlString = urlString.replacingOccurrences(of: component.rawString, with: strValueToInsert)
        }
        
        var urlComponents = URLComponents(string: urlString)!
        if (urlComponents.scheme == nil) {
            urlComponents.scheme = "http"
        }
        
        return urlComponents.url
    }
    
    // MARK: Internal
    internal class func _parseURLComponents(_ string: String) -> [AudioAddictURLComponent]
    {
        var components: [AudioAddictURLComponent] = []
        
        let foundationString = string as NSString
        let pattern = "\\{((.)([\\w,]+)+)\\}"
        let regex = try! NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options())
        let fullRange = NSMakeRange(0, string.count)
        let matches = regex.matches(in: string, options: NSRegularExpression.MatchingOptions(), range: fullRange)
        
        for result in matches {
            var component = AudioAddictURLComponent()
            
            // store position
            let from16 = string.utf16.index(string.utf16.startIndex, offsetBy: result.range.location)
            component.position = String.Index(from16, within: string)
            
            // parse delimiter
            let delimiterString = foundationString.substring(with: result.range(at: 2))
            if (delimiterString.count > 0) {
                component.delimiter = delimiterString[delimiterString.startIndex]
            }
            
            // parse parameter keys
            let paramsString = foundationString.substring(with: result.range(at: 3))
            component.parameterKeys = paramsString.components(separatedBy: ",")
            
            // store complete match
            component.rawString = foundationString.substring(with: result.range(at: 0))
            
            // append
            components.append(component)
        }
        
        return components
    }
}
