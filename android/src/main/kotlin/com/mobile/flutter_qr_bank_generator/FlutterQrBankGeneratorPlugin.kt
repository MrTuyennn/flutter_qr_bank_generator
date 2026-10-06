package com.mobile.flutter_qr_bank_generator

import com.mobile.flutter_qr_bank_generator.qrcode.QrCodeFactory
import io.flutter.embedding.engine.plugins.FlutterPlugin

const val VIEW_TYPE_QR_GENERATOR = "flutter_qr_bank_generator/qrcode"

/** FlutterQrBankGeneratorPlugin */
class FlutterQrBankGeneratorPlugin : FlutterPlugin {
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        binding.platformViewRegistry.registerViewFactory(
            VIEW_TYPE_QR_GENERATOR,
            QrCodeFactory(binding.binaryMessenger, binding.flutterAssets)
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    }
}
