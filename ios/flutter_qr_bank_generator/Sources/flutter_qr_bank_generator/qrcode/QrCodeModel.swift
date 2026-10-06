import Flutter
import UIKit

final class QrCodeModel: ObservableObject {
    private let registrar: FlutterPluginRegistrar?

    @Published var content: String = ""
    @Published var image: String = ""
    @Published var qrcode: UIImage?

    init(registrar: FlutterPluginRegistrar? = nil) {
        self.registrar = registrar
    }

    // gọi chỗ này bình thường, model tự chạy async bên trong
    func setDataQrCode(contentQr: String, imageQr: String) {
        content = contentQr
        image   = imageQr
        Task {
            let result = await QrImageRenderer.render(content: content, image: image, registrar: registrar)
            await MainActor.run { self.qrcode = result }
        }
    }
}
