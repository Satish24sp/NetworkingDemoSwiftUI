//
//  NetworkError.swift
//  NetworkingDemoSwiftUI_URLSession
//
//  Created by Satish Thakur on 07/09/25.
//


import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingError(Error)
    
    // Status code based errors
    case badRequest
    case unauthorized
    case forbidden
    case notFound
    case serverError(Int)
    case unhandledStatusCode(Int)

    case fileSaveFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: 
            return "Invalid URL"
        case .requestFailed(let err): 
            return "Request failed: \(err.localizedDescription)"
        case .invalidResponse: 
            return "Invalid response from server"
        case .serverError(let code): 
            return "Server error: \(code)"
        case .decodingError(let err): 
            return "Decoding error: \(err.localizedDescription)"
        case .badRequest:
            return "Bad request"
        case .unauthorized:
            return "Unauthorized access"
        case .forbidden:
            return "Request forbidden"
        case .notFound:
            return "Request not found"
        case .unhandledStatusCode(let code):
            return "Unhandled Status Code: \(code)"
        case .fileSaveFailed:
            return "File save failed"
        }
    }
}
