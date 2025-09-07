//
//  User.swift
//  NetworkingDemoSwiftUI_URLSession
//
//  Created by Satish Thakur on 07/09/25.
//


import Foundation

struct User: Codable, Identifiable {
    let id: Int?
    let name: String?
    let email: String?
}

struct CreateUserRequest: Codable {
    let name: String?
    let email: String?
}
