import Flutter
import Foundation
import UIKit
import SwiftUI

class QrCodeWidget: NSObject, FlutterPlatformView {
    private var hostingController: UIHostingController<QrCodeView>

    init(frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?, registrar: FlutterPluginRegistrar) {
        let params = args as? Dictionary<String, Any>
        let content = params?["content"] as? String ?? ""
        let image = params?["image"] as? String ?? ""
        // set data qrcode
        let model = QrCodeModel(registrar: registrar)
        model.setDataQrCode(contentQr: content, imageQr: image)
        // set data qrcode

        let swiftUIView = QrCodeView(model: model)
        self.hostingController = UIHostingController(rootView: swiftUIView)
        self.hostingController.view.frame = frame
        self.hostingController.view.backgroundColor = .white
        super.init()
    }

    func view() -> UIView {
        return hostingController.view
    }
}
