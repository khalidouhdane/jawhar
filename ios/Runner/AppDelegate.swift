import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Pre-activate AVAudioSession before plugin registration.
    // audioplayers_darwin calls AVAudioSession.sharedInstance() during init().
    // On iOS 26, accessing the audio session too early (before the app is
    // fully initialized) results in EXC_BAD_ACCESS. By configuring the
    // session here first, we ensure the shared instance is valid before
    // any plugin touches it.
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(.playback, mode: .default)
      try session.setActive(false)
    } catch {
      // Non-fatal — proceed with plugin registration regardless.
    }

    GeneratedPluginRegistrant.register(with: self)

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
