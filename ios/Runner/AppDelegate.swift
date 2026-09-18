import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    registerExternalLinkChannel()
    return launched
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  /// Opens an https destination in the system browser. The Dart side has
  /// already filtered the scheme; this re-checks it so the platform never
  /// opens an arbitrary URL on behalf of a page.
  private func registerExternalLinkChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "mpc/external_link",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "open" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let arguments = call.arguments as? [String: Any],
        let raw = arguments["url"] as? String,
        let url = URL(string: raw),
        url.scheme?.lowercased() == "https"
      else {
        result(false)
        return
      }
      UIApplication.shared.open(url, options: [:]) { opened in
        result(opened)
      }
    }
  }
}
