import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var privacyCovers: [ObjectIdentifier: UIView] = [:]

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let center = NotificationCenter.default
    center.addObserver(
      self, selector: #selector(sceneDidEnterBackground(_:)),
      name: UIScene.didEnterBackgroundNotification, object: nil)
    center.addObserver(
      self, selector: #selector(sceneBecameVisible(_:)),
      name: UIScene.willEnterForegroundNotification, object: nil)
    center.addObserver(
      self, selector: #selector(sceneBecameVisible(_:)),
      name: UIScene.didActivateNotification, object: nil)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // The cover goes on only when a scene really leaves the foreground (app
  // switcher snapshot). willResignActive also fires while a system alert such as
  // the notification-permission prompt is up, which used to blank the whole app.
  @objc private func sceneDidEnterBackground(_ note: Notification) {
    guard let scene = note.object as? UIWindowScene,
      let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first
    else { return }
    let id = ObjectIdentifier(scene)
    if privacyCovers[id] != nil { return }
    let cover = UIView(frame: window.bounds)
    cover.backgroundColor = .systemBackground
    cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    window.addSubview(cover)
    privacyCovers[id] = cover
  }

  @objc private func sceneBecameVisible(_ note: Notification) {
    guard let scene = note.object as? UIScene else { return }
    privacyCovers.removeValue(forKey: ObjectIdentifier(scene))?.removeFromSuperview()
  }
}
