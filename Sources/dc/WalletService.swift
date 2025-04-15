//
// Copyright contributors to the IBM Verify Digital Credentials SDK for iOS project
//

import Foundation
import Authentication
import Core

// MARK: Protocols

/// An interface for providing information about the outcome of an authorization code flow request initiated via the browser.
@MainActor
public protocol WalletServiceDelegate: AnyObject {
    /// Tells the delegate when credential was accepted.
    /// - Parameters:
    ///   - service: The wallet service that performed the credential operation.
    ///   - credential: An encapsulation of the accepted credential.
    func walletService(service: WalletService, didAcceptCredential credential: Credential)
    
    /// Tells the delegate the credential was verified.
    /// - Parameters:
    ///   - service: The wallet service that performed the credential operation.
    ///   - verification: The credential verification information.
    func walletService(service: WalletService, didVerifyCredential verification: VerificationInfo)
    
    /// Tells the delegate that the credential proof has been generated.
    /// - Parameters:
    ///   - service: The wallet service that performed the credential operation.
    ///   - verification: The credential verification information prior to being verified.
    func walletService(service: WalletService, didGenerateProof verification: VerificationInfo)
}

/// An inerface that defines a wallet service operations.
public protocol WalletServiceDescriptor {
    /// The access token generated by the authorization server.
    var accessToken: String { get set }
    
    /// The location of the endpoint to refresh the OAuth token for the wallet.
    var refreshUri: URL { get }

    /// The location of the endpoint to perform digital credential operaions..
    var baseUri: URL { get }
    
    /// The unique identifier between the service and the client app.
    var clientId: String { get }
    
    /// A delegate that the wallet service informs about the success of credential operations.
    var delegate: (any WalletServiceDelegate)? { get set }

    /// A closure providing headers for requests.
    var headers: () -> [String: String] { get set }

    /// Refresh the OAuth token associated with the registered wallet.
    /// - Parameters:
    ///   - refreshToken: The refresh token of the existing wallet registration.
    ///   - accountName: The account name associated with the service.
    ///   - pushToken: A token that identifies the device to Apple Push Notification Service (APNS).
    /// - Returns: A new `TokenInfo` for the wallet.
    ///
    /// Communicate with Apple Push Notification service (APNs) and receive a unique device token that identifies your app.  Refer to [Registering Your App with APNs](https://developer.apple.com/documentation/usernotifications/registering_your_app_with_apns).
    func refreshToken(using refreshToken: String, accountName: String?, pushToken: String?) async throws -> TokenInfo
    
    // MARK: Invitations
    
    /// Gets an array of outstanding invitations.
    /// - Returns: An array of ``InvitationInfo``.
    func retrieveInvitations() async throws -> [InvitationInfo]
    
    /// Process an invitation received by the wallet.
    /// - Parameters:
    ///   - offerUrl: The originating URL typically encoded in a QR code.
    /// - Returns: A new ``PreviewDescriptor``.
    func previewInvitation(using offerUrl: URL) async throws -> (any PreviewDescriptor)
   
    // MARK: Proof Requests
    
    /// Gets an array of outstanding proof requests.
    /// - Parameters:
    ///   - state: The ``VerificationState`` to filter by.  Default`passed`.
    /// - Returns: An array of ``VerificationInfo``.
    func retrieveProofRequests(filter state: VerificationState) async throws -> [VerificationInfo]
    
    /// Process a proof request from the wallet.
    /// - Parameters:
    ///   - preview: The preview of type ``VerificationPreviewInfo``.
    ///   - action: The status to be assigned to the proof request.
    func processProofRequest(with preview: VerificationPreviewInfo, action: VerificationAction) async throws
    
    // MARK: Credentials
    
    /// Gets an array of accepted credentials.
    /// - Parameters:
    ///   - state: The ``CredentialState``.  Default `stored`.
    /// - Returns: An array of ``Credential``.
    func retrieveCredentials(filter state: CredentialState) async throws -> [Credential]
    
    /// Gets a credential by its identifier
    /// - Parameters:
    ///   - identifier: The unique identifier of a credential.
    /// - Returns: An instance of  ``Credential`` or `nil` where no credential is retrieved.
    func retrieveCredential(with identifier: String) async throws -> Credential?
    
