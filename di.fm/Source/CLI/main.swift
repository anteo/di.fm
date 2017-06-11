//
//  main.swift
//  di.fm player
//
//  Created by Charles Magahern on 6/10/17.
//  Copyright © 2017 zanneth. All rights reserved.
//

import Foundation

struct CLIOptions
{
    var username:   String = ""
    var password:   String = ""
    var station:    String = ""
    
    init(_ arguments: [String])
    {
        let argsCount = arguments.count
        var skip = false
        for (idx, arg) in arguments.enumerated() {
            let nextarg = (idx + 1 < argsCount ? arguments[idx + 1] : "")
            
            switch arg {
            case "-u":
                self.username = nextarg
                skip = true
                continue
            case "-p":
                self.password = nextarg
                skip = true
                continue
            default:
                if (!skip && idx == argsCount - 1) {
                    self.station = arg
                }
            }
            
            skip = false
        }
    }
}

func printUsage()
{
    let procname = CommandLine.arguments[0]
    print("usage \(procname) [-u USERNAME] [-p PASSWORD] station")
}

func findChannel(name: String, batchUpdate: BatchUpdate) -> Channel?
{
    var foundChannel: Channel?
    
    for channelFilter in batchUpdate.channelFilters {
        for channel in channelFilter.channels {
            if (channel.name.caseInsensitiveCompare(name) == .orderedSame) {
                foundChannel = channel
                break
            }
        }
        
        if (foundChannel != nil) {
            break
        }
    }
    
    return foundChannel
}

func playStation(options: CLIOptions)
{
    let server = AudioAddictServer()
    
    print("Authenticating...")
    server.authenticate(username: options.username, password: options.password) { (user: AuthenticatedUser?, error: Error?) -> (Void) in
        if let authenticatedUser = user {
            print("Authenticated as \(authenticatedUser.email)")
            print("Fetching stations...")
            
            server.fetchBatchUpdate(Stream.Quality.PremiumHigh, completion: { (batch: BatchUpdate?, error: Error?) -> (Void) in
                if let batch = batch {
                    if let channel = findChannel(name: options.station, batchUpdate: batch) {
                        let player = Player()
                        if #available(OSX 10.12.2, *) {
                            let _ = RemoteController(player: player)
                        }
                        
                        player.listenKey = authenticatedUser.listenKey
                        player.streamSet = batch.streamSets.first
                        player.currentChannel = channel
                        
                        print("Playing station \(channel.name)...")
                        player.play()
                    } else {
                        print("Channel \"\(options.station)\" not found.")
                        exit(-3)
                    }
                } else {
                    print("Error fetching stations. \((error ?? DIError(.unknown)).localizedDescription)")
                    exit(-2)
                }
            })
        } else {
            print("Authentication error. \((error ?? DIError(.unknown)).localizedDescription)")
            exit(-1)
        }
    }
    
    RunLoop.main.run()
}

func main()
{
    let opts = CLIOptions(CommandLine.arguments)
    if (opts.username.isEmpty || opts.password.isEmpty || opts.station.isEmpty) {
        printUsage()
    } else {
        playStation(options: opts)
    }
}

main()
