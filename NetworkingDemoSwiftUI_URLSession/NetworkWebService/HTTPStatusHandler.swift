//
//  HTTPStatusHandler.swift
//  NetworkingDemoSwiftUI_URLSession
//
//  Created by Satish Thakur on 07/09/25.
//

import Foundation

struct HTTPStatusHandler {
    /// Checks the HTTP status code and throws the corresponding NetworkError if needed
    static func handle(_ statusCode: Int) throws {
        switch statusCode {
        case 200..<300:
            return // Success, do nothing
        case 400:
            throw NetworkError.badRequest
        case 401:
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        case 500..<600:
            throw NetworkError.serverError(statusCode)
        default:
            throw NetworkError.unhandledStatusCode(statusCode)
        }
    }
    
    /// Optional helper to check if status code is success
    public static func isSuccess(_ statusCode: Int) -> Bool {
        return (200..<300).contains(statusCode)
    }
}
