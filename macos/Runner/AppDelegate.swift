import Cocoa
import FlutterMacOS
import SwiftUI

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}

// MARK: - Screen Time (macOS local blocking via process monitor)
// Note: forceTerminate() only works when App Sandbox is disabled (see entitlements).

@objc class IceGateScreenTimePlugin: NSObject, FlutterPlugin {
  private static var isRegistered = false
  private static weak var sharedInstance: IceGateScreenTimePlugin?

  private let monitor = ProcessMonitor.shared
  private weak var window: NSWindow?
  private var pickerSheetController: NSViewController?

  private let channel: FlutterMethodChannel

  init(messenger: FlutterBinaryMessenger) {
    self.channel = FlutterMethodChannel(
      name: "duylong.art/screentime",
      binaryMessenger: messenger
    )
    super.init()
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    if isRegistered { return }
    isRegistered = true

    let instance = IceGateScreenTimePlugin(messenger: registrar.messenger)
    sharedInstance = instance
    registrar.addMethodCallDelegate(instance, channel: instance.channel)
    print("IceGateScreenTimePlugin: ✅ Registered on duylong.art/screentime")
  }

  static func attachWindow(_ window: NSWindow) {
    sharedInstance?.setWindow(window)
  }

  func setWindow(_ window: NSWindow) {
    self.window = window
  }

  @objc public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    var didReply = false
    let replyOnce: (Any?) -> Void = { value in
      guard !didReply else { return }
      didReply = true
      result(value)
    }

