//
//  Extension+JSONDecoder.swift
//  NetworkingDemoSwiftUI_URLSession
//
//  Created by Satish Thakur on 08/09/25.
//

import Foundation

extension JSONDecoder {
    func decodeResponse<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        // Try decoding BaseResponseModel<T>
        if let wrapped = try? self.decode(BaseResponseModel<T>.self, from: data) {
            if let result = wrapped.data {
                return result
            } else {
                throw DecodingError.dataCorrupted(.init(codingPath: [],
                    debugDescription: "No data in BaseResponseModel"))
            }
        }
        // Fallback: decode plain T
        return try self.decode(T.self, from: data)
    }
}
