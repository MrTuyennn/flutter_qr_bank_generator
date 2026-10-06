package com.example.flutter_qr_bank_generator.qrcode

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class QrCodeFactory(
    private val messenger: BinaryMessenger,
    private val flutterAssets: FlutterPlugin.FlutterAssets
) : PlatformViewFactory(
    StandardMessageCodec.INSTANCE
) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return QrCodeWidget(context, viewId, messenger, flutterAssets, args)
    }
}
