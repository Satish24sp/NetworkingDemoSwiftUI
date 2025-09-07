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

    /// Generic API request using Alamofire and BaseResponseModel
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
        
        guard let statusCode = afResponse.response?.statusCode else {
            throw NetworkError.invalidResponse
        }

        // Use HTTPStatusHandler
        try HTTPStatusHandler.handle(statusCode)

        guard let data = afResponse.data else {
            throw NetworkError.invalidResponse
        }

        // Debug pretty-print
        debugPrintResponse(data, statusCode: statusCode)

        do {
            // Decode BaseResponseModel<T>
            let baseResponse = try JSONDecoder().decode(BaseResponseModel<T>.self, from: data)
            return baseResponse
        } catch let error as DecodingError {
            throw NetworkError.decodingError(error)
        } catch {
            throw NetworkError.requestFailed(error)
        }
    }

    // MARK: - Debug Helpers
    private func debugPrintResponse(_ data: Data, statusCode: Int) {
        #if DEBUG
        print("\n---- RESPONSE ----")
        print("Status Code: \(statusCode)")
        if let json = try? JSONSerialization.jsonObject(with: data),
           let pretty = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let prettyString = String(data: pretty, encoding: .utf8) {
            print(prettyString)
        } else if let rawString = String(data: data, encoding: .utf8) {
            print(rawString)
        }
        print("---- END RESPONSE ----\n")
        #endif
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

