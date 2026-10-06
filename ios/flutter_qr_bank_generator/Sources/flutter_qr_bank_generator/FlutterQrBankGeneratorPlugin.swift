import Flutter
import Photos
import UIKit

let viewTypeQrGenerator = "flutter_qr_bank_generator/qrcode"
let methodChannelQrGenerator = "flutter_qr_bank_generator/methods"

public class FlutterQrBankGeneratorPlugin: NSObject, FlutterPlugin {
  private let registrar: FlutterPluginRegistrar

  init(registrar: FlutterPluginRegistrar) {
    self.registrar = registrar
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let factory = QrCodeFactory(registrar: registrar)
    registrar.register(factory, withId: viewTypeQrGenerator)

    let instance = FlutterQrBankGeneratorPlugin(registrar: registrar)
    let channel = FlutterMethodChannel(name: methodChannelQrGenerator, binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      instance.handle(call, result: result)
    }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "generate":
      handleGenerate(call: call, result: result)
    case "download":
      handleDownload(call: call, result: result)
    case "share":
      handleShare(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleGenerate(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    let content = args?["content"] as? String ?? ""
    let image = args?["image"] as? String ?? ""

    Task {
      let uiImage = await QrImageRenderer.render(content: content, image: image, registrar: registrar)
      guard let data = uiImage.pngData() else {
        await MainActor.run {
          result(FlutterError(code: "generate_failed", message: "Could not encode PNG", details: nil))
        }
        return
      }
      await MainActor.run {
        result(FlutterStandardTypedData(bytes: data))
      }
    }
  }

  private func handleDownload(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    guard let typedData = args?["bytes"] as? FlutterStandardTypedData,
          let uiImage = UIImage(data: typedData.data) else {
      result(FlutterError(code: "invalid_args", message: "bytes is required", details: nil))
      return
    }

    PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
      guard status == .authorized || status == .limited else {
        DispatchQueue.main.async { result(false) }
        return
      }
      PHPhotoLibrary.shared().performChanges({
        PHAssetChangeRequest.creationRequestForAsset(from: uiImage)
      }) { success, _ in
        DispatchQueue.main.async { result(success) }
      }
    }
  }

  private func handleShare(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    guard let typedData = args?["bytes"] as? FlutterStandardTypedData else {
      result(FlutterError(code: "invalid_args", message: "bytes is required", details: nil))
      return
    }
    let fileName = args?["fileName"] as? String ?? "qrcode"
    let text = args?["text"] as? String

    let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).png")
    do {
      try typedData.data.write(to: tmpURL, options: .atomic)
    } catch {
      result(FlutterError(code: "share_failed", message: error.localizedDescription, details: nil))
      return
    }

    DispatchQueue.main.async {
      var items: [Any] = [tmpURL]
      if let text, !text.isEmpty { items.append(text) }

      let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)

      guard let root = Self.topViewController() else {
        result(false)
        return
      }

      if let popover = activityVC.popoverPresentationController {
        popover.sourceView = root.view
        popover.sourceRect = CGRect(x: root.view.bounds.midX, y: root.view.bounds.midY, width: 0, height: 0)
      }

      root.present(activityVC, animated: true) {
        result(true)
      }
    }
  }

  private static func topViewController() -> UIViewController? {
    let window = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }

    var top = window?.rootViewController
    while let presented = top?.presentedViewController {
      top = presented
    }
    return top
  }
}
