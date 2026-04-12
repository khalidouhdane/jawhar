import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Plugin registration is now handled by didInitializeImplicitFlutterEngine
    // for UIScene lifecycle compatibility on iOS 26+.
    // See: https://flutter.dev/to/uiscene-migration

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Called by Flutter when the implicit engine is ready.
  /// Plugins are registered here instead of in didFinishLaunchingWithOptions
  /// to ensure the engine and binary messenger are fully initialized before
  /// any plugin tries to use them. This fixes the EXC_BAD_ACCESS crash
  /// in audioplayers_darwin on iOS 26.
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
