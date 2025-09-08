//
//  NetworkDebugHelper.swift
//  NetworkingDemoSwiftUI_URLSession
//
//  Created by Satish Thakur on 08/09/25.
//

import Foundation
import Alamofire

// MARK: - Network Debug Helper
final class NetworkDebugHelper {
    
    // MARK: Shared Instance
    static let shared = NetworkDebugHelper()
    private init() {}
    
    // MARK: JSON Pretty Printer
    private func prettyJSONString(from data: Data) -> String? {
        if let jsonObject = try? JSONSerialization.jsonObject(with: data),
           let pretty = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
           let prettyString = String(data: pretty, encoding: .utf8) {
            return prettyString
        }
        return String(data: data, encoding: .utf8)
    }
    
    private func prettyJSONString(from dict: [String: Any]) -> String? {
        if let pretty = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
           let prettyString = String(data: pretty, encoding: .utf8) {
            return prettyString
        }
        return nil
    }
    
    // MARK: - URLSession Request Logger
    func logRequest(_ request: URLRequest) {
#if DEBUG
        print("\n---- REQUEST ----")
        
        if let method = request.httpMethod {
            print("Method: \(method)")
        }
        
        if let url = request.url {
            print("URL: \(url.absoluteString)")
            
            // Pretty query params
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let queryItems = components.queryItems, !queryItems.isEmpty {
                let dict = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value ?? "") })
                if let pretty = prettyJSONString(from: dict) {
                    print("Query Params:\n\(pretty)")
                }
            }
        }
        
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            if let pretty = prettyJSONString(from: headers) {
                print("Headers:\n\(pretty)")
            }
        }
        
        if let body = request.httpBody, !body.isEmpty {
            if let pretty = prettyJSONString(from: body) {
                print("Body:\n\(pretty)")
            }
        }
        
        print("---- END REQUEST ----\n")
#endif
    }
    
    // MARK: - URLSession Response Logger
    func logResponse(data: Data?, response: URLResponse?, error: Error?) {
#if DEBUG
        print("\n---- RESPONSE ----")
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Status Code: \(httpResponse.statusCode)")
        }
        
        if let data = data, !data.isEmpty {
            if let pretty = prettyJSONString(from: data) {
                print("Body:\n\(pretty)")
            }
        } else {
            print("No Response Data")
        }
        
        if let error = error {
            print("Error: \(error)")
        }
        
        print("---- END RESPONSE ----\n")
#endif
    }
    
    // MARK: - Alamofire Request Logger
    func logAFRequest(_ request: URLRequest?) {
#if DEBUG
        guard let request = request else {
            print("⚠️ [DEBUG] Empty request")
            return
        }
        logRequest(request)
#endif
    }
    
    // MARK: - Alamofire Response Logger for `.serializingData()`
    func logAFResponse(_ response: DataResponse<Data, AFError>) {
#if DEBUG
        logResponse(data: response.data,
                    response: response.response,
                    error: response.error)
#endif
    }
    
    // MARK: - Alamofire Response Logger for `.response`
    func logAFResponse(_ response: DataResponse<Data?, AFError>) {
#if DEBUG
        logResponse(data: response.data ?? nil,
                    response: response.response,
                    error: response.error)
#endif
    }
    
}
