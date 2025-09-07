//
//  BaseResponseModel.swift
//  NetworkingDemoSwiftUI_URLSession
//
//  Created by Satish Thakur on 07/09/25.
//


import Foundation

/// Generic response wrapper for APIs
public struct BaseResponseModel<T: Decodable & Sendable>: Decodable, Sendable {
    public let status: Bool
    public let message: String?
    public let data: T?

    public init(status: Bool, message: String?, data: T?) {
        self.status = status
        self.message = message
        self.data = data
    }
}

/*
 Here T is Sendable
 T can now be:
 T = { }        // single object
 T = [ ]        // array
 T = String     // raw string message
 T = Int/Bool   // numeric or flag responses
 */
