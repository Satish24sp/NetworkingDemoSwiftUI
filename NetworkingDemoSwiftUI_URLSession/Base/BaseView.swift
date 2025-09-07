//
//  BaseView.swift
//  NetworkingDemoSwiftUI_URLSession
//
//  Created by Satish Thakur on 07/09/25.
//


import SwiftUI

struct BaseView<Content: View, VM: BaseViewModel>: View {
    @ObservedObject var viewModel: VM
    let content: () -> Content

    init(viewModel: VM, @ViewBuilder content: @escaping () -> Content) {
        self.viewModel = viewModel
        self.content = content
    }

    var body: some View {
        ZStack {
            content()
                .alert(isPresented: $viewModel.showAlert) {
                    Alert(
                        title: Text("Message"),
                        message: Text(viewModel.alertMessage ?? ""),
                        dismissButton: .default(Text("OK"))
                    )
                }

            if viewModel.isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView("Loading...")
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .shadow(radius: 5)
                    )
            }
        }
    }
}
