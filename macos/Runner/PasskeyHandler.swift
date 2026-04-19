import FlutterMacOS
import Foundation
import AuthenticationServices

@available(macOS 12.0, *)
class PasskeyHandler: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var result: FlutterResult?
    private var window: NSWindow?
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult, window: NSWindow?) {
        self.result = result
        self.window = window
        
        switch call.method {
        case "isSupported":
            result(true)
        case "createCredential":
            createCredential(jsonString: call.arguments as! String)
        case "getCredential":
            getCredential(jsonString: call.arguments as! String)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func createCredential(jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
              let options = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            result?(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid JSON options", details: nil))
            return
        }
        
        let rpId = (options["rp"] as? [String: Any])?["id"] as? String ?? "passkey.duylong.art"
        let userName = (options["user"] as? [String: Any])?["name"] as? String ?? ""
        let userDisplayName = (options["user"] as? [String: Any])?["displayName"] as? String ?? userName
        let userIdString = (options["user"] as? [String: Any])?["id"] as? String ?? ""
        let userId = Data(base64Encoded: userIdString) ?? Data(userIdString.utf8)
        let challengeString = options["challenge"] as? String ?? ""
        let challenge = Data(base64Encoded: challengeString) ?? Data(challengeString.utf8)
        
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpId)
        let request = provider.createCredentialRegistrationRequest(challenge: challenge, name: userName, userID: userId)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    private func getCredential(jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
              let options = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            result?(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid JSON options", details: nil))
            return
        }
        
        let rpId = options["rpId"] as? String ?? "passkey.duylong.art"
        let challengeString = options["challenge"] as? String ?? ""
        let challenge = Data(base64Encoded: challengeString) ?? Data(challengeString.utf8)
        
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpId)
        let request = provider.createCredentialAssertionRequest(challenge: challenge)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    // MARK: - ASAuthorizationControllerDelegate
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialRegistration {
            let response: [String: Any] = [
                "id": credential.credentialID.base64EncodedString(),
                "rawId": credential.credentialID.base64EncodedString(),
                "type": "public-key",
                "response": [
                    "attestationObject": credential.rawAttestationObject?.base64EncodedString() ?? "",
                    "clientDataJSON": credential.rawClientDataJSON.base64EncodedString()
                ]
            ]
            if let json = try? JSONSerialization.data(withJSONObject: response),
               let jsonString = String(data: json, encoding: .utf8) {
                result?(jsonString)
            } else {
                result?(FlutterError(code: "SERIALIZATION_ERROR", message: "Failed to serialize registration response", details: nil))
            }
        } else if let credential = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion {
            let response: [String: Any] = [
                "id": credential.credentialID.base64EncodedString(),
                "rawId": credential.credentialID.base64EncodedString(),
                "type": "public-key",
                "response": [
                    "authenticatorData": credential.rawAuthenticatorData.base64EncodedString(),
                    "clientDataJSON": credential.rawClientDataJSON.base64EncodedString(),
                    "signature": credential.signature.base64EncodedString(),
                    "userHandle": credential.userID.base64EncodedString()
                ]
            ]
            if let json = try? JSONSerialization.data(withJSONObject: response),
               let jsonString = String(data: json, encoding: .utf8) {
                result?(jsonString)
            } else {
                result?(FlutterError(code: "SERIALIZATION_ERROR", message: "Failed to serialize assertion response", details: nil))
            }
        } else {
            result?(FlutterError(code: "UNKNOWN_CREDENTIAL", message: "Unknown credential type received", details: nil))
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let authError = error as NSError
        if authError.domain == ASAuthorizationErrorDomain {
            switch authError.code {
            case ASAuthorizationError.canceled.rawValue:
                result?(FlutterError(code: "CANCELED", message: "User canceled the authorization", details: nil))
            default:
                result?(FlutterError(code: "AUTH_ERROR", message: error.localizedDescription, details: authError.code))
            }
        } else {
            result?(FlutterError(code: "ERROR", message: error.localizedDescription, details: nil))
        }
    }
    
    // MARK: - ASAuthorizationControllerPresentationContextProviding
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return window ?? NSApplication.shared.keyWindow ?? NSWindow()
    }
}