    /// Process a credential for the wallet.
    /// - Parameters:
    ///   - preview: An instance of the ``CredentialPreviewInfo``.
    ///   - action: The action to perform for the credential offer.
    func processCredential(with preview: CredentialPreviewInfo, action: CredentialAction) async throws
    
    /// Deletes a credential.
    /// - Parameters:
    ///   - identifier: The unique identifier of a credential.
    func deleteCredential(with identifier: String) async throws
}

/// The `WalletService` enables device wallets to perform operations to process invitations for proof request and credentials.
public class WalletService: WalletServiceDescriptor {
    public weak var delegate: (any WalletServiceDelegate)?
    public var accessToken: String
    nonisolated public let refreshUri: URL
    nonisolated public let baseUri: URL
    nonisolated public let clientId: String
    nonisolated public var headers: () -> [String: String]?
    
    /// An object that coordinates a group of related, network data transfer tasks.
    private let urlSession: URLSession
    
    /// Creates the service with the access token and related endpoint URI's.
    /// - Parameters:
    ///   - accessToken: The access token generated by the authorization server.
    ///   - refreshUri: The location of the endpoint to refresh the OAuth token for the wallet.
    ///   - baseUri: The location of the endpoint to perform digital credential operatons.
    ///   - clientId: The unique identifier between the service and the client app.
    ///   - certificateTrust: A delegate to handle session-level certificate pinning.
    ///   - headers: A closure that returns headers for requests.
    public init(token accessToken: String, refreshUri: URL, baseUri: URL, clientId: String, certificateTrust: URLSessionDelegate? = nil, headers: (() -> [String: String])? = nil) {
        self.accessToken = accessToken
        self.refreshUri = refreshUri
        self.baseUri = baseUri
        self.clientId = clientId
        self.headers = headers ?? { ["Authorization": "Bearer \(accessToken)"] }

        if let certificateTrust = certificateTrust {
            self.urlSession = URLSession(configuration: .default, delegate: certificateTrust, delegateQueue: nil)
        } else {
            self.urlSession = URLSession.shared
        }
    }
    
    // MARK: Token Refresh
    
    public func refreshToken(using refreshToken: String, accountName: String? = nil, pushToken: String? = nil) async throws -> TokenInfo {
        // Add additional data to obtain the Token.
        var additionalParameters: [String: Any] = [:]
        if let pushToken = pushToken {
            additionalParameters.updateValue(pushToken, forKey: "pushToken")
        }
        
        if let accountName = accountName {
            additionalParameters.updateValue(accountName, forKey: "accountName")
        }
        
        // Get a new OAuth token from refresh and update device details.
        let oauthProvider = OAuthProvider(clientId: clientId, additionalParameters: additionalParameters, certificateTrust: self.urlSession.delegate)
        let result = try await oauthProvider.refresh(issuer: self.refreshUri, refreshToken: refreshToken)
             
        // Update the internal accessToken and return
        self.accessToken = result.accessToken
             
        return result
    }
    
    // MARK: Invitations
    
    public func retrieveInvitations() async throws -> [InvitationInfo] {
        // Resource for obtaining invitation, this requires a custom parser to only decode the items JSON array.
        let resource = HTTPResource<[InvitationInfo]>(.get, url: self.baseUri.appendingPathComponent("invitations"), headers: self.headers()) { data, response in
            // Create a JSONDecoder for custom parsing.
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            
            guard let data = data, !data.isEmpty else {
                return .failure(WalletError.dataInitializationFailed)
            }
                
            guard let invitations = try? decoder.decode(type: [InvitationInfo].self, from: data) else {
                return .failure(WalletError.failedToParse)
            }

            return .success(invitations)
        }
        
        return try await self.urlSession.dataTask(for: resource)
    }
    
