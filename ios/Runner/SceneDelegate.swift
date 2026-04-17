import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
    override func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let flutterViewController = window?.rootViewController as! FlutterViewController
        
        // Setup FamilyControls picker view controller
        let screenTimePlugin = ScreenTimePlugin()
        let pickerView = UIHostingController(rootView: AppPickerView(selection: screenTimePlugin.selection) { newSelection in
            screenTimePlugin.selection = newSelection
        })
        pickerView.view.isHidden = true
        flutterViewController.addChild(pickerView)
        flutterViewController.view.addSubview(pickerView.view)
        pickerView.didMove(toParent: flutterViewController)
        
        // Expose the picker view controller to the plugin
        screenTimePlugin.pickerViewController = pickerView
        
        super.scene(scene, willConnectTo: session, options: connectionOptions)
    }
}
