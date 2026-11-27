import Flutter
import GoogleMobileAds
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "com.jordonpark.laureol/ads",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "useContextualAds" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let configuration = MobileAds.shared.requestConfiguration
      configuration.setPublisherFirstPartyIDEnabled(false)
      configuration.publisherPrivacyPersonalizationState = .disabled
      result(nil)
    }
  }
}
