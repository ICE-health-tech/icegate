import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    IceGateScreenTimePlugin.register(
      with: flutterViewController.registrar(forPlugin: "IceGateScreenTimePlugin")
    )
    IceGateScreenTimePlugin.attachWindow(self)

    super.awakeFromNib()
  }
}
