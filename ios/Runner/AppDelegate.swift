import Flutter
import UIKit
import FamilyControls
import ManagedSettings
import SwiftUI

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var screenTimePlugin: ScreenTimePlugin?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ScreenTimePlugin") {
      screenTimePlugin = ScreenTimePlugin(messenger: registrar.messenger())
    }
  }
}

@objc public class ScreenTimePlugin: NSObject {
  private let channel: FlutterMethodChannel
  private let store = ManagedSettingsStore()

  private let containerId = "group.art.duylong.icegate"
  private let selectionKeyPrefix = "ice_gate_selection_tokens"

  @objc public init(messenger: FlutterBinaryMessenger) {
    self.channel = FlutterMethodChannel(
      name: "duylong.art/screentime",
      binaryMessenger: messenger
    )
    super.init()
    channel.setMethodCallHandler(handle)
  }

  private func storageKey(for ruleId: String?) -> String {
    guard let ruleId = ruleId, !ruleId.isEmpty else {
      return selectionKeyPrefix
    }
    return "\(selectionKeyPrefix)_\(ruleId)"
  }

  @available(iOS 16.0, *)
  private func loadSelection(for ruleId: String?) -> FamilyActivitySelection {
    guard let defaults = UserDefaults(suiteName: containerId),
          let data = defaults.data(forKey: storageKey(for: ruleId)) else {
      return FamilyActivitySelection()
    }
    do {
      return try JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    } catch {
      print("ScreenTimePlugin: Failed to decode selection for \(ruleId ?? "global"): \(error)")
      return FamilyActivitySelection()
    }
  }

  @available(iOS 16.0, *)
  private func saveSelection(_ selection: FamilyActivitySelection, for ruleId: String?) {
    guard let defaults = UserDefaults(suiteName: containerId) else { return }
    do {
      let data = try JSONEncoder().encode(selection)
      defaults.set(data, forKey: storageKey(for: ruleId))
    } catch {
      print("ScreenTimePlugin: Failed to encode selection: \(error)")
    }
  }

  @available(iOS 16.0, *)
  private func mergedSelection(ruleIds: [String], selectionJsonList: [String]) -> FamilyActivitySelection {
    var merged = FamilyActivitySelection()
    var keys = Set<String>()

    for ruleId in ruleIds where !ruleId.isEmpty {
      keys.insert(storageKey(for: ruleId))
    }

    // Legacy global key when no per-rule ids were passed.
    if keys.isEmpty {
      keys.insert(storageKey(for: nil))
    }

    guard let defaults = UserDefaults(suiteName: containerId) else { return merged }

    for key in keys {
      guard let data = defaults.data(forKey: key),
            let sel = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
        continue
      }
      merged.applicationTokens.formUnion(sel.applicationTokens)
      merged.categoryTokens.formUnion(sel.categoryTokens)
    }

    return merged
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestAuthorization":
      requestAuthorization(result: result)
    case "checkAuthorization":
      checkAuthorization(result: result)
    case "showAppPicker":
      let args = call.arguments as? [String: Any]
      let ruleId = args?["ruleId"] as? String
      showAppPicker(ruleId: ruleId, result: result)
    case "getSelection":
      getSelection(result: result)
    case "hasRuleSelection":
      let args = call.arguments as? [String: Any]
      let ruleId = args?["ruleId"] as? String
      hasRuleSelection(ruleId: ruleId, result: result)
    case "setSelection":
      result(true)
    case "toggleShield":
      let args = call.arguments as? [String: Any]
      let active = args?["active"] as? Bool ?? false
      let ruleIds = args?["ruleIds"] as? [String] ?? []
      let selections = args?["selections"] as? [String] ?? []
      toggleShield(active: active, ruleIds: ruleIds, selections: selections, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func requestAuthorization(result: @escaping FlutterResult) {
    if #available(iOS 16.0, *) {
      if AuthorizationCenter.shared.authorizationStatus == .approved {
        result(true)
        return
      }
      Task {
        do {
          try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
          result(AuthorizationCenter.shared.authorizationStatus == .approved)
        } catch {
          result(
            FlutterError(
              code: "AUTH_FAILED",
              message: "Failed to request screen time auth: \(error.localizedDescription)",
              details: nil
            )
          )
        }
      }
    } else {
      result(
        FlutterError(code: "UNSUPPORTED", message: "iOS 16+ required", details: nil)
      )
    }
  }

  private func checkAuthorization(result: @escaping FlutterResult) {
    if #available(iOS 16.0, *) {
      result(AuthorizationCenter.shared.authorizationStatus == .approved)
    } else {
      result(false)
    }
  }

  private func showAppPicker(ruleId: String?, result: @escaping FlutterResult) {
    guard #available(iOS 16.0, *) else {
      result(FlutterError(code: "UNSUPPORTED", message: "iOS 16+ required", details: nil))
      return
    }

    guard AuthorizationCenter.shared.authorizationStatus == .approved else {
      result(
        FlutterError(
          code: "AUTH_REQUIRED",
          message: "Screen Time permission required before selecting apps",
          details: nil
        )
      )
      return
    }

    guard let rootViewController = topViewController() else {
      result(
        FlutterError(code: "NO_ROOT_VC", message: "Root view controller not found", details: nil)
      )
      return
    }

    let initialSelection = loadSelection(for: ruleId)
    let pickerView = AppPickerView(selection: initialSelection) { newSelection in
      self.saveSelection(newSelection, for: ruleId)
      result(true)
    }

    let hostingController = UIHostingController(rootView: pickerView)
    rootViewController.present(hostingController, animated: true)
  }

  private func hasRuleSelection(ruleId: String?, result: @escaping FlutterResult) {
    if #available(iOS 16.0, *) {
      let selection = loadSelection(for: ruleId)
      result(!selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty)
    } else {
      result(false)
    }
  }

  private func getSelection(result: @escaping FlutterResult) {
    if #available(iOS 16.0, *) {
      let selection = loadSelection(for: nil)
      let hasApps = !selection.applicationTokens.isEmpty
      let hasCategories = !selection.categoryTokens.isEmpty
      result([
        "appTokens": hasApps ? ["ios_has_selection"] : [],
        "categoryTokens": hasCategories ? ["ios_has_category"] : [],
      ])
    } else {
      result(["appTokens": [], "categoryTokens": []])
    }
  }

  private func toggleShield(
    active: Bool,
    ruleIds: [String],
    selections: [String],
    result: @escaping FlutterResult
  ) {
    if #available(iOS 16.0, *) {
      if active {
        let merged = mergedSelection(ruleIds: ruleIds, selectionJsonList: selections)
        store.shield.applications =
          merged.applicationTokens.isEmpty ? nil : merged.applicationTokens
        store.shield.applicationCategories =
          merged.categoryTokens.isEmpty ? nil : .specific(merged.categoryTokens)
      } else {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
      }
      result(true)
    } else {
      result(false)
    }
  }

  private func topViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
    for scene in scenes {
      if let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
        return root.presentedViewController ?? root
      }
    }
    return nil
  }
}

@available(iOS 16.0, *)
struct AppPickerView: View {
  @State var selection: FamilyActivitySelection
  var onComplete: (FamilyActivitySelection) -> Void
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationView {
      FamilyActivityPicker(selection: $selection)
        .navigationTitle("Select Apps to Block")
        .toolbar {
          ToolbarItem(placement: .confirmationAction) {
            Button("Done") {
              onComplete(selection)
              dismiss()
            }
          }
        }
    }
  }
}
