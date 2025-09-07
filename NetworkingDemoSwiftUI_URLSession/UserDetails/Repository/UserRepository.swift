//
//  UserRepository.swift
//  NetworkingDemoSwiftUI_URLSession
//
//  Created by Satish Thakur on 07/09/25.
//


import Foundation

protocol UserRepositoryProtocol {
    func fetchUsers(query: String?) async throws -> BaseResponseModel<[User]>
    func createUser(request: CreateUserRequest) async throws -> BaseResponseModel<User>
}

struct UserRepository: UserRepositoryProtocol {
    private let api: APIService

    public init(api: APIService = .shared) {
        self.api = api
    }

    func fetchUsers(query: String? = nil) async throws -> BaseResponseModel<[User]> {
        let endpoint = Endpoint(path: "/users", method: .GET)
        return try await api.request(endpoint, responseType: [User].self)
    }

    func createUser(request: CreateUserRequest) async throws -> BaseResponseModel<User> {
        let endpoint = Endpoint(path: "/users", method: .POST, body: request)
        return try await api.request(endpoint, responseType: User.self)
    }
}
