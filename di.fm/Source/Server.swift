//
//  DigitallyImportedServer.swift
//  di.fm
//
//  Created by Charles Magahern on 4/26/16.
//

import Foundation

class Server
{
    private var _urlSession:            NSURLSession
    private var _operationQueue:        NSOperationQueue = NSOperationQueue()
    private var _errorStream:           StandardErrorOutputStream = StandardErrorOutputStream()
    
    private let _baseURL:               NSURL = NSURL(string: "http://listen.di.fm/")!
    
    init()
    {
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        _urlSession = NSURLSession(configuration: config)
        _operationQueue.maxConcurrentOperationCount = 1
    }
    
    func fetchStations(stationsQuality: Station.Quality, completion: ([Station], NSError?) -> Void)
    {
        let op = FetchStationsOperation(baseURL: _baseURL, session: _urlSession)
        op.stationQuality = stationsQuality
        
        weak var weakOp = op
        op.completionBlock = {
            guard let strongOp = weakOp else { completion([], nil) ; return }
            if (strongOp.error != nil) {
                self._logError("Error fetching stations", error: strongOp.error!)
            }
            
            completion(strongOp.stations, strongOp.error)
        }
        _operationQueue.addOperation(op)
    }
    
    // MARK: Internal
    
    internal func _logError(description: String, error: NSError)
    {
        print("ERROR: \(description) \(error)", toStream: &_errorStream)
    }
}

internal class ServerOperation : NSOperation
{
    var baseURL:    NSURL
    var session:    NSURLSession
    internal(set) var error: NSError?
    
    init(baseURL: NSURL, session: NSURLSession)
    {
        self.baseURL = baseURL
        self.session = session
    }
    
    func fetchData(url: NSURL) -> NSData?
    {
        var fetchedData: NSData?
        let semaphore = Semaphore(value: 0)
        
        let task = self.session.dataTaskWithURL(url) { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            if (data != nil) {
                fetchedData = data
            } else {
                self.error = NSError.difmError(.ConnectionError, underlying: error)
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
        
        return fetchedData
    }
}

internal class FetchStationsOperation : ServerOperation
{
    var stationQuality: Station.Quality = .PublicHigh
    internal(set) var stations: [Station] = []
    
    override func main()
    {
        var stations: [Station] = []
        let url = self.baseURL.URLByAppendingPathComponent(self.stationQuality.rawValue)
        let data = self.fetchData(url)
        
        if (data != nil) {
            if let stationDictsArray = (try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions()) as? NSArray) {
                for stationObj in stationDictsArray! {
                    if let stationDict = stationObj as? NSDictionary {
                        var station = Station(stationDict)
                        station.quality = self.stationQuality
                        stations.append(station)
                    }
                }
            }
        }
        
        self.stations = stations
    }
}
