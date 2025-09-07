//
//  MockUserRepository.swift
//  NetworkingDemoSwiftUI_URLSession
//
//  Created by Satish Thakur on 07/09/25.
//


import Foundation

struct MockUserRepository: UserRepositoryProtocol {
    enum Mode { case success, error }
    var mode: Mode = .success

    var mockUsers: [User] = [
        User(id: 1, name: "Satish", email: "satish@example.com"),
        User(id: 2, name: "Thakur", email: "thakur@example.com")
    ]

    func fetchUsers(query: String? = nil) async throws -> BaseResponseModel<[User]> {
        switch mode {
        case .success:
            return BaseResponseModel(status: true, message: "Fetched successfully", data: mockUsers)
        case .error:
            return BaseResponseModel(status: false, message: "Failed to fetch users", data: nil)
        }
    }

    func createUser(request: CreateUserRequest) async throws -> BaseResponseModel<User> {
        switch mode {
        case .success:
            let newUser = User(id: Int.random(in: 100...999), name: request.name, email: request.email)
            return BaseResponseModel(status: true, message: "User created successfully", data: newUser)
        case .error:
            return BaseResponseModel(status: false, message: "Failed to create user", data: nil)
        }
    }
}
