package com.mobile.flutter_qr_bank_generator

import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import androidx.core.content.FileProvider
import com.mobile.flutter_qr_bank_generator.qrcode.QrCodeFactory
import com.mobile.flutter_qr_bank_generator.qrcode.QrImageRenderer
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.Executors

const val VIEW_TYPE_QR_GENERATOR = "flutter_qr_bank_generator/qrcode"
const val METHOD_CHANNEL_QR_GENERATOR = "flutter_qr_bank_generator/methods"

/** FlutterQrBankGeneratorPlugin */
class FlutterQrBankGeneratorPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var applicationContext: Context
    private lateinit var flutterAssets: FlutterPlugin.FlutterAssets
    private lateinit var channel: MethodChannel
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        flutterAssets = binding.flutterAssets

        binding.platformViewRegistry.registerViewFactory(
            VIEW_TYPE_QR_GENERATOR,
            QrCodeFactory(binding.binaryMessenger, binding.flutterAssets)
        )

        channel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL_QR_GENERATOR)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        executor.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "generate" -> handleGenerate(call, result)
            "download" -> handleDownload(call, result)
            "share" -> handleShare(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handleGenerate(call: MethodCall, result: MethodChannel.Result) {
        val content = call.argument<String>("content") ?: ""
        val image = call.argument<String>("image") ?: ""
        executor.execute {
            try {
                val bitmap = QrImageRenderer.render(applicationContext, content, image, flutterAssets)
                val bytes = bitmap.toPngBytes()
                mainHandler.post { result.success(bytes) }
            } catch (e: Exception) {
                mainHandler.post { result.error("generate_failed", e.message, null) }
            }
        }
    }

    private fun handleDownload(call: MethodCall, result: MethodChannel.Result) {
        val bytes = call.argument<ByteArray>("bytes")
        val fileName = call.argument<String>("fileName") ?: "qrcode"
        if (bytes == null) {
            result.error("invalid_args", "bytes is required", null)
            return
        }
        executor.execute {
            try {
                val saved = saveImageToGallery(applicationContext, bytes, fileName)
                mainHandler.post { result.success(saved) }
            } catch (e: Exception) {
                mainHandler.post { result.error("download_failed", e.message, null) }
            }
        }
    }

    private fun handleShare(call: MethodCall, result: MethodChannel.Result) {
        val bytes = call.argument<ByteArray>("bytes")
        val fileName = call.argument<String>("fileName") ?: "qrcode"
        val text = call.argument<String>("text")
        if (bytes == null) {
            result.error("invalid_args", "bytes is required", null)
            return
        }
        executor.execute {
            try {
                shareImage(applicationContext, bytes, fileName, text)
                mainHandler.post { result.success(true) }
            } catch (e: Exception) {
                mainHandler.post { result.error("share_failed", e.message, null) }
            }
        }
    }

    private fun Bitmap.toPngBytes(): ByteArray {
        val stream = ByteArrayOutputStream()
        compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }

    /**
     * Saves PNG [bytes] to the device's Pictures gallery via MediaStore (no
     * runtime permission needed on API 29+; `WRITE_EXTERNAL_STORAGE` is
     * declared with `maxSdkVersion="28"` for older devices).
     */
    private fun saveImageToGallery(context: Context, bytes: ByteArray, fileName: String): Boolean {
        val resolver = context.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, "$fileName.png")
            put(MediaStore.Images.Media.MIME_TYPE, "image/png")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES)
            }
        }
        val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values) ?: return false
        val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
        resolver.openOutputStream(uri)?.use { out ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
        } ?: return false
        return true
    }

    /**
     * Writes PNG [bytes] to the app's cache dir and opens the native share
     * sheet for it via a [FileProvider]-backed content URI. Uses
     * `FLAG_ACTIVITY_NEW_TASK` since the plugin doesn't track the current
     * [android.app.Activity].
     */
    private fun shareImage(context: Context, bytes: ByteArray, fileName: String, text: String?) {
        val imagesDir = File(context.cacheDir, "images").apply { mkdirs() }
        val file = File(imagesDir, "$fileName.png")
        file.outputStream().use { it.write(bytes) }

        val uri = FileProvider.getUriForFile(
            context,
            "${context.packageName}.flutter_qr_bank_generator.fileprovider",
            file
        )

        val sendIntent = Intent(Intent.ACTION_SEND).apply {
            type = "image/png"
            putExtra(Intent.EXTRA_STREAM, uri)
            if (!text.isNullOrEmpty()) putExtra(Intent.EXTRA_TEXT, text)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        val chooser = Intent.createChooser(sendIntent, "Share QR Code").apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(chooser)
    }
}
