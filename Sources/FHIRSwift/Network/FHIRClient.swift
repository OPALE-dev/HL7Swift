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


/**
 A minimal FHIR Restful client with basic CRUD operations, based on SwiftNIO/AsyncHTTPClient
 */
public class FHIRClient {
    var baseURL:URL!
    var encoder = JSONEncoder()
    var httpClient:HTTPClient!
    
    
    init(_ baseURL:URL) {
        self.httpClient = HTTPClient(eventLoopGroupProvider: .createNew)
        self.baseURL = baseURL
    }
    
    
    deinit {
        try? httpClient.syncShutdown()
    }
    
    
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
    
    
    func update(_ resource:Resource, id:String) throws -> EventLoopFuture<HTTPClient.Response> {
        let data = try encoder.encode(resource)
        let url = baseURL
            .appendingPathComponent("\(type(of: resource))")
            .appendingPathComponent(id)
                
        var request = try HTTPClient.Request(url: url, method: .POST)
        request.headers.add(name: "Content-Type", value: "application/fhir+json")
        
        if let body = String(data: data, encoding: .utf8) {
            request.body = HTTPClient.Body.string(body)
        }
        
        return httpClient.execute(request: request)
    }
    
    
    func read(_ resourceName:String, id:String) throws -> EventLoopFuture<HTTPClient.Response> {
        let url = baseURL
            .appendingPathComponent("\(type(of: resourceName))")
            .appendingPathComponent(id)
                
        var request = try HTTPClient.Request(url: url, method: .GET)
        request.headers.add(name: "Content-Type", value: "application/fhir+json")
        
        return httpClient.execute(request: request)
    }

    
    func delete(_ resourceName:String, id:String) throws -> EventLoopFuture<HTTPClient.Response> {
        let url = baseURL
            .appendingPathComponent(resourceName)
            .appendingPathComponent(id)
                
        var request = try HTTPClient.Request(url: url, method: .DELETE)
        request.headers.add(name: "Content-Type", value: "application/fhir+json")
        
        return httpClient.execute(request: request)
    }
}
