import Cocoa
import FlutterMacOS
import SwiftUI

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    print("AppDelegate: applicationDidFinishLaunching started")
    super.applicationDidFinishLaunching(notification)
    
    // On macOS, the registrar is obtained from the FlutterViewController
    if let controller = mainFlutterWindow?.contentViewController as? FlutterViewController {
      print("AppDelegate: Found FlutterViewController, registering IceGateScreenTimePlugin")
      IceGateScreenTimePlugin.register(with: controller.registrar(forPlugin: "IceGateScreenTimePlugin"))
    } else {
      print("AppDelegate: ❌ Could not find FlutterViewController")
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}

// MARK: - ScreenTimePlugin
// Combined into AppDelegate to resolve scope issues without Xcode access.

@objc class IceGateScreenTimePlugin: NSObject, FlutterPlugin {
  private let monitor = ProcessMonitor.shared
  private var window: NSWindow?

  private let channel: FlutterMethodChannel

  init(messenger: FlutterBinaryMessenger) {
    self.channel = FlutterMethodChannel(name: "duylong.art/screentime", binaryMessenger: messenger)
    super.init()
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = IceGateScreenTimePlugin(messenger: registrar.messenger)
    if let window = NSApplication.shared.windows.first {
      instance.setWindow(window)
    }
    registrar.addMethodCallDelegate(instance, channel: instance.channel)
    print("IceGateScreenTimePlugin: ✅ macOS Plugin Registered on channel duylong.art/screentime")
  }

  func setWindow(_ window: NSWindow) {
    self.window = window
  }

  @objc public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    print("IceGateScreenTimePlugin: 📲 Received macOS method call: \(call.method)")
    switch call.method {
    case "requestAuthorization":
      result(true)
    case "checkAuthorization":
      result(true)
    case "showAppPicker":
      let args = call.arguments as? [String: Any]
      let initialJson = args?["initialSelection"] as? String
      showAppPicker(initialJson: initialJson, result: result)
    case "getSelection":
      getSelection(result: result)
    case "setSelection":
      let args = call.arguments as? [String: Any]
      let appTokens = args?["appTokens"] as? [String] ?? []
      setSelection(appTokens: appTokens, result: result)
    case "toggleShield":
      let args = call.arguments as? [String: Any]
      let active = args?["active"] as? Bool ?? false
      let selections = args?["selections"] as? [String] ?? []
      toggleShield(active: active, selections: selections, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func getSelection(result: @escaping FlutterResult) {
    let data: [String: [String]] = [
      "appTokens": monitor.getBlockedBundleIds(),
      "categoryTokens": [],
    ]
    result(data)
  }

  private func setSelection(appTokens: [String], result: @escaping FlutterResult) {
    monitor.updateBlockedList(bundleIds: appTokens)
    result(true)
  }

  private func showAppPicker(initialJson: String?, result: @escaping FlutterResult) {
    guard let window = self.window else {
      result(FlutterError(code: "NO_WINDOW", message: "Main window logic missing", details: nil))
      return
    }

    if #available(macOS 12.0, *) {
      let pickerView = AppPickerView(initialBundleIds: parseBundleIds(from: initialJson)) {
        selectedBundleIds in
        let dict: [String: [String]] = ["applicationTokens": selectedBundleIds]
        if let data = try? JSONSerialization.data(withJSONObject: dict),
          let jsonString = String(data: data, encoding: .utf8)
        {
          result(jsonString)
        } else {
          result(
            FlutterError(code: "ENCODE_ERROR", message: "Failed to encode selection", details: nil))
        }
      }

      let hostingController = NSHostingController(rootView: pickerView)
      hostingController.view.frame = NSRect(x: 0, y: 0, width: 450, height: 600)

      window.contentViewController?.presentAsSheet(hostingController)
    } else {
      result(
        FlutterError(
          code: "UNSUPPORTED", message: "macOS 12.0 or newer is required for App Picker",
          details: nil))
    }
  }

  private func toggleShield(active: Bool, selections: [String], result: @escaping FlutterResult) {
    var allBlockedIds = Set<String>()
    for json in selections {
      allBlockedIds.formUnion(parseBundleIds(from: json))
    }

    if active {
      monitor.startBlocking(bundleIds: Array(allBlockedIds))
    } else {
      monitor.stopBlocking()
    }
    result(true)
  }

  private func parseBundleIds(from json: String?) -> [String] {
    guard let json = json, let data = json.data(using: .utf8) else { return [] }
    do {
      if let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
        if let tokens = dict["applicationTokens"] as? [String] {
          return tokens
        }
      }
    } catch {
      print("ScreenTimePlugin: Error parsing selection JSON: \(error)")
    }
    return []
  }
}

class ProcessMonitor {
  static let shared = ProcessMonitor()
  private var blockedBundleIds: [String] = []
  private var timer: Timer?
  private var isBlocking = false
  private var observation: NSObjectProtocol?

  private init() {}

  func getBlockedBundleIds() -> [String] {
    return blockedBundleIds
  }

  func updateBlockedList(bundleIds: [String]) {
    self.blockedBundleIds = bundleIds
    if isBlocking {
      checkAndKill()
    }
  }

