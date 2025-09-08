//
//  APIServiceAlamofire.swift
//  NetworkingDemoSwiftUI_URLSession
//
//  Created by Satish Thakur on 07/09/25.
//


import Alamofire
import Foundation
import CryptoKit

final class APIServiceAlamofire {
    static let shared = APIServiceAlamofire()
    private let baseURL: String
    private let session: Session
    
    init(baseURL: String = "https://jsonplaceholder.typicode.com") {
        self.baseURL = baseURL
        
        if NetworkConstants.isSslEnabled {
            // Attempt SSL certificate pinning
            if let certPath = Bundle.main.path(forResource: "myserver", ofType: "cer"),
               let localCertData = try? Data(contentsOf: URL(fileURLWithPath: certPath)),
               let certificate = SecCertificateCreateWithData(nil, localCertData as CFData) {
                
                let serverTrustManager = ServerTrustManager(
                    evaluators: [
                        "api.myserver.com": PinnedCertificatesTrustEvaluator(
                            certificates: [certificate],
                            acceptSelfSignedCertificates: false,
                            performDefaultValidation: true,
                            validateHost: true
                        )
                    ]
                )
                
                /*
                 /// Use suitable option:
                 /// Option 1: SSL Public Key pinning via Alamofire’s Built-in PublicKeysTrustEvaluator
                 let evaluators: [String: ServerTrustEvaluating] = [
                 "api.myserver.com": PublicKeysTrustEvaluator(
                 performDefaultValidation: true,
                 validateHost: true
                 )
                 ]
                 let serverTrustManager = ServerTrustManager(evaluators: evaluators)
                 
                 /// Option 2: SSL Public Key pinning via SHA-256 Public Key Hashes (Custom Evaluator)
                 let publicKeyHash = "BASE64_ENCODED_SHA256_PUBLIC_KEY"
                 
                 let evaluators: [String: ServerTrustEvaluating] = [
                 "api.myserver.com": PublicKeyHashTrustEvaluator(validBase64Hashes: [publicKeyHash])
                 ]
                 
                 let serverTrustManager = ServerTrustManager(evaluators: evaluators)
                 */
                
                self.session = Session(serverTrustManager: serverTrustManager)
                
            } else {
                // Certificate missing or invalid, fallback to default session
                print("⚠️ SSL pinning certificate missing or invalid. Using default session.")
                self.session = Session.default
            }
        } else {
            // Standard session if SSL not enabled
            self.session = Session.default
        }
    }
    
    // MARK: - Generic API Request Method
    func request<T: Decodable & Sendable>(
        _ endpoint: Endpoint,
        responseType: T.Type
    ) async throws -> BaseResponseModel<T> {
        let url = baseURL + endpoint.path
        
        // Prepare parameters for body or query
        let parameters: [String: Any]?
        if let body = endpoint.body {
            let data = try JSONEncoder().encode(body)
            parameters = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        } else {
            parameters = endpoint.queryParameters
        }
        
        let encoding: ParameterEncoding = endpoint.method == .GET ? URLEncoding.default : JSONEncoding.default
        
        // Alamofire request
        let afResponse = await session.request(
            url,
            method: endpoint.afMethod,
            parameters: parameters,
            encoding: encoding,
            headers: endpoint.afHeaders
        ).serializingData().response

        guard let statusCode = afResponse.response?.statusCode else {
            throw NetworkError.invalidResponse
        }
        
        // Use HTTPStatusHandler
        try HTTPStatusHandler.handle(statusCode)
        
        guard let data = afResponse.data else {
            throw NetworkError.invalidResponse
        }
        
        // Log Request
        NetworkDebugHelper.shared.logAFRequest(afResponse.request)
        // Log Response
        NetworkDebugHelper.shared.logAFResponse(afResponse)
        
        do {
//            // Decode BaseResponseModel<T>
//            let baseResponse = try JSONDecoder().decode(BaseResponseModel<T>.self, from: data)
//            return baseResponse
            
            let decoder = JSONDecoder()
            
            // Try decoding BaseResponseModel<T>
            if let wrapped = try? decoder.decode(BaseResponseModel<T>.self, from: data) {
                return wrapped
            }
            
            // Otherwise decode raw T and wrap
            let plain = try decoder.decode(T.self, from: data)
            return BaseResponseModel(status: true, message: nil, data: plain)
            
        } catch let error as DecodingError {
            throw NetworkError.decodingError(error)
        } catch {
            throw NetworkError.requestFailed(error)
        }
    }
    
