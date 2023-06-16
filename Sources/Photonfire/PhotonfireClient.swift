//
//  File.swift
//
//
//  Created by Photon Juniper on 2023/6/16.
//

import Foundation

public enum PhotonfireError: Error {
    case parameterError(_ message: String = "")
    case apiError(_ message: String = "")
}

public class PhotonfireClient {
    // TODO Could have used macros to generate the builder.
    public class Builder {
        public var baseURL: URL
        public var session: URLSession
        public var defaultHeaders: [String: String] = [:]
        
        public init(baseURL: URL, session: URLSession = .shared) {
            self.baseURL = baseURL
            self.session = session
        }
        
        public func defaultHeaders(headers: [String:String]) -> PhotonfireClient.Builder {
            headers.forEach { (k, v) in
                self.defaultHeaders[k] = v
            }
            return self
        }
        
        public func build() -> PhotonfireClient {
            return PhotonfireClient(
                baseURL: baseURL,
                session: session,
                headers: defaultHeaders
            )
        }
    }
    
    public let baseURL: URL
    public let session: URLSession
    public let defaultHeaders: [String: String]
    
    public lazy var jsonDecoder: JSONDecoder = {
        return JSONDecoder()
    }()
        
    private init(
        baseURL: URL,
        session: URLSession,
        headers: [String:String]
    ) {
        self.baseURL = baseURL
        self.session = session
        self.defaultHeaders = headers
    }
    
    public func createService<T: PhotonfireServiceProtocol>(of type: T.Type) -> T {
        return type.createInstance(client: self) as! T
    }
}

public protocol PhotonfireServiceProtocol: AnyObject {
    associatedtype ClassType = Self
    static func createInstance(client: PhotonfireClient) -> ClassType
}
