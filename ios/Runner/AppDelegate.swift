import DeviceActivity
import FamilyControls
import Flutter
import ManagedSettings
import SwiftUI
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Register custom plugin using the standard registrar
    if let registrar = self.registrar(forPlugin: "IceGateScreenTimePlugin") {
      IceGateScreenTimePlugin.register(with: registrar)
    }

    // On-device image captioning (FoundationModels, iOS 26 + A17 Pro/M-series).
    if let registrar = self.registrar(forPlugin: "OnDeviceCaptionPlugin") {
      OnDeviceCaptionPlugin.register(with: registrar)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

// MARK: - ScreenTimePlugin

@objc public class IceGateScreenTimePlugin: NSObject, FlutterPlugin {
  @objc public static let shared = IceGateScreenTimePlugin()
  private var channel: FlutterMethodChannel?
  private let store: ManagedSettingsStore = {
    if #available(iOS 16.0, *) {
      return ManagedSettingsStore(named: .init("group.art.duylong.icegate"))
    } else {
      return ManagedSettingsStore()
    }
  }()
  private var selection = FamilyActivitySelection()

  private let containerId = "group.art.duylong.icegate"
  private let appTokensKey = "ice_gate_app_tokens"
  private let categoryTokensKey = "ice_gate_category_tokens"

  private override init() {
    super.init()
    self.loadSelection()
  }

  @objc public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = IceGateScreenTimePlugin.shared
    instance.channel = FlutterMethodChannel(
      name: "duylong.art/screentime", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: instance.channel!)
    print("IceGateScreenTimePlugin: ✅ Plugin Registered on channel duylong.art/screentime")
  }

  private func loadSelection() {
    if let defaults = UserDefaults(suiteName: containerId) {
      if let appTokensData = defaults.data(forKey: appTokensKey),
        let appTokens = try? JSONDecoder().decode([String].self, from: appTokensData)
      {
        selection.applicationTokens = Set(appTokens.compactMap { ApplicationToken(from: $0) })
      }
      if let categoryTokensData = defaults.data(forKey: categoryTokensKey),
        let categoryTokens = try? JSONDecoder().decode([String].self, from: categoryTokensData)
      {
        selection.categoryTokens = Set(
          categoryTokens.compactMap { ActivityCategoryToken(from: $0) })
      }
      print(
        "ScreenTimePlugin: Loaded selection - Apps: \(selection.applicationTokens.count), Categories: \(selection.categoryTokens.count)"
      )
    }
  }

  private func saveSelection() {
    if let defaults = UserDefaults(suiteName: containerId) {
      let appTokens = selection.applicationTokens.compactMap { $0.encodeToString() }
      if let appTokensData = try? JSONEncoder().encode(appTokens) {
        defaults.set(appTokensData, forKey: appTokensKey)
      }

      let categoryTokens = selection.categoryTokens.compactMap { $0.encodeToString() }
      if let categoryTokensData = try? JSONEncoder().encode(categoryTokens) {
        defaults.set(categoryTokensData, forKey: categoryTokensKey)
      }
      print(
        "ScreenTimePlugin: Saved selection - Apps: \(appTokens.count), Categories: \(categoryTokens.count)"
      )
    }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    print("ScreenTimePlugin: 📲 Received method call: \(call.method)")
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
    case "getSelection":
      getSelection(result: result)
    case "setSelection":
      let args = call.arguments as? [String: Any]
      let appTokens = args?["appTokens"] as? [String] ?? []
      let categoryTokens = args?["categoryTokens"] as? [String] ?? []
      setSelection(appTokens: appTokens, categoryTokens: categoryTokens, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func requestAuthorization(result: @escaping FlutterResult) {
    if #available(iOS 15.0, *) {
      print("ScreenTimePlugin: 🔑 Requesting FamilyControls authorization (Main Thread)...")
      
      // Ensure we are on the main thread for UI/System requests
      DispatchQueue.main.async {
        Task {
          do {
            if #available(iOS 16.0, *) {
              print("ScreenTimePlugin: Trying iOS 16+ .individual authorization")
              do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                print("ScreenTimePlugin: .individual authorization success")
                result(true)
              } catch {
                print("ScreenTimePlugin: .individual failed, trying legacy fallback: \(error.localizedDescription)")
                // Fallback to legacy request
                AuthorizationCenter.shared.requestAuthorization { fallbackResult in
                  switch fallbackResult {
                  case .success:
                    print("ScreenTimePlugin: Fallback authorization success")
                    result(true)
                  case .failure(let fallbackError):
                    print("ScreenTimePlugin: All auth methods failed: \(fallbackError.localizedDescription)")
                    result(FlutterError(code: "AUTH_FAILED", message: fallbackError.localizedDescription, details: nil))
                  }
                }
              }
            } else {
              print("ScreenTimePlugin: Using iOS 15 callback authorization")
              AuthorizationCenter.shared.requestAuthorization { authResult in
                switch authResult {
                case .success: 
                  print("ScreenTimePlugin: Authorization success")
                  result(true)
                case .failure(let error):
                  print("ScreenTimePlugin: Authorization failed: \(error.localizedDescription)")
                  result(FlutterError(code: "AUTH_FAILED", message: error.localizedDescription, details: nil))
                }
              }
            }
          } catch {
            print("ScreenTimePlugin: Authorization catch error: \(error.localizedDescription)")
            result(FlutterError(code: "AUTH_FAILED", message: error.localizedDescription, details: nil))
          }
        }
      }
    } else {
      result(FlutterError(code: "UNSUPPORTED", message: "iOS 15+ required", details: nil))
    }
  }

  private func checkAuthorization(result: @escaping FlutterResult) {
    if #available(iOS 15.0, *) {
      result(AuthorizationCenter.shared.authorizationStatus == .approved)
    } else {
      result(false)
    }
  }

  private func showAppPicker(result: @escaping FlutterResult) {
    var rootViewController: UIViewController?
    if #available(iOS 13.0, *) {
      if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
        let window = windowScene.windows.first(where: { $0.isKeyWindow })
      {
        rootViewController = window.rootViewController
      }
    }
    if rootViewController == nil {
      rootViewController = UIApplication.shared.delegate?.window??.rootViewController
    }

    guard let finalRootVC = rootViewController else {
      result(
        FlutterError(code: "NO_ROOT_VC", message: "Root view controller not found", details: nil))
      return
    }

    if #available(iOS 15.0, *) {
      let pickerView = AppPickerView(selection: selection) { newSelection in
        self.selection = newSelection
        self.saveSelection()

        print(
          "ScreenTimePlugin: Raw Selection - Apps: \(newSelection.applicationTokens.count), Categories: \(newSelection.categoryTokens.count)"
        )

        let appTokens = newSelection.applicationTokens.compactMap { $0.encodeToString() }
        let categoryTokens = newSelection.categoryTokens.compactMap { $0.encodeToString() }

        print(
          "ScreenTimePlugin: Serialized - Apps: \(appTokens.count), Categories: \(categoryTokens.count)"
        )

        let dict = ["applicationTokens": appTokens, "categoryTokens": categoryTokens]
        if let data = try? JSONSerialization.data(withJSONObject: dict),
          let jsonString = String(data: data, encoding: .utf8)
        {
          result(jsonString)
        } else {
          result(true)
        }
      }
      let hostingController = UIHostingController(rootView: pickerView)
      finalRootVC.present(hostingController, animated: true)
    } else {
      result(FlutterError(code: "UNSUPPORTED", message: "iOS 15+ required", details: nil))
    }
  }

  private func toggleShield(active: Bool, result: @escaping FlutterResult) {
    if #available(iOS 15.0, *) {
      if active {
        print(
          "ScreenTimePlugin: Enabling Shield. Apps: \(selection.applicationTokens.count), Categories: \(selection.categoryTokens.count)"
        )
        store.shield.applications =
          selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories =
          selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
      } else {
        print("ScreenTimePlugin: Disabling Shield")
        store.shield.applications = nil
        store.shield.applicationCategories = nil
      }
      result(true)
    } else {
      result(false)
    }
  }

  private func getSelection(result: @escaping FlutterResult) {
    let appTokens = selection.applicationTokens.compactMap { $0.encodeToString() }
    let categoryTokens = selection.categoryTokens.compactMap { $0.encodeToString() }
    print(
      "ScreenTimePlugin: Returning Selection. Apps: \(appTokens.count), Categories: \(categoryTokens.count)"
    )
    result(["appTokens": appTokens, "categoryTokens": categoryTokens])
  }

  private func setSelection(
    appTokens: [String], categoryTokens: [String], result: @escaping FlutterResult
  ) {
    if #available(iOS 15.0, *) {
      selection.applicationTokens = Set(appTokens.compactMap { ApplicationToken(from: $0) })
      selection.categoryTokens = Set(categoryTokens.compactMap { ActivityCategoryToken(from: $0) })
      saveSelection()
      result(true)
    } else {
      result(false)
    }
  }
}

// MARK: - AppPickerView

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

// MARK: - Token Extensions

@available(iOS 15.0, *)
extension ApplicationToken {
  func encodeToString() -> String? {
    return try? JSONEncoder().encode(self).base64EncodedString()
  }
  init?(from string: String) {
    guard let data = Data(base64Encoded: string),
      let token = try? JSONDecoder().decode(ApplicationToken.self, from: data)
    else { return nil }

    print("ScreenTimePlugin: Decoded token: \(token)")
    self = token
  }
}

@available(iOS 15.0, *)
extension ActivityCategoryToken {
  func encodeToString() -> String? {
    return try? JSONEncoder().encode(self).base64EncodedString()
  }
  init?(from string: String) {
    guard let data = Data(base64Encoded: string),
      let token = try? JSONDecoder().decode(ActivityCategoryToken.self, from: data)
    else { return nil }
    self = token
  }
}

@available(iOS 13.0, *)
extension UIApplication {
  var customKeyWindow: UIWindow? {
    return
      connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
  }
}
