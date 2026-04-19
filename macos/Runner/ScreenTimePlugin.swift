import Cocoa
import FlutterMacOS
import SwiftUI

class ScreenTimePlugin: NSObject {
    private let monitor = ProcessMonitor.shared
    private var window: NSWindow?
    
    func setWindow(_ window: NSWindow) {
        self.window = window
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "requestAuthorization":
            // macOS standard apps don't need the same "Screen Time" auth as iOS for basic killing
            // But they do need "Accessibility" or just "Sandbox" permissions.
            // For now, return true since we have the entitlement.
            result(true)
        case "checkAuthorization":
            result(true)
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

    private func showAppPicker(initialJson: String?, result: @escaping FlutterResult) {
        guard let window = self.window else {
            result(FlutterError(code: "NO_WINDOW", message: "Main window logic missing", details: nil))
            return
        }

        if #available(macOS 12.0, *) {
            let pickerView = AppPickerView(initialBundleIds: parseBundleIds(from: initialJson)) { selectedBundleIds in
                // Encode back to a format SocialBlockerBlock expects.
                let dict: [String: [String]] = ["applicationTokens": selectedBundleIds]
                if let data = try? JSONSerialization.data(withJSONObject: dict),
                   let jsonString = String(data: data, encoding: .utf8) {
                    result(jsonString)
                } else {
                    result(FlutterError(code: "ENCODE_ERROR", message: "Failed to encode selection", details: nil))
                }
            }
            
            let hostingController = NSHostingController(rootView: pickerView)
            hostingController.view.frame = NSRect(x: 0, y: 0, width: 450, height: 600)
            
            window.contentViewController?.presentAsSheet(hostingController)
        } else {
            result(FlutterError(code: "UNSUPPORTED", message: "macOS 12.0 or newer is required for App Picker", details: nil))
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
                // Check for iOS-style 'applicationTokens' which might contain bundle IDs or tokens
                // In our macOS implementation, we'll store/retrieve bundle IDs here.
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

// MARK: - Process Monitor

class ProcessMonitor {
    static let shared = ProcessMonitor()
    private var blockedBundleIds: [String] = []
    private var timer: Timer?
    private var isBlocking = false
    
    private init() {}
    
    func startBlocking(bundleIds: [String]) {
        self.blockedBundleIds = bundleIds
        self.isBlocking = true
        
        // Check immediately
        checkAndKill()
        
        // Start timer
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkAndKill()
        }
    }
    
    func stopBlocking() {
        isBlocking = false
        timer?.invalidate()
        timer = nil
    }
    
    private func checkAndKill() {
        guard isBlocking else { return }
        
        let runningApps = NSWorkspace.shared.runningApplications
        for app in runningApps {
            if let bundleId = app.bundleIdentifier, blockedBundleIds.contains(bundleId) {
                print("ScreenTimePlugin: Blocking active app: \(bundleId)")
                app.terminate() // Graceful termination
                // If it persists, could use app.forceTerminate()
            }
        }
    }
}

// MARK: - App Picker UI

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
            header
            
            searchBar
            
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
                    
                    Toggle("", isOn: Binding(
                        get: { selection.contains(app.bundleId) },
                        set: { isSet in
                            if isSet {
                                selection.insert(app.bundleId)
                            } else {
                                selection.remove(app.bundleId)
                            }
                        }
                    ))
                    .toggleStyle(.checkbox)
                }
                .padding(.vertical, 4)
            }
            .listStyle(.inset)
            
            footer
        }
        .frame(width: 450, height: 600)
        .onAppear {
            self.selection = Set(initialBundleIds)
            loadInstalledApps()
        }
    }
    
    private var header: some View {
        VStack(spacing: 8) {
            Text("Select Apps to Block")
                .font(.headline)
            Text("Selected: \(selection.count)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private var searchBar: some View {
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
    }
    
    private var footer: some View {
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
                       let bundleId = bundle.bundleIdentifier {
                        let name = bundle.infoDictionary?["CFBundleName"] as? String ?? item.replacingOccurrences(of: ".app", with: "")
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