  func startBlocking(bundleIds: [String]) {
    self.blockedBundleIds = bundleIds
    self.isBlocking = true
    checkAndKill()
    timer?.invalidate()
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      self?.checkAndKill()
    }

    if observation == nil {
      observation = NSWorkspace.shared.notificationCenter.addObserver(
        forName: NSWorkspace.didLaunchApplicationNotification,
        object: nil,
        queue: .main
      ) { [weak self] notification in
        guard let self = self, self.isBlocking else { return }
        if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
          as? NSRunningApplication,
          let bundleId = app.bundleIdentifier,
          self.blockedBundleIds.contains(bundleId)
        {
          app.forceTerminate()
        }
      }
    }
  }

  func stopBlocking() {
    isBlocking = false
    timer?.invalidate()
    timer = nil
    if let obs = observation {
      NSWorkspace.shared.notificationCenter.removeObserver(obs)
      observation = nil
    }
  }

  private func checkAndKill() {
    guard isBlocking else { return }
    let runningApps = NSWorkspace.shared.runningApplications
    for app in runningApps {
      if let bundleId = app.bundleIdentifier, blockedBundleIds.contains(bundleId) {
        app.forceTerminate()
      }
    }
  }
}

@available(macOS 12.0, *)
struct AppPickerView: View {
  @State private var installedApps: [AppDisplayInfo] = []
  @State private var selection: Set<String> = []
  @State private var searchText: String = ""

  var initialBundleIds: [String]
  var onComplete: ([String]) -> Void
  @Environment(\.presentationMode) var presentationMode

  var filteredApps: [AppDisplayInfo] {
    if searchText.isEmpty {
      return installedApps
    } else {
      return installedApps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      VStack(spacing: 8) {
        Text("Select Apps to Block")
          .font(.headline)
        Text("Selected: \(selection.count)")
          .font(.subheadline)
          .foregroundColor(.secondary)
      }
      .padding()

      HStack {
        Image(systemName: "magnifyingglass")
          .foregroundColor(.secondary)
        TextField("Search Apps...", text: $searchText)
          .textFieldStyle(.plain)
      }
      .padding(8)
      .background(Color(NSColor.controlBackgroundColor))
      .cornerRadius(8)
      .padding(.horizontal)
      .padding(.bottom, 8)

      List(filteredApps, id: \.bundleId) { app in
        HStack {
          if let icon = app.icon {
            Image(nsImage: icon)
              .resizable()
              .frame(width: 24, height: 24)
          } else {
            Image(systemName: "app.fill")
              .resizable()
              .frame(width: 24, height: 24)
              .foregroundColor(.gray)
          }

          VStack(alignment: .leading) {
            Text(app.name)
              .font(.body)
            Text(app.bundleId)
              .font(.caption)
              .foregroundColor(.secondary)
          }

          Spacer()

          Toggle(
            "",
            isOn: Binding(
              get: { selection.contains(app.bundleId) },
              set: { isSet in
                if isSet {
                  selection.insert(app.bundleId)
                } else {
                  selection.remove(app.bundleId)
                }
              }
            )
          )
          .toggleStyle(.checkbox)
        }
        .padding(.vertical, 4)
      }
      .listStyle(.inset)

      HStack {
        Button("Cancel") {
          presentationMode.wrappedValue.dismiss()
        }
        .keyboardShortcut(.cancelAction)

        Spacer()

        Button("Done") {
          onComplete(Array(selection))
          presentationMode.wrappedValue.dismiss()
        }
        .buttonStyle(.borderedProminent)
        .keyboardShortcut(.defaultAction)
      }
      .padding()
      .background(Color(NSColor.windowBackgroundColor))
    }
    .frame(width: 450, height: 600)
    .onAppear {
      self.selection = Set(initialBundleIds)
      loadInstalledApps()
    }
  }

  private func loadInstalledApps() {
    let appDirs = ["/Applications", "/System/Applications", "~/Applications"]
    var apps: [AppDisplayInfo] = []
    let fm = FileManager.default
    let ws = NSWorkspace.shared

    for dir in appDirs {
      let expandedDir = (dir as NSString).expandingTildeInPath
      do {
        let content = try fm.contentsOfDirectory(atPath: expandedDir)
        for item in content where item.hasSuffix(".app") {
          let fullPath = (expandedDir as NSString).appendingPathComponent(item)
          if let bundle = Bundle(path: fullPath),
            let bundleId = bundle.bundleIdentifier
          {
            let name =
              bundle.infoDictionary?["CFBundleName"] as? String
              ?? item.replacingOccurrences(of: ".app", with: "")
            let icon = ws.icon(forFile: fullPath)
            apps.append(AppDisplayInfo(name: name, bundleId: bundleId, icon: icon))
          }
        }
      } catch {
        print("ScreenTimePlugin: Error reading \(dir): \(error)")
      }
    }
    self.installedApps = apps.sorted { $0.name.lowercased() < $1.name.lowercased() }
  }
}

struct AppDisplayInfo {
  let name: String
  let bundleId: String
  let icon: NSImage?
}
