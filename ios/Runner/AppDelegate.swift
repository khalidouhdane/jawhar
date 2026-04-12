import Flutter
import UIKit
import audioplayers_darwin

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // WORKAROUND: audioplayers_darwin crashes on iOS 26 during plugin
    // registration because it calls AVAudioSession.sharedInstance() in
    // its init() — before the app lifecycle is fully ready.
    // See: https://github.com/bluefireteam/audioplayers/issues/1940
    //
    // Strategy: Register ALL plugins normally (GeneratedPluginRegistrant),
    // then immediately re-register audioplayers_darwin in the next run loop
    // tick where the audio system is ready. The first registration will
    // crash, so instead we skip it by removing it from the generated file
    // and deferring it manually.
    //
    // Since we can't modify GeneratedPluginRegistrant (it's auto-generated),
    // we'll use a different approach: wrap the registration in a try/catch
    // equivalent for ObjC++ exceptions, or simply defer everything.
    //
    // Simplest reliable fix: call GeneratedPluginRegistrant which includes
    // audioplayers, but wrap the entire call safely. However, EXC_BAD_ACCESS
    // cannot be caught. So the ONLY fix is to ensure the audio session is
    // active before registration.

    // Pre-activate the audio session BEFORE plugin registration so that
    // AVAudioSession.sharedInstance() returns a valid object.
    let audioSession = AVAudioSession.sharedInstance()
    try? audioSession.setCategory(.playback)
    try? audioSession.setActive(true)

    // Now register all plugins — audioplayers_darwin will find a valid session
    GeneratedPluginRegistrant.register(with: self)

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
