//
//  APIService.swift
//  NetworkingDemoSwiftUI_URLSession
//
//  Created by Satish Thakur on 07/09/25.
//


import Foundation
import Security
import CryptoKit

final class APIService {
    static let shared = APIService()
    private let baseURL: String
    private let session: URLSession
    
    // MARK: - Class Initializer
    init(baseURL: String = "https://jsonplaceholder.typicode.com") {
        self.baseURL = baseURL
        if NetworkConstants.isSslEnabled {
            // SSL certificate pinning Setup
            let delegate = SSLPinningSessionDelegate(certName: "jsonplaceholder.typicode.com")
            
            // SSL Public Key Pinning Setup
            //            let pin = "BASE64_ENCODED_SHA256_PUBLIC_KEY"
            //            let delegate = PublicKeyPinningDelegate(validPublicKeyHashes: [pin])
            
            self.session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
            
        } else {
            // Standard session
            self.session = URLSession.shared
        }
    }
    
    // MARK: - Generic API Request Method
    func request<T: Decodable & Sendable>(
        _ endpoint: Endpoint,
        responseType: T.Type
    ) async throws -> BaseResponseModel<T> {
        let request = try endpoint.urlRequest(baseURL: baseURL)
        // Log Request
        NetworkDebugHelper.shared.logRequest(request)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        // Use HTTPStatusHandler
        try HTTPStatusHandler.handle(httpResponse.statusCode)
        // Log Response
        NetworkDebugHelper.shared.logResponse(data: data, response: response, error: nil)

        guard let _ = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        do {
//            // Decode BaseResponseModel<T>
//            return try JSONDecoder().decode(BaseResponseModel<T>.self, from: data)
            
            let decoder = JSONDecoder()
            
            // Try decoding BaseResponseModel<T> first
            if let wrapped = try? decoder.decode(BaseResponseModel<T>.self, from: data) {
                return wrapped
            }
            
            // If decoding failed, fallback to plain T and wrap it manually
            let plain = try decoder.decode(T.self, from: data)
            return BaseResponseModel(status: true, message: nil, data: plain)
            
        } catch let error as DecodingError {
            throw NetworkError.decodingError(error)
        } catch {
            throw NetworkError.requestFailed(error)
        }
    }
    
    // MARK: - Upload and Download File
    // Upload File
        func upload<T: Codable>(
            url: String,
            fileURL: URL,
            headers: [String: String] = [:],
            responseType: T.Type
        ) async throws -> T {
            guard let url = URL(string: url) else { throw NetworkError.invalidURL }

            var request = URLRequest(url: url)
            request.httpMethod = HTTPMethod.POST.rawValue
            headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

            do {
                let (data, response) = try await session.upload(for: request, fromFile: fileURL)
                guard let httpResponse = response as? HTTPURLResponse,
                      200..<300 ~= httpResponse.statusCode else {
                    throw NetworkError.invalidResponse
                }
                return try JSONDecoder().decode(T.self, from: data)
            } catch let error as DecodingError {
                throw NetworkError.decodingError(error)
            } catch {
                throw NetworkError.requestFailed(error)
            }
        }

        // Download File
        func download(
            url: String,
            destination: URL
        ) async throws -> URL {
            guard let url = URL(string: url) else { throw NetworkError.invalidURL }

            do {
                let (tempURL, response) = try await session.download(from: url)
                guard let httpResponse = response as? HTTPURLResponse,
                      200..<300 ~= httpResponse.statusCode else {
                    throw NetworkError.invalidResponse
                }
                let fileManager = FileManager.default
                try? fileManager.removeItem(at: destination) // remove old file if exists
                try fileManager.moveItem(at: tempURL, to: destination)
                return destination
            } catch {
                throw NetworkError.fileSaveFailed
            }
        }
    
    // MARK: - Upload Multipart without progress
    func uploadMultipart<T: Codable>(
        url: String,
        parameters: [String: String] = [:],
        files: [(data: Data, fieldName: String, fileName: String, mimeType: String)],
        headers: [String: String] = [:],
        responseType: T.Type
    ) async throws -> T {
        guard let url = URL(string: url) else { throw NetworkError.invalidURL }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.POST.rawValue
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        var body = Data()
        
        // Add parameters
        for (key, value) in parameters {
            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.appendString("\(value)\r\n")
        }
        
        // Add files
        for file in files {
            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition: form-data; name=\"\(file.fieldName)\"; filename=\"\(file.fileName)\"\r\n")
            body.appendString("Content-Type: \(file.mimeType)\r\n\r\n")
            body.append(file.data)
            body.appendString("\r\n")
        }
        
