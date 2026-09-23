import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var privacyCover: UIView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  override func applicationWillResignActive(_ application: UIApplication) {
    if let window = window, privacyCover == nil {
      let cover = UIView(frame: window.bounds)
      if #available(iOS 13.0, *) {
        cover.backgroundColor = .systemBackground
      } else {
        cover.backgroundColor = .white
      }
      cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      window.addSubview(cover)
      privacyCover = cover
    }
    super.applicationWillResignActive(application)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    privacyCover?.removeFromSuperview()
    privacyCover = nil
  }
}