    print("IceGateScreenTimePlugin: 📲 \(call.method)")
    switch call.method {
    case "requestAuthorization":
      replyOnce(true)
    case "checkAuthorization":
      replyOnce(true)
    case "showAppPicker":
      let args = call.arguments as? [String: Any]
      let initialJson = args?["initialSelection"] as? String
      let ruleId = args?["ruleId"] as? String
      showAppPicker(initialJson: initialJson, ruleId: ruleId, result: replyOnce)
    case "getSelection":
      getSelection(result: replyOnce)
    case "setSelection":
      let args = call.arguments as? [String: Any]
      let appTokens = args?["appTokens"] as? [String] ?? []
      setSelection(appTokens: appTokens, result: replyOnce)
    case "toggleShield":
      let args = call.arguments as? [String: Any]
      let active = args?["active"] as? Bool ?? false
      let selections = args?["selections"] as? [String] ?? []
      let ruleIds = args?["ruleIds"] as? [String] ?? []
      toggleShield(active: active, selections: selections, ruleIds: ruleIds, result: replyOnce)
    default:
      replyOnce(FlutterMethodNotImplemented)
    }
  }

  private func getSelection(result: @escaping FlutterResult) {
    result([
      "appTokens": monitor.getBlockedBundleIds(),
      "categoryTokens": [] as [String],
    ])
  }

  private func setSelection(appTokens: [String], result: @escaping FlutterResult) {
    monitor.updateBlockedList(bundleIds: appTokens)
    result(true)
  }

  private func showAppPicker(
    initialJson: String?, ruleId: String?, result: @escaping FlutterResult
  ) {
    guard let window = self.window else {
      result(FlutterError(code: "NO_WINDOW", message: "Main window missing", details: nil))
      return
    }

    guard #available(macOS 12.0, *) else {
      result(
        FlutterError(
          code: "UNSUPPORTED", message: "macOS 12.0 or newer is required", details: nil))
      return
    }

    if pickerSheetController != nil {
      result(nil)
      return
    }

    var didReply = false
    let replyOnce: (Any?) -> Void = { value in
      guard !didReply else { return }
      didReply = true
      result(value)
    }

    let dismissSheet: () -> Void = { [weak self] in
      DispatchQueue.main.async {
        guard let self = self, let sheet = self.pickerSheetController else { return }
        if let sheetWindow = sheet.view.window {
          window.endSheet(sheetWindow)
        } else if let parent = window.contentViewController {
          parent.dismiss(sheet)
        }
        self.pickerSheetController = nil
      }
    }

    let pickerView = AppPickerView(
      initialBundleIds: parseBundleIds(from: initialJson),
      onDone: { [weak self] selectedBundleIds in
        guard self?.pickerSheetController != nil else { return }
        let dict: [String: [String]] = ["applicationTokens": selectedBundleIds]
        if let data = try? JSONSerialization.data(withJSONObject: dict),
          let jsonString = String(data: data, encoding: .utf8)
        {
          replyOnce(jsonString)
        } else {
          replyOnce(
            FlutterError(code: "ENCODE_ERROR", message: "Failed to encode selection", details: nil))
        }
        dismissSheet()
      },
      onCancel: { [weak self] in
        guard self?.pickerSheetController != nil else { return }
        replyOnce(nil)
        dismissSheet()
      }
    )

    let hostingController = NSHostingController(rootView: pickerView)
    pickerSheetController = hostingController
    hostingController.view.frame = NSRect(x: 0, y: 0, width: 450, height: 600)
    window.contentViewController?.presentAsSheet(hostingController)
  }

  private func toggleShield(
    active: Bool, selections: [String], ruleIds: [String],
    result: @escaping FlutterResult
  ) {
    var allBlockedIds = Set<String>()
    for json in selections {
      allBlockedIds.formUnion(parseBundleIds(from: json))
    }

    if active {
      if allBlockedIds.isEmpty {
        result(false)
        return
      }
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
      print("IceGateScreenTimePlugin: JSON parse error: \(error)")
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
    blockedBundleIds
  }

  func updateBlockedList(bundleIds: [String]) {
    blockedBundleIds = bundleIds
    if isBlocking {
      checkAndKill()
    }
  }

  func startBlocking(bundleIds: [String]) {
    blockedBundleIds = bundleIds
    isBlocking = true
    print("ProcessMonitor: start blocking \(bundleIds.count) apps: \(bundleIds)")
    checkAndKill()

    timer?.invalidate()
    timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
      self?.checkAndKill()
    }
    if let timer = timer {
      RunLoop.main.add(timer, forMode: .common)
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
          let ok = app.forceTerminate()
          if !ok {
            print("ProcessMonitor: forceTerminate failed for \(bundleId) (sandbox?)")
          }
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
    print("ProcessMonitor: stopped")
  }

  private func checkAndKill() {
    guard isBlocking else { return }
    for app in NSWorkspace.shared.runningApplications {
      guard let bundleId = app.bundleIdentifier, blockedBundleIds.contains(bundleId) else {
        continue
      }
      if app == NSRunningApplication.current {
        continue
      }
      let ok = app.forceTerminate()
      if !ok {
        print("ProcessMonitor: could not terminate \(bundleId)")
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
  var onDone: ([String]) -> Void
  var onCancel: () -> Void

  var filteredApps: [AppDisplayInfo] {
    if searchText.isEmpty {
      return installedApps
    }
    return installedApps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
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
        Button("Cancel") { onCancel() }
          .keyboardShortcut(.cancelAction)
        Spacer()
        Button("Done") { onDone(Array(selection)) }
          .buttonStyle(.borderedProminent)
          .keyboardShortcut(.defaultAction)
      }
      .padding()
      .background(Color(NSColor.windowBackgroundColor))
    }
    .frame(width: 450, height: 600)
    .onAppear {
      selection = Set(initialBundleIds)
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
      guard let content = try? fm.contentsOfDirectory(atPath: expandedDir) else { continue }
      for item in content where item.hasSuffix(".app") {
        let fullPath = (expandedDir as NSString).appendingPathComponent(item)
        guard let bundle = Bundle(path: fullPath),
          let bundleId = bundle.bundleIdentifier
        else { continue }
        let name =
          bundle.infoDictionary?["CFBundleName"] as? String
          ?? item.replacingOccurrences(of: ".app", with: "")
        apps.append(AppDisplayInfo(name: name, bundleId: bundleId, icon: ws.icon(forFile: fullPath)))
      }
    }
    installedApps = apps.sorted { $0.name.lowercased() < $1.name.lowercased() }
  }
}

struct AppDisplayInfo {
  let name: String
  let bundleId: String
  let icon: NSImage?
}