        body.appendString("--\(boundary)--\r\n")
        request.httpBody = body
        
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  200..<300 ~= httpResponse.statusCode else {
                throw NetworkError.invalidResponse
            }
            return try JSONDecoder().decode(T.self, from: data)
        } catch let error as DecodingError {
            throw NetworkError.decodingError(error)
        } catch {
            throw NetworkError.requestFailed(error)
        }
    }
    
    // MARK: - Upload Multipart with progress
    func uploadMultipartWithProgress<T: Codable>(
        url: String,
        parameters: [String: String] = [:],
        files: [(data: Data, fieldName: String, fileName: String, mimeType: String)],
        headers: [String: String] = [:],
        responseType: T.Type,
        onProgress: ((Double) -> Void)? = nil
    ) async throws -> T {
        guard let url = URL(string: url) else { throw NetworkError.invalidURL }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.POST.rawValue
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        var body = Data()
        
        // Add parameters
        for (key, value) in parameters {
            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.appendString("\(value)\r\n")
        }
        
        // Add files
        for file in files {
            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition: form-data; name=\"\(file.fieldName)\"; filename=\"\(file.fileName)\"\r\n")
            body.appendString("Content-Type: \(file.mimeType)\r\n\r\n")
            body.append(file.data)
            body.appendString("\r\n")
        }
        
        body.appendString("--\(boundary)--\r\n")
        
        let delegate = ProgressDelegate()
        delegate.onProgress = onProgress
                
        return try await withCheckedThrowingContinuation { continuation in
            let task = session.uploadTask(with: request, from: body) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: NetworkError.requestFailed(error))
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse,
                      200..<300 ~= httpResponse.statusCode,
                      let data = data else {
                    continuation.resume(throwing: NetworkError.invalidResponse)
                    return
                }
                do {
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    continuation.resume(returning: decoded)
                } catch let error as DecodingError {
                    continuation.resume(throwing: NetworkError.decodingError(error))
                } catch {
                    continuation.resume(throwing: NetworkError.requestFailed(error))
                }
            }
            task.resume()
        }
    }
    
}

// MARK: - SSL Pinning Session Delegate Via Certificate files
class SSLPinningSessionDelegate: NSObject, URLSessionDelegate {
    private let localCertData: Data?
    
    /// Initialize with certificate file name in the bundle
    init(certName: String, certType: String = "cer") {
        if let path = Bundle.main.path(forResource: certName, ofType: certType),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            self.localCertData = data
        } else {
            self.localCertData = nil
            print("⚠️ SSL Pinning: Certificate \(certName).\(certType) not found in bundle.")
        }
    }
    
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        guard let serverTrust = challenge.protectionSpace.serverTrust,
              let localCertData = localCertData else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        // Get server certificate chain (iOS 15+)
        let certChain: [SecCertificate]
        if #available(iOS 15.0, *) {
            certChain = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate] ?? []
        } else {
            var tempChain: [SecCertificate] = []
            let count = SecTrustGetCertificateCount(serverTrust)
            for i in 0..<count {
                if let cert = SecTrustGetCertificateAtIndex(serverTrust, i) {
                    tempChain.append(cert)
                }
            }
            certChain = tempChain
        }
        
        guard let serverCert = certChain.first else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        let serverCertData = SecCertificateCopyData(serverCert) as Data
        
        if serverCertData == localCertData {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            print("⚠️ SSL Pinning: Certificate mismatch")
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
    
}



// MARK: - SSL Pinning Session Delegate Via Public SHA256 Keys
class PublicKeyPinningDelegate: NSObject, URLSessionDelegate {
    private let validPublicKeyHashes: [Data] // SHA-256 hashes of trusted public keys
    
    init(validPublicKeyHashes: [String]) {
        self.validPublicKeyHashes = validPublicKeyHashes.compactMap {
            Data(base64Encoded: $0)
        }
    }
    
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Get server certificates (new API iOS 15+, fallback otherwise)
        let certificates: [SecCertificate]
        if #available(iOS 15.0, *) {
            certificates = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate] ?? []
        } else {
            let count = SecTrustGetCertificateCount(serverTrust)
            certificates = (0..<count).compactMap { SecTrustGetCertificateAtIndex(serverTrust, $0) }
        }
        
        guard let serverCertificate = certificates.first else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Extract public key
        guard let publicKey = SecCertificateCopyKey(serverCertificate) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        var error: Unmanaged<CFError>?
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Compute SHA-256 hash of the public key
        let keyHash = SHA256.hash(data: publicKeyData)
        let keyHashData = Data(keyHash)
        
        if validPublicKeyHashes.contains(keyHashData) {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
    
}


extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
