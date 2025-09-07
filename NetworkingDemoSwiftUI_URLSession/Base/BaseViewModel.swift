//
//  BaseViewModel.swift
//  NetworkingDemoSwiftUI_URLSession
//
//  Created by Satish Thakur on 07/09/25.
//


import SwiftUI

class BaseViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var alertMessage: String? = nil
    @Published var showAlert: Bool = false

    func setLoading(_ loading: Bool) {
        DispatchQueue.main.async { self.isLoading = loading }
    }

    func showMessage(_ message: String) {
        DispatchQueue.main.async {
            self.alertMessage = message
            self.showAlert = true
        }
    }
}
