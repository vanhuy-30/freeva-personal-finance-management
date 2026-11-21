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
  // The cover goes on only when the app really leaves the foreground (app
  // switcher snapshot). willResignActive also fires while a system alert such as
  // the notification-permission prompt is up, which used to blank the whole app.
  override func applicationDidEnterBackground(_ application: UIApplication) {
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
    super.applicationDidEnterBackground(application)
  }

  override func applicationWillEnterForeground(_ application: UIApplication) {
    super.applicationWillEnterForeground(application)
    privacyCover?.removeFromSuperview()
    privacyCover = nil
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    privacyCover?.removeFromSuperview()
    privacyCover = nil
  }
}
