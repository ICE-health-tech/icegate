import Flutter
import UIKit
import FamilyControls
import ManagedSettings
import DeviceActivity
import SwiftUI

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var screenTimePlugin: ScreenTimePlugin?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    
    // Ensure the window is accessible to plugins
    if let window = self.window {
        let controller : FlutterViewController = window.rootViewController as! FlutterViewController
        screenTimePlugin = ScreenTimePlugin(messenger: controller.binaryMessenger)
    } else {
        // Fallback for SceneDelegate scenarios where window might be nil at this point
        if #available(iOS 13.0, *) {
            // Scene connection will handle this later
        }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return result
  }
}

@objc public class ScreenTimePlugin: NSObject {
    private let channel: FlutterMethodChannel
    private let store = ManagedSettingsStore()
    private var selection = FamilyActivitySelection()
    
    // Shared user defaults key for tokens
    private let containerId = "group.duylong.art.iceshield"
    private let selectionKey = "ice_gate_selection_tokens"
    
    @objc public init(messenger: FlutterBinaryMessenger) {
        self.channel = FlutterMethodChannel(name: "duylong.art/screentime", binaryMessenger: messenger)
        super.init()
        self.loadSelection()
        self.channel.setMethodCallHandler(self.handle)
    }
    
    private func loadSelection() {
        if let defaults = UserDefaults(suiteName: containerId),
           let data = defaults.data(forKey: selectionKey) {
            do {
                let decoder = JSONDecoder()
                self.selection = try decoder.decode(FamilyActivitySelection.self, from: data)
                print("ScreenTimePlugin: Loaded persistent selection")
            } catch {
                print("ScreenTimePlugin: Failed to decode selection: \(error)")
            }
        }
    }
    
    private func saveSelection() {
        if let defaults = UserDefaults(suiteName: containerId) {
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(self.selection)
                defaults.set(data, forKey: selectionKey)
                print("ScreenTimePlugin: Saved selection to persistent storage")
            } catch {
                print("ScreenTimePlugin: Failed to encode selection: \(error)")
            }
        }
    }
    
    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "requestAuthorization":
            requestAuthorization(result: result)
        case "checkAuthorization":
            checkAuthorization(result: result)
        case "showAppPicker":
            showAppPicker(result: result)
        case "toggleShield":
            let args = call.arguments as? [String: Any]
            let active = args?["active"] as? Bool ?? false
            toggleShield(active: active, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func requestAuthorization(result: @escaping FlutterResult) {
        if #available(iOS 16.0, *) {
            Task {
                do {
                    try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                    result(true)
                } catch {
                    result(FlutterError(code: "AUTH_FAILED", message: "Failed to request screen time auth: \(error.localizedDescription)", details: nil))
                }
            }
        } else {
            result(FlutterError(code: "UNSUPPORTED", message: "iOS 15+ required", details: nil))
        }
    }
    
    private func checkAuthorization(result: @escaping FlutterResult) {
        if #available(iOS 16.0, *) {
            let status = AuthorizationCenter.shared.authorizationStatus
            result(status == .approved)
        } else {
            result(false)
        }
    }
    
    private func showAppPicker(result: @escaping FlutterResult) {
        guard let rootViewController = UIApplication.shared.delegate?.window??.rootViewController else {
            result(FlutterError(code: "NO_ROOT_VC", message: "Root view controller not found", details: nil))
            return
        }
        
        if #available(iOS 16.0, *) {
            // SwiftUI view for the picker
            let pickerView = AppPickerView(selection: selection) { newSelection in
                self.selection = newSelection
                self.saveSelection()
                result(true)
            }
            
            let hostingController = UIHostingController(rootView: pickerView)
            rootViewController.present(hostingController, animated: true)
        } else {
            result(FlutterError(code: "UNSUPPORTED", message: "iOS 15+ required", details: nil))
        }
    }
    
    private func toggleShield(active: Bool, result: @escaping FlutterResult) {
        if #available(iOS 16.0, *) {
            if active {
                // Apply shielding to selected apps
                print("ScreenTimePlugin: Toggling shield ON for \(selection.applicationTokens.count) apps")
                store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
                store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
            } else {
                // Remove all shields
                print("ScreenTimePlugin: Toggling shield OFF")
                store.shield.applications = nil
                store.shield.applicationCategories = nil
            }
            result(true)
        } else {
            result(false)
        }
    }
}

@available(iOS 16.0, *)
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
    @objc var customKeyWindow: UIWindow? {
        return connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
