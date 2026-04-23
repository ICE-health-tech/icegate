import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
    override func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let flutterViewController = window?.rootViewController as! FlutterViewController
        
        // Register custom plugins directly to the active view controller's registry
        ScreenTimePlugin.register(with: flutterViewController.registrar(forPlugin: "ScreenTimePlugin")!)
        
        super.scene(scene, willConnectTo: session, options: connectionOptions)
        // --- PASSKEY FIX (Nuclear) ---
        // We call this AFTER super.scene to ensure Flutter has initialized the window.
        // makeKeyAndVisible() is what populates UIApplication.shared.keyWindow
        window?.makeKeyAndVisible()
        
        // Synchronize with AppDelegate for legacy plugin support
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.window = self.window
        }
    }
}
