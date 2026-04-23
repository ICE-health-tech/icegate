import Flutter
import UIKit
import FamilyControls
import ManagedSettings
import DeviceActivity
import SwiftUI

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    
    // Register custom Screen Time plugin
    ScreenTimePlugin.register(with: self.registrar(forPlugin: "ScreenTimePlugin")!)
    
    GeneratedPluginRegistrant.register(with: self)
    return result
  }
}

// MARK: - ScreenTimePlugin Implementation
// This is moved here because the separate ScreenTimePlugin.swift was not correctly linked in the Xcode project.
@objc public class ScreenTimePlugin: NSObject, FlutterPlugin {
    private var channel: FlutterMethodChannel?
    private lazy var store: ManagedSettingsStore = {
        if #available(iOS 16.0, *) {
            return ManagedSettingsStore(named: .init(containerId))
        } else {
            return ManagedSettingsStore()
        }
    }()
    
    // Shared user defaults key for tokens
    private let containerId = "group.duylong.art.icegate"
    private let selectionKey = "ice_gate_selection_tokens"
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "duylong.art/screentime", binaryMessenger: registrar.messenger())
        let instance = ScreenTimePlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "requestAuthorization":
            requestAuthorization(result: result)
        case "checkAuthorization":
            checkAuthorization(result: result)
        case "showAppPicker":
            let args = call.arguments as? [String: Any]
            let initialJson = args?["initialSelection"] as? String
            showAppPicker(initialJson: initialJson, result: result)
        case "toggleShield":
            let args = call.arguments as? [String: Any]
            let active = args?["active"] as? Bool ?? false
            let selectionJsons = args?["selections"] as? [String] ?? []
            toggleShield(active: active, selections: selectionJsons, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func requestAuthorization(result: @escaping FlutterResult) {
        if #available(iOS 15.0, *) {
            let status = AuthorizationCenter.shared.authorizationStatus
            if status == .approved {
                print("ScreenTimePlugin: Already approved")
                result(true)
                return
            }
            
            Task { @MainActor in
                do {
                    print("ScreenTimePlugin: Requesting authorization...")
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                    
                    if #available(iOS 16.0, *) {
                        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                    } else {
                        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                            AuthorizationCenter.shared.requestAuthorization { authResult in
                                switch authResult {
                                case .success: continuation.resume()
                                case .failure(let error): continuation.resume(throwing: error)
                                }
                            }
                        }
                    }
                    
                    let finalStatus = AuthorizationCenter.shared.authorizationStatus
                    print("ScreenTimePlugin: Auth request completed. Status: \(finalStatus)")
                    if finalStatus == .approved {
                        result(true)
                    } else if finalStatus == .denied {
                        result(FlutterError(code: "AUTH_DENIED", message: "Authorization denied. Please enable in Settings.", details: nil))
                    } else {
                        result(false)
                    }
                } catch {
                    print("ScreenTimePlugin: Auth request failed: \(error)")
                    result(FlutterError(code: "AUTH_FAILED", message: error.localizedDescription, details: nil))
                }
            }
        } else {
            result(FlutterError(code: "UNSUPPORTED", message: "iOS 15+ required", details: nil))
        }
    }
    
    private func checkAuthorization(result: @escaping FlutterResult) {
        if #available(iOS 15.0, *) {
            let status = AuthorizationCenter.shared.authorizationStatus
            result(status == .approved)
        } else {
            result(false)
        }
    }
    
    private func showAppPicker(initialJson: String?, result: @escaping FlutterResult) {
        guard let rootViewController = UIApplication.shared.customKeyWindow?.rootViewController else {
            result(FlutterError(code: "NO_ROOT_VC", message: "Root view controller not found", details: nil))
            return
        }
        
        if #available(iOS 15.0, *) {
            var initialSelection = FamilyActivitySelection()
            if let json = initialJson, let data = json.data(using: .utf8) {
                if let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
                    initialSelection = decoded
                }
            }
            
            let pickerView = AppPickerView(selection: initialSelection) { newSelection in
                if let data = try? JSONEncoder().encode(newSelection),
                   let jsonString = String(data: data, encoding: .utf8) {
                    result(jsonString)
                } else {
                    result(FlutterError(code: "ENCODE_ERROR", message: "Failed to encode selection", details: nil))
                }
            }
            
            let hostingController = UIHostingController(rootView: pickerView)
            rootViewController.present(hostingController, animated: true)
        } else {
            result(FlutterError(code: "UNSUPPORTED", message: "iOS 15+ required", details: nil))
        }
    }
    
    private func toggleShield(active: Bool, selections: [String], result: @escaping FlutterResult) {
        if #available(iOS 15.0, *) {
            if active {
                var mergedSelection = FamilyActivitySelection()
                for json in selections {
                    if let data = json.data(using: .utf8),
                       let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
                        mergedSelection.applicationTokens.formUnion(decoded.applicationTokens)
                        mergedSelection.categoryTokens.formUnion(decoded.categoryTokens)
                        mergedSelection.webDomainTokens.formUnion(decoded.webDomainTokens)
                    }
                }
                
                print("ScreenTimePlugin: Shielding \(mergedSelection.applicationTokens.count) apps")
                store.shield.applications = mergedSelection.applicationTokens.isEmpty ? nil : mergedSelection.applicationTokens
                store.shield.applicationCategories = mergedSelection.categoryTokens.isEmpty ? nil : .specific(mergedSelection.categoryTokens)
                store.shield.webDomains = mergedSelection.webDomainTokens.isEmpty ? nil : mergedSelection.webDomainTokens
            } else {
                print("ScreenTimePlugin: Clearing all shields")
                store.shield.applications = nil
                store.shield.applicationCategories = nil
                store.shield.webDomains = nil
            }
            result(true)
        } else {
            result(false)
        }
    }
}

@available(iOS 15.0, *)
struct AppPickerView: View {
    @State var selection: FamilyActivitySelection
    var onComplete: (FamilyActivitySelection) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                FamilyActivityPicker(selection: $selection)
            }
            .navigationTitle("Select Apps to Block")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onComplete(selection)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

@available(iOS 13.0, *)
extension UIApplication {
    var customKeyWindow: UIWindow? {
        return connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
