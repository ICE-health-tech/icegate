import Flutter
import Foundation
import UIKit

// FoundationModels (on-device Apple Intelligence) requires iOS 26 and an
// A17 Pro / M-series device. It is imported with @_weakLink so the app still
// launches on iOS 15 — the deployment target for this project is 15.0, and a
// strong import of a newer framework would fail to link for older targets.
@_weakLink import FoundationModels

/// On-device image captioning via Apple's on-device language model.
///
/// This exists because iOS has no API to capture another app's screen, so the
/// only pixels available here are the app's own (RepaintBoundary). Captioning
/// them locally keeps the data on the device: no screenshot is uploaded for
/// in-app captures on iOS.
public class OnDeviceCaptionPlugin: NSObject, FlutterPlugin {

    private static let channelName = "duylong.art/ondevice_caption"

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = OnDeviceCaptionPlugin()
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isAvailable":
            result(Self.isAvailable())
        case "caption":
            guard let args = call.arguments as? [String: Any],
                  let path = args["path"] as? String
            else {
                result(FlutterError(
                    code: "bad_args",
                    message: "caption requires a file path",
                    details: nil
                ))
                return
            }
            caption(path: path, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Runtime availability: the OS must expose the framework AND the device
    /// must be capable. Both are checked because a device can be on a new iOS
    /// with older silicon.
    private static func isAvailable() -> Bool {
        if #available(iOS 26.0, *) {
            // LanguageModelSession.availability is the framework's own
            // device-capability check (accounts for A17 Pro / M-series).
            return LanguageModelSession.availability == .available
        }
        return false
    }

    private func caption(path: String, result: @escaping FlutterResult) {
        guard Self.isAvailable() else {
            result(FlutterError(
                code: "unavailable",
                message: "On-device model unavailable on this device or OS version",
                details: nil
            ))
            return
        }

        let image: UIImage
        if let data = FileManager.default.contents(atPath: path) {
            guard let decoded = UIImage(data: data) else {
                result(FlutterError(
                    code: "bad_image",
                    message: "Could not decode image at \(path)",
                    details: nil
                ))
                return
            }
            image = decoded
        } else {
            result(FlutterError(
                code: "missing_file",
                message: "No file at \(path)",
                details: nil
            ))
            return
        }

        Task {
            do {
                let caption = try await Self.generateCaption(image: image)
                await MainActor.run { result(caption) }
            } catch {
                await MainActor.run {
                    result(FlutterError(
                        code: "caption_failed",
                        message: error.localizedDescription,
                        details: nil
                    ))
                }
            }
        }
    }

    @available(iOS 26.0, *)
    private static func generateCaption(image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(
                domain: "ImageError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Could not encode image as JPEG"]
            )
        }

        let session = LanguageModelSession()
        let attachment = Attachment(content: ImageAttachmentContent(data: imageData))
        let prompt = Prompt(
            """
            Describe this app screen in detail for a personal memory system.
            State what the user is looking at, any visible numbers or trends, \
            and what the screen appears to be for.
            """,
            attachments: [attachment]
        )

        let response = try await session.respond(to: prompt)
        return response.text
    }
}
