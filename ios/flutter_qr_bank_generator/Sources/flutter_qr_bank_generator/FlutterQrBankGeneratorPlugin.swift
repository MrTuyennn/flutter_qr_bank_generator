import Flutter
import UIKit

let viewTypeQrGenerator = "flutter_qr_bank_generator/qrcode"

public class FlutterQrBankGeneratorPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let factory = QrCodeFactory(registrar: registrar)
    registrar.register(factory, withId: viewTypeQrGenerator)
  }
}
