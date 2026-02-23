import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let linkChannelName = "apkarena/links"
  private var linkChannel: FlutterMethodChannel?
  private var initialLink: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: linkChannelName,
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        guard let self = self else {
          result(nil)
          return
        }
        switch call.method {
        case "getInitialLink":
          result(self.initialLink)
          self.initialLink = nil
        default:
          result(FlutterMethodNotImplemented)
        }
      }
      linkChannel = channel
    }

    if let launchURL = launchOptions?[.url] as? URL {
      handleIncomingURL(launchURL)
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    handleIncomingURL(url)
    return super.application(app, open: url, options: options)
  }

  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
      let url = userActivity.webpageURL
    {
      handleIncomingURL(url)
      return true
    }
    return super.application(
      application,
      continue: userActivity,
      restorationHandler: restorationHandler
    )
  }

  private func handleIncomingURL(_ url: URL) {
    let urlString = url.absoluteString
    initialLink = urlString
    linkChannel?.invokeMethod("onLink", arguments: urlString)
  }
}
