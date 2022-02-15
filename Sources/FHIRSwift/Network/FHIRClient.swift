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


public enum FHIRCreateResult {
    case error(_ error:Error)
    case success(_ id:String, _ url:URL, _ json:[String : Any])
}


public enum FHIRReadResult {
    case error(_ error:Error)
    case success(_ resource:Resource, _ url:URL)
}



public enum FHIRClientError: LocalizedError, Equatable {
    case errorResponse(status:Int, message: String)
    case readSyncResponse(message: String)
    case readNotFound(message: String)
    case malformedURL(message: String)
    
    public var errorDescription: String? {
        switch self {
  
        case .errorResponse(let status, let message):
            return "HTTP Error Response: [\(status)] \(message)"
            
        case .readSyncResponse(let message):
            return "Error during sync read: \(message)"
           
        case .readNotFound(let message):
            return "Read Not Found: \(message)"
            
        case .malformedURL(let message):
            return "Malformed URL: \(message)"
        }
    }
}


/**
 A minimal FHIR Restful client with basic CRUD operations, based on SwiftNIO/AsyncHTTPClient
 */
public class FHIRClient {
    var baseURL:URL!
    var encoder = JSONEncoder()
    var decoder = JSONDecoder()
    var httpClient:HTTPClient!
    
    
    init(_ baseURL:URL) {
        self.httpClient = HTTPClient(eventLoopGroupProvider: .createNew)
        self.baseURL = baseURL
    }
    
    
    deinit {
        try? httpClient.syncShutdown()
    }
    
    
    func create(_ resource:Resource, _ completion: @escaping (FHIRCreateResult) -> ()) throws {
        let data = try encoder.encode(resource)
        let url = baseURL.appendingPathComponent("\(type(of: resource))")
                
        var request = try HTTPClient.Request(url: url, method: .POST)
        request.headers.add(name: "Content-Type", value: "application/fhir+json")
        
        if let body = String(data: data, encoding: .utf8) {
            request.body = HTTPClient.Body.string(body)
        }
                
        httpClient.execute(request: request).whenComplete { result in
            switch result {
            case .failure(let error):
                completion(.error(error))
                
            case .success(var response):
                // if 201 Created
                if response.status == .created {
                    // handle JSON response
                    if let rb = response.body?.readableBytes {
                        if let data = response.body?.readData(length: rb) {
                            do {
                                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] {
                                    if let id = json["id"] as? String {
                                        completion(.success(id, url.appendingPathComponent(id), json))
                                    }
                                }
                            } catch let e {
                                // JSON serialization fails
                                completion(.error(e))
                            }
                        }
                    }
                } else {
                    // HTTP status error
                    completion(.error(FHIRClientError.errorResponse(
                                        status: Int(response.status.code),
                                        message: "No resource ID found (\(response.status.reasonPhrase))")))
                }
            }
        }
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
    
    
    /**
     Search sync
     */
    func read(_ resourceName:String, params:[String:String]) throws -> FHIRReadResult {
        let url = baseURL.appendingPathComponent(resourceName)
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        components.queryItems = params.map({ (key, value) -> URLQueryItem in
            URLQueryItem(name: key, value: value)
        })
        
        guard let url = components.url else { throw FHIRClientError.malformedURL(message: url.description) }
        
        print("url \(url)")
        
        var request = try HTTPClient.Request(url: url, method: .GET)
        request.headers.add(name: "Content-Type", value: "application/fhir+json")
        
        var response = try httpClient.execute(request: request).wait()
                
        if response.status == .ok {
            if let rb = response.body?.readableBytes {
                if let data = response.body?.readData(length: rb) {
                    do {
                        let proxy = try decoder.decode(ResourceProxy.self, from: data)
                        
                        if case .bundle(let bundle) = proxy {
                            let patients = bundle.entry?.compactMap {
                                $0.resource?.get(if: ModelsR4.Patient.self)
                            }
                            
                            if let first = patients?.first {
                                return FHIRReadResult.success(first, url)
                            }
                        }
                    } catch let e {
                        // JSON serialization fails
                        return FHIRReadResult.error(e)
                    }
                }
            }
        } else {
            return FHIRReadResult.error(
                FHIRClientError.readNotFound(
                    message: "Resource not found [\(response.status.code)] \(response.status.reasonPhrase)"))
        }
        
        return FHIRReadResult.error(
            FHIRClientError.readSyncResponse(
                message: "Cannot read JSON data"))
    }
    
    
    /**
     Read sync
     */
    func read(_ resourceName:String, id:String) throws -> FHIRReadResult {
        let url = baseURL
            .appendingPathComponent(resourceName)
            .appendingPathComponent(id)
                
        var request = try HTTPClient.Request(url: url, method: .GET)
        request.headers.add(name: "Content-Type", value: "application/fhir+json")
        
        var response = try httpClient.execute(request: request).wait()
        
        if let rb = response.body?.readableBytes {
            if let data = response.body?.readData(length: rb) {
                do {
                    let patient = try decoder.decode(Patient.self, from: data)

                    return FHIRReadResult.success(patient, url.appendingPathComponent(id))
                } catch let e {
                    // JSON serialization fails
                    return FHIRReadResult.error(e)
                }
            }
        }
        
        return FHIRReadResult.error(FHIRClientError.readSyncResponse(message: "Cannot decode JSON data"))
    }
    
    
    /**
     Read async
     */
    func read(_ resourceName:String, id:String, _ completion: @escaping (FHIRReadResult) -> ()) throws {
        let url = baseURL
            .appendingPathComponent("\(type(of: resourceName))")
            .appendingPathComponent(id)
                
        var request = try HTTPClient.Request(url: url, method: .GET)
        request.headers.add(name: "Content-Type", value: "application/fhir+json")
        
        httpClient.execute(request: request).whenComplete { result in
            switch result {
            case .failure(let error):
                completion(.error(error))
                
            case .success(var response):
                // if 302 Found
                if response.status == .found {
                    if let rb = response.body?.readableBytes {
                        if let data = response.body?.readData(length: rb) {
                            do {
                                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] {
                                    print(json)
//                                    if let id = json["id"] as? String {
//                                        if resourceName == "Patient" {
//                                            let patient = Patient(from: <#T##Decoder#>)
//
//                                            completion(.success(patient, url.appendingPathComponent(id), json))
//                                        }
//                                    }
                                }
                            } catch let e {
                                // JSON serialization fails
                                completion(.error(e))
                            }
                        }
                    }
                } else {
                    // HTTP status error
                    completion(.error(FHIRClientError.errorResponse(
                                        status: Int(response.status.code),
                                        message: "\(resourceName) with ID \(id) not found (\(response.status.reasonPhrase))")))
                }
            }
        }
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
