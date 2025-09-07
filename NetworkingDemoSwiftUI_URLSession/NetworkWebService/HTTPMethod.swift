//
//  HTTPMethod.swift
//  NetworkingDemoSwiftUI_URLSession
//
//  Created by Satish Thakur on 07/09/25.
//

import Foundation
import Alamofire

enum HTTPMethod: String {
    case GET, POST, PUT, DELETE
}

struct Endpoint {
    let path: String
    let method: HTTPMethod
    var queryItems: [URLQueryItem]? = nil
    var body: Encodable? = nil
    var headers: [String: String]? = nil
    
    init(
        path: String,
        method: HTTPMethod,
        queryItems: [URLQueryItem]? = nil,
        body: Encodable? = nil,
        headers: [String: String]? = nil
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.body = body
        self.headers = headers
    }
    
    // MARK: - URLSession Support
    func urlRequest(baseURL: String) throws -> URLRequest {
        guard var components = URLComponents(string: baseURL + path) else {
            throw NetworkError.invalidURL
        }
        components.queryItems = queryItems
        guard let url = components.url else { throw NetworkError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // Add headers
        if let headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Add body
        if let body {
            request.httpBody = try JSONEncoder().encode(body)
            if request.value(forHTTPHeaderField: "Content-Type") == nil {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        }
        
        return request
    }
    
    // MARK: - Alamofire Support
    var queryParameters: [String: Any]? {
        guard let queryItems = queryItems else { return nil }
        var dict = [String: Any]()
        queryItems.forEach { dict[$0.name] = $0.value }
        return dict
    }
    
    var afMethod: Alamofire.HTTPMethod {
        switch method {
        case .GET: return .get
        case .POST: return .post
        case .PUT: return .put
        case .DELETE: return .delete
        }
    }
    
    var afHeaders: Alamofire.HTTPHeaders? {
        guard let headers = headers else { return nil }
        return HTTPHeaders(headers)
    }
}
