//
//  ContentView.swift
//  NetworkingDemoSwiftUI_URLSession
//
//  Created by Satish Thakur on 07/09/25.
//


import SwiftUI

struct ContentView: View {
    @StateObject private var vm: UserViewModel

    init(repository: UserRepositoryProtocol = UserRepository()) {
        _vm = StateObject(wrappedValue: UserViewModel(repository: repository))
    }

    var body: some View {
        BaseView(viewModel: vm) {
            NavigationView {
                VStack {
                    HStack {
                        Button("Fetch Users") {
                            Task { await vm.fetchUsers() }
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Add User") {
                            Task { await vm.addUser(name: "Satish", email: "satish@example.com") }
                        }
                        .buttonStyle(.bordered)
                    }

                    List(vm.users) { user in
                        VStack(alignment: .leading) {
                            Text(user.name ?? "").font(.headline)
                            Text(user.email ?? "").font(.subheadline).foregroundColor(.gray)
                        }
                    }
                }
                .navigationTitle("Users")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView(repository: MockUserRepository(mode: .success))
                .previewDisplayName("✅ Success")

            ContentView(repository: MockUserRepository(mode: .error))
                .previewDisplayName("❌ Error")

            BaseView(viewModel: {
                let vm = UserViewModel(repository: MockUserRepository())
                vm.isLoading = true
                return vm
            }()) {
                Text("⏳ Loading State")
            }
            .previewDisplayName("⏳ Loading")
        }
    }
}
