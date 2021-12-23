//
//  File.swift
//  
//
//  Created by Rafael Warnault on 23/12/2021.
//

import Foundation
import NIO

public class HL7Server {
    var host:String = "0.0.0.0"
    var port:Int = 2575
    
    var channel: Channel!
    var group:MultiThreadedEventLoopGroup!
    var bootstrap:ServerBootstrap!
    
    public init(port: Int, localAET:String) {
        
    }
}