    // Upload File
    func upload<T: Codable>(
        url: String,
        fileURL: URL,
        headers: [String: String] = [:],
        responseType: T.Type
    ) async throws -> T {
        guard let url = URL(string: url) else { throw NetworkError.invalidURL }
        
        let afHeaders = HTTPHeaders(headers)
        
        return try await withCheckedThrowingContinuation { continuation in
            session.upload(fileURL, to: url, method: .post, headers: afHeaders)
                .validate(statusCode: 200..<300)
                .responseDecodable(of: T.self) { response in
                    switch response.result {
                    case .success(let decoded):
                        continuation.resume(returning: decoded)
                    case .failure(let afError):
                        if let underlying = afError.underlyingError {
                            continuation.resume(throwing: NetworkError.requestFailed(underlying))
                        } else if let decodingError = afError.asAFError?.underlyingError as? DecodingError {
                            continuation.resume(throwing: NetworkError.decodingError(decodingError))
                        } else {
                            continuation.resume(throwing: NetworkError.invalidResponse)
                        }
                    }
                }
        }
    }
    
    // Download File
    func download(
        url: String,
        destination: URL
    ) async throws -> URL {
        guard let url = URL(string: url) else { throw NetworkError.invalidURL }
        
        let destinationClosure: DownloadRequest.Destination = { _, _ in
            (destination, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            session.download(url, to: destinationClosure)
                .validate(statusCode: 200..<300)
                .response { response in
                    switch response.result {
                    case .success:
                        if let fileURL = response.fileURL {
                            continuation.resume(returning: fileURL)
                        } else {
                            continuation.resume(throwing: NetworkError.fileSaveFailed)
                        }
                    case .failure:
                        continuation.resume(throwing: NetworkError.invalidResponse)
                    }
                }
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
        
        let afHeaders = HTTPHeaders(headers)
        
        return try await withCheckedThrowingContinuation { continuation in
            session.upload(multipartFormData: { formData in
                // Add parameters
                for (key, value) in parameters {
                    formData.append(Data(value.utf8), withName: key)
                }
                // Add files
                for file in files {
                    formData.append(file.data,
                                    withName: file.fieldName,
                                    fileName: file.fileName,
                                    mimeType: file.mimeType)
                }
            }, to: url, method: .post, headers: afHeaders)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let decoded):
                    continuation.resume(returning: decoded)
                case .failure(let afError):
                    if let underlying = afError.underlyingError {
                        continuation.resume(throwing: NetworkError.requestFailed(underlying))
                    } else if let decodingError = afError.asAFError?.underlyingError as? DecodingError {
                        continuation.resume(throwing: NetworkError.decodingError(decodingError))
                    } else {
                        continuation.resume(throwing: NetworkError.invalidResponse)
                    }
                }
            }
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
        
        let afHeaders = HTTPHeaders(headers)
        
        return try await withCheckedThrowingContinuation { continuation in
            session.upload(multipartFormData: { formData in
                // Add parameters
                for (key, value) in parameters {
                    formData.append(Data(value.utf8), withName: key)
                }
                // Add files
                for file in files {
                    formData.append(file.data,
                                    withName: file.fieldName,
                                    fileName: file.fileName,
                                    mimeType: file.mimeType)
                }
            }, to: url, method: .post, headers: afHeaders)
            .uploadProgress { progress in
                onProgress?(progress.fractionCompleted)
            }
            .validate(statusCode: 200..<300)
            .responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let decoded):
                    continuation.resume(returning: decoded)
                case .failure(let afError):
                    if let underlying = afError.underlyingError {
                        continuation.resume(throwing: NetworkError.requestFailed(underlying))
                    } else if let decodingError = afError.asAFError?.underlyingError as? DecodingError {
                        continuation.resume(throwing: NetworkError.decodingError(decodingError))
                    } else {
                        continuation.resume(throwing: NetworkError.invalidResponse)
                    }
                }
            }
        }
    }
    
}


// MARK: Support SHA-256 Public Key Hashes (Custom Evaluator)
struct PublicKeyHashTrustEvaluator: ServerTrustEvaluating {
    private let validKeyHashes: [Data]
    
    init(validBase64Hashes: [String]) {
        self.validKeyHashes = validBase64Hashes.compactMap { Data(base64Encoded: $0) }
    }
    
    func evaluate(_ trust: SecTrust, forHost host: String) throws {
        let certificates: [SecCertificate]
        if #available(iOS 15.0, *) {
            certificates = SecTrustCopyCertificateChain(trust) as? [SecCertificate] ?? []
        } else {
            let count = SecTrustGetCertificateCount(trust)
            certificates = (0..<count).compactMap { SecTrustGetCertificateAtIndex(trust, $0) }
        }
        
        guard let certificate = certificates.first,
              let publicKey = SecCertificateCopyKey(certificate) else {
            throw AFError.serverTrustEvaluationFailed(reason: .noCertificatesFound)
        }
        
        var error: Unmanaged<CFError>?
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
            throw AFError.serverTrustEvaluationFailed(reason: .noPublicKeysFound)
        }
        
        let hash = SHA256.hash(data: publicKeyData)
        let hashData = Data(hash)
        
        guard validKeyHashes.contains(hashData) else {
            throw AFError.serverTrustEvaluationFailed(reason: .noPublicKeysFound)
        }
    }
}
