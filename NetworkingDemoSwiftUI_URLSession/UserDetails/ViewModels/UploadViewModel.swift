//
//  UploadViewModel.swift
//  NetworkingDemoSwiftUI_URLSession
//
//  Created by Satish Thakur on 07/09/25.
//

import SwiftUI

@MainActor
class UploadViewModel: ObservableObject {
    @Published var responseMessage: String?

    func uploadProfileImage(image: UIImage, userId: String) async {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }

        do {
            let response: UploadResponse = try await APIService.shared.uploadMultipart(
                url: "https://api.myserver.com/upload",
                parameters: ["userId": userId],
                files: [(data: imageData, fieldName: "profilePic", fileName: "avatar.jpg", mimeType: "image/jpeg")],
                responseType: UploadResponse.self
            )
            responseMessage = response.message
        } catch {
            responseMessage = "Upload failed: \(error.localizedDescription)"
        }
    }
    
    func uploadProfileImageWithProgress(image: UIImage, userId: String) async {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        Task {
            do {
                let result: UploadResponse = try await APIService.shared.uploadMultipartWithProgress(
                    url: "https://api.myserver.com/upload",
                    parameters: ["userId": "123"],
                    files: [(data: imageData,
                             fieldName: "file",
                             fileName: "photo.jpg",
                             mimeType: "image/jpeg")],
                    headers: ["Authorization": "Bearer token"],
                    responseType: UploadResponse.self
                ) { progress in
                    print("Upload progress: \(progress * 100)%")
                }
                print("Upload successful:", result)
            } catch {
                print("Upload failed:", error)
            }
        }
        
    }
    
    
}


struct UploadResponse: Codable {
    let success: Bool
    let message: String
    let imageUrl: String?
}


///How to Call UploadProfileImage
/// await vm.uploadProfileImage(image: img, userId: "123")