    public func previewInvitation(using offerUrl: URL) async throws -> (any PreviewDescriptor) {
        do {
            let data = try await processInvitation(using: offerUrl)
        
            // Create a JSONDecoder for custom parsing.
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .millisecondsSince1970
            
            /// Decode the invitation processor response.
//            guard let info = try? decoder.decode(RootInvitation.self, from: data) else {
//         //   guard let info = try? decoder.decode(RootInvitation.self, from: data) else {
//                throw WalletError.failedToParse
//            }
            
            let stubInvitation = InvitationPreviewInfo(
                           id: "604fc1b5-f0e6-4d0e-9fab-a42ad8136560",
                           url: URL(string: "https://dcvsms917-ap4.csda.gov.au:9720/diagency/a2a/v1/messages/e68870ea-c817-43e6-955e-1ce1d98a10a9/invitation?id=604fc1b5-f0e6-4d0e-9fab-a42ad8136560")!,
                           label: "issuer_1",
                           comment: "This is a test invitation",
                           type: .invitation,
                           formats: ["didcomm/aip2;env=rfc19"],
                           jsonRepresentation: nil // or Data("{}".utf8) if needed
                       )
            print("✅ SUCCESS INVITATION: \(stubInvitation.label)")

            
//            /// Determine what type of invitation to return.
//            switch info.type {
//            case .offerCredential:
//                return CredentialPreviewInfo(using: info)
//            case .requestPresentation:
//                return VerificationPreviewInfo(using: info)
//            }
            return CredentialPreviewInfo(id: stubInvitation.id, url: stubInvitation.url, label: stubInvitation.label, comment: stubInvitation.label, jsonRepresentation: nil, documentTypes: [""])
            
        //    return CredentialPreviewInfo(id: info.invitation.id, url: info.invitation.url, label: info.invitation.label, comment: info.invitation.label, jsonRepresentation: nil, documentTypes: [""])
        }
        catch let error {
            throw error
        }
    }
    
    /// Process an invitation received by the wallet.
    /// - Parameters:
    ///   - offerUrl: The originating URL typically encoded in a QR code.
    ///   - forPreview: A flag to process the invitation as a preview.
    /// - Returns: The `Data` returned from the service.
    @discardableResult private func processInvitation(using offerUrl: URL, forPreview: Bool = true) async throws -> Data {
        // Resource for processing the invitation and managing the response.
        let url = URL(string: "\(self.baseUri.absoluteString)/invitation_processor")!
        
        // Create the parameters for the request body.
        let body = """
        {
            "url":"\(offerUrl)",
            "inspect": \(forPreview)
        }
        """.data(using: .utf8)!
        
        let resource = HTTPResource<Data>(.put, url: url, accept: .json, contentType: .json, body: body, headers: self.headers()) { data, response in
            guard let data, !data.isEmpty else {
                return .failure(WalletError.dataInitializationFailed)
            }
            
            return .success(data)
        }
        
        return try await urlSession.dataTask(for: resource)
    }
    
    // MARK: Proof Requests (Verifications)
    
    public func retrieveProofRequests(filter state: VerificationState = .passed) async throws -> [VerificationInfo] {
        // Resource for obtaining proof request, this requires a custom parser to only decode the items JSON array.
        let url = URL(string: "\(self.baseUri.absoluteString)/verifications?state=\(state.rawValue)")!
        let resource = HTTPResource<[VerificationInfo]>(.get, url: url, headers: self.headers()) { data, response in
            // Create a JSONDecoder for custom parsing.
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            
            guard let data, !data.isEmpty else {
                return .failure(WalletError.dataInitializationFailed)
            }
                
            guard let verifications = try? decoder.decode(type: [VerificationInfo].self, from: data) else {
                return .failure(WalletError.failedToParse)
            }

            return .success(verifications)
        }
        
        return try await self.urlSession.dataTask(for: resource)
    }
    
    /// Process the response to a proof request.
    /// - Parameters:
    ///   - id: The identifier for the verification.
    ///   - state: A flag to process the verification state.
    /// - Returns: The `Data` returned from the service.
    @discardableResult private func processProofRequest(using id: String, state: VerificationState = .proofGenerated) async throws -> Data {
        // Construct the URL for the verification endpoint.
        let url = URL(string: "\(self.baseUri.absoluteString)/verifications/\(id)")!
        
        // Create the parameters for the credential body.
        let body = """
        {
            "state": "\(state.rawValue)"
        }
        """.data(using: .utf8)!
        
        let resource = HTTPResource<Data>(.patch, url: url, accept: .json, contentType: .json, body: body, headers: self.headers()) { data, response in
            guard let data, !data.isEmpty else {
                return .failure(WalletError.dataInitializationFailed)
            }
            
            return .success(data)
        }
        
        return try await urlSession.dataTask(for: resource)
    }
    
