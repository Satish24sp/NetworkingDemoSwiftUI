//
//  UserViewModel.swift
//  NetworkingDemoSwiftUI_URLSession
//
//  Created by Satish Thakur on 07/09/25.
//


import Foundation

@MainActor
final class UserViewModel: BaseViewModel {
    private let repository: UserRepositoryProtocol
    @Published var users: [User] = []

    init(repository: UserRepositoryProtocol) {
        self.repository = repository
        super.init()
    }

    func fetchUsers(search: String? = nil) async {
        setLoading(true)
        defer { setLoading(false) }

        do {
            let response = try await repository.fetchUsers(query: search)

            if response.status {
                users = response.data ?? []
            }

            // Show dynamic message
            if let msg = response.message, !msg.isEmpty {
                showMessage(msg)
            }
        } catch {
            showMessage(error.localizedDescription)
        }
    }

    func addUser(name: String, email: String) async {
        setLoading(true)
        defer { setLoading(false) }

        do {
            let response = try await repository.createUser(request: CreateUserRequest(name: name, email: email))

            if response.status, let newUser = response.data {
                users.append(newUser)
            }

            // Show dynamic message
            if let msg = response.message, !msg.isEmpty {
                showMessage(msg)
            }
        } catch {
            showMessage(error.localizedDescription)
        }
    }
}
