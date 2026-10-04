import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    raiseOpenFileLimit()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// The stockfish plugin's native glue opens two pipes every time an engine
  /// starts and never closes them: four file descriptors per Opening Explorer
  /// visit. iOS launches apps with a soft limit of 256 open files, and an iPad
  /// can keep the app alive for days, so raise the soft limit (up to the hard
  /// limit) to make that leak irrelevant.
  private func raiseOpenFileLimit() {
    var limit = rlimit()
    guard getrlimit(RLIMIT_NOFILE, &limit) == 0 else { return }
    let target = min(limit.rlim_max, rlim_t(4096))
    guard target > limit.rlim_cur else { return }
    limit.rlim_cur = target
    _ = setrlimit(RLIMIT_NOFILE, &limit)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