    public func processProofRequest(with preview: VerificationPreviewInfo, action: VerificationAction = .generate) async throws {
        do {
            switch action {
            case .reject:
                // Accept the invitation so that we can act on it.
                try await processInvitation(using: preview.url, forPreview: false)
                
                // Delete the proof request.
                try await processProofRequest(using: preview.id, state: .deleted)
            case .generate:
                // Accept the invitation so that we can act on it.
                try await processInvitation(using: preview.url, forPreview: false)
                
                // Set the verification to "generate" state.
                let data = try await processProofRequest(using: preview.id)
                
                // Parse the verification data.
                let result = try JSONDecoder().decode(VerificationInfo.self, from: data)
                
                // Fire the delegate with the verification info.
                await delegate?.walletService(service: self, didGenerateProof: result)
            case .share:
                // Next, set the verification to "shared" state.
                let data = try await processProofRequest(using: preview.id, state: .proofShared)
                
                // Parse the verification data.
                let result = try JSONDecoder().decode(VerificationInfo.self, from: data)
                
                // Fire the delegate with the verification info.
                await delegate?.walletService(service: self, didVerifyCredential: result)
            }
        }
        catch URLSessionError.invalidResponse(_, let description) {
            throw WalletError.verificationFailed(message: description)
        }
         catch let error {
             throw error
        }
    }
    
    // MARK: Credentials
    
    public func retrieveCredentials(filter state: CredentialState = .stored) async throws -> [Credential] {
        // Construct the URL with a filter on credential state.
        let url = URL(string: "\(self.baseUri.absoluteString)/credentials?filter={\"state\":\"\(state.rawValue)\"}")!
        
        // Resource for obtaining credentials, this requires a custom parser to only decode the items JSON array.
        let resource = HTTPResource<[Credential]>(.get, url: url, headers: self.headers()) { data, response in
            // Create a JSONDecoder for custom parsing.
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            
            guard let data = data, !data.isEmpty else {
                return .failure(WalletError.dataInitializationFailed)
            }
              
            // Ensure that the parsing of a collection of credentials will pass.
            guard let credentials = try? decoder.decode(type: [Credential].self, from: data) else {
                return .failure(WalletError.failedToParse)
            }
            
            // Map the collection from a Credential to CredentialDescriptpr.
            return .success(credentials)
        }
        
        return try await self.urlSession.dataTask(for: resource)
    }
    
    public func retrieveCredential(with identifier: String) async throws -> Credential? {
        // Construct the URL with a filter on credential state.
        let url = URL(string: "\(self.baseUri.absoluteString)/credentials/\(identifier)")!
        
        // Resource for obtaining credentials..
        let resource = HTTPResource<Credential>(json: .get, url: url, headers: self.headers())
        
        return try await self.urlSession.dataTask(for: resource)
    }
    
    public func processCredential(with preview: CredentialPreviewInfo, action: CredentialAction = .accepted) async throws {
        // Construct the URL for the credential endpoint.
        let url = URL(string: "\(self.baseUri.absoluteString)/credentials/\(preview.id)")!
        
        try await processInvitation(using: preview.url, forPreview: false)
        
        // Create the parameters for the credential body.
        let body = """
        {
            "state": "\(action.rawValue)"
        }
        """.data(using: .utf8)!
        
        // Resource for obtaining credentials, this requires a custom parser to only decode the items JSON array.
        let resource = HTTPResource<Credential?>(.patch, url: url, accept: .json, contentType: .json, body: body, headers: self.headers()) { data, response in
            // Create a JSONDecoder for custom parsing.
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .millisecondsSince1970
            
            guard let data = data, !data.isEmpty else {
                return .failure(WalletError.dataInitializationFailed)
            }
            
            if action == .rejected {
                return .success(nil)
            }
            
            // Esnure that the parsing of a collection of credentials will pass.
            guard let credential = try? decoder.decode(Credential.self, from: data) else {
                return .failure(WalletError.failedToParse)
            }
            
            // Map the collection from a Credential to CredentialDescriptpr.
            return .success(credential)
        }
        
        // A nil result suggests the credential was rejected.
        guard let result = try await self.urlSession.dataTask(for: resource) else {
            return
        }
        
        await self.delegate?.walletService(service: self, didAcceptCredential: result)
    }
    
    public func deleteCredential(with identifier: String) async throws {
        let resource = HTTPResource(.delete, url: self.baseUri.appendingPathComponent("credentials/\(identifier)"), headers: self.headers())
        return try await self.urlSession.dataTask(for: resource)
    }
}
 
