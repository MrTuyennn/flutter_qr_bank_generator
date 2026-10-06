import Flutter
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

final class QrCodeModel: ObservableObject {
    private let context = CIContext(options: [.useSoftwareRenderer: false])
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
        Task { await generateQRCode() }
    }

    /// Tạo QR và chèn icon (nếu có) - chạy async, không block UI
    func generateQRCode() async {
        // Tạo filter mỗi lần (an toàn thread hơn giữ property)
        let f = CIFilter.qrCodeGenerator()
        f.message = Data(content.utf8)
        f.correctionLevel = "H"

        guard let out = f.outputImage else {
            await MainActor.run { self.qrcode = UIImage(systemName: "xmark.circle") }
            return
        }

        // scale cho nét
        let scaled = out.transformed(by: CGAffineTransform(scaleX: 20, y: 20))

        // render ra UIImage
        guard let cg = context.createCGImage(scaled, from: scaled.extent) else {
            await MainActor.run { self.qrcode = UIImage(systemName: "xmark.circle") }
            return
        }
        let baseQR = UIImage(cgImage: cg)

        // tải icon async (KHÔNG dùng Data(contentsOf:))
        let icon = await loadIconUIImage()

        // ghép icon (nếu có)
        let finalImage: UIImage = {
            guard let icon else { return baseQR }
            return addIconToQRCode(qrImage: baseQR, icon: icon)
        }()

        await MainActor.run { self.qrcode = finalImage }
    }

    // MARK: - Async icon loader
    /// [image] can be a network URL, a base64-encoded image (optionally as a
    /// `data:` URI), or a Flutter asset path (e.g. `assets/logo.png`).
    private func loadIconUIImage() async -> UIImage? {
        guard !image.isEmpty else { return getAppIcon() }

        if isHttpUrl(image) {
            if let img = await loadFromUrl(image) { return img }
        } else if isBase64(image) {
            if let img = loadFromBase64(image) { return img }
        } else if let img = loadFromAsset(image) {
            return img
        }

        return getAppIcon()
    }

    private func isHttpUrl(_ value: String) -> Bool {
        let lowered = value.lowercased()
        return lowered.hasPrefix("http://") || lowered.hasPrefix("https://")
    }

    private func isBase64(_ value: String) -> Bool {
        let payload = value.hasPrefix("data:") ? String(value.split(separator: ",", maxSplits: 1).last ?? "") : value
        guard !payload.isEmpty, payload.count % 4 == 0 else { return false }
        let base64Chars = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=")
        return payload.unicodeScalars.allSatisfy { base64Chars.contains($0) }
    }

    private func loadFromUrl(_ urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            return nil
        }
    }

    private func loadFromBase64(_ value: String) -> UIImage? {
        let payload = value.hasPrefix("data:") ? String(value.split(separator: ",", maxSplits: 1).last ?? "") : value
        guard let data = Data(base64Encoded: payload) else { return nil }
        return UIImage(data: data)
    }

    private func loadFromAsset(_ assetPath: String) -> UIImage? {
        guard let registrar else { return nil }
        let key = registrar.lookupKey(forAsset: assetPath)
        guard let path = Bundle.main.path(forResource: key, ofType: nil) else { return nil }
        return UIImage(contentsOfFile: path)
    }

    /// Overlay icon vào giữa QR (bo tròn + viền trắng)
    private func addIconToQRCode(qrImage: UIImage, icon: UIImage) -> UIImage {
        let size = qrImage.size
        let ratio: CGFloat = 0.2
        let iconSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let iconOrigin = CGPoint(x: (size.width - iconSize.width) / 2,
                                 y: (size.height - iconSize.height) / 2)
        let iconRect = CGRect(origin: iconOrigin, size: iconSize)

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            qrImage.draw(in: CGRect(origin: .zero, size: size))

            // NẾU muốn nền trong suốt cho logo, hãy xóa 3 dòng fill trắng bên dưới
            let circlePath = UIBezierPath(ovalIn: iconRect)
            UIColor.white.setFill()
            circlePath.fill()

            circlePath.addClip()
            icon.draw(in: iconRect)
        }
    }

    /// Bundle.main is always the host app's bundle, so this still resolves
    /// the host app's icon even though this code now lives in a plugin pod.
    private func getAppIcon() -> UIImage? {
        guard
            let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
            let primaryIcons = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
            let iconFiles = primaryIcons["CFBundleIconFiles"] as? [String],
            let lastIcon = iconFiles.last
        else { return nil }
        return UIImage(named: lastIcon)
    }
}
