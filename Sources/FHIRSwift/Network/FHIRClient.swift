//
//  File.swift
//  
//
//  Created by Rafael Warnault on 15/02/2022.
//

import Foundation
import NIO
import AsyncHTTPClient
import ModelsR4



public class FHIRClient {
    var baseURL:URL!
    var encoder = JSONEncoder()
    var httpClient:HTTPClient!
    
    
    init(_ baseURL:URL) {
        self.httpClient = HTTPClient(eventLoopGroupProvider: .createNew)
        self.baseURL = baseURL
    }
    
    
//    deinit {
//        try? httpClient.syncShutdown()
//    }
//    
    
    func create(_ resource:Resource) throws -> EventLoopFuture<HTTPClient.Response> {
        let data = try encoder.encode(resource)
        let url = baseURL.appendingPathComponent("\(type(of: resource))")
                
        var request = try HTTPClient.Request(url: url, method: .POST)
        request.headers.add(name: "Content-Type", value: "application/fhir+json")
        
        if let body = String(data: data, encoding: .utf8) {
            request.body = HTTPClient.Body.string(body)
        }
        
        return httpClient.execute(request: request)
    }
    
    
    func update() {
        
    }
    
    
    func patch() {
        
    }
    
    
    func read() {
        
    }
    
    
    func delete(_ resource:String, id:String) throws -> EventLoopFuture<HTTPClient.Response> {
        let url = baseURL
            .appendingPathComponent(resource)
            .appendingPathComponent(id)
                
        var request = try HTTPClient.Request(url: url, method: .DELETE)
        request.headers.add(name: "Content-Type", value: "application/fhir+json")
        
        return httpClient.execute(request: request)
    }
}
