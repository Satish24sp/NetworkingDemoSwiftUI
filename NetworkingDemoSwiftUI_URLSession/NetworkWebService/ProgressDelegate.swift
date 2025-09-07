//
//  ProgressDelegate.swift
//  NetworkingDemoSwiftUI_URLSession
//
//  Created by Satish Thakur on 07/09/25.
//


import Foundation

// Custom delegate to track progress
class ProgressDelegate: NSObject, URLSessionTaskDelegate {
    var onProgress: ((Double) -> Void)?
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    didSendBodyData bytesSent: Int64,
                    totalBytesSent: Int64,
                    totalBytesExpectedToSend: Int64) {
        guard totalBytesExpectedToSend > 0 else { return }
        let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        DispatchQueue.main.async {
            self.onProgress?(progress)
        }
    }
}
