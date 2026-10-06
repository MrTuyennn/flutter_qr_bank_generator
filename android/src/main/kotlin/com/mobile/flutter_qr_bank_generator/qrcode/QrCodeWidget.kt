package com.mobile.flutter_qr_bank_generator.qrcode

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Rect
import android.os.Handler
import android.os.Looper
import android.util.Base64
import android.view.View
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.ProgressBar
import com.google.zxing.BarcodeFormat
import com.google.zxing.MultiFormatWriter
import com.google.zxing.common.BitMatrix
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.platform.PlatformView
import java.util.concurrent.Executors
import androidx.core.graphics.createBitmap
import androidx.core.graphics.withClip
import androidx.core.graphics.set

class QrCodeWidget internal constructor(
    context: Context,
    id: Int,
    messenger: BinaryMessenger,
    private val flutterAssets: FlutterPlugin.FlutterAssets,
    args: Any?
) : PlatformView, MethodCallHandler {

    private var rootView: View? = null
    private var qrCodeImageView: ImageView

    private var loading: ProgressBar? = null
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    private var content: String = ""
    private var image: String = ""

    init {
        // Parse creationParams
        if (args is MutableMap<*, *>) {
            if (args.containsKey("content")) {
                content = (args["content"] as String?).toString()
            }
            if (args.containsKey("image")) {
                image = (args["image"] as String?).toString()
            }
        }
        qrCodeImageView = ImageView(context).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.WRAP_CONTENT,
                FrameLayout.LayoutParams.WRAP_CONTENT
            )
            scaleType = ImageView.ScaleType.CENTER_INSIDE
        }

        loading = ProgressBar(context).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.WRAP_CONTENT,
                FrameLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = android.view.Gravity.CENTER
            }
            visibility = View.GONE
            indeterminateTintList = android.content.res.ColorStateList.valueOf(android.graphics.Color.BLACK)
        }

        val frameLayout = FrameLayout(context)
        frameLayout.addView(qrCodeImageView)
        frameLayout.addView(loading)
        rootView = frameLayout

        // Generate QR code first
        val bitmap = generateQRCode(content)

        // Check if image URL is provided
        if (image.isNotEmpty()) {
            // Show loading indicator
            mainHandler.post {
                loading?.visibility = View.VISIBLE
                loading?.bringToFront()
            }

            // Load image asynchronously (URL / base64 / Flutter asset)
            executor.execute {
                val iconBitmap = loadImage(context, image)
                mainHandler.post {
                    // Hide loading indicator
                    loading?.visibility = View.GONE

                    val finalBitmap = overlayIconOnQRCode(bitmap, iconBitmap ?: loadHostAppIcon(context))
                    qrCodeImageView.setImageBitmap(finalBitmap)
                }
            }
        } else {
            // Use default app icon
            val finalBitmap = overlayIconOnQRCode(bitmap, loadHostAppIcon(context))
            qrCodeImageView.setImageBitmap(finalBitmap)
        }
    }

    /**
     * The plugin has no compile-time access to the host app's R class, so the
     * fallback icon is looked up dynamically by resource name from the host package.
     */
    private fun loadHostAppIcon(context: Context): Bitmap? {
        val resId = context.resources.getIdentifier("app_icon", "drawable", context.packageName)
        if (resId == 0) return null
        return BitmapFactory.decodeResource(context.resources, resId)
    }

    /**
     * [image] can be a network URL, a base64-encoded image (optionally as a
     * `data:` URI), or a Flutter asset path (e.g. `assets/logo.png`).
     */
    private fun loadImage(context: Context, image: String): Bitmap? {
        return when {
            isHttpUrl(image) -> loadBitmapFromUrl(image)
            isBase64(image) -> loadBitmapFromBase64(image)
            else -> loadBitmapFromAsset(context, image)
        }
    }

    private fun isHttpUrl(value: String): Boolean =
        value.startsWith("http://", ignoreCase = true) || value.startsWith("https://", ignoreCase = true)

    private fun isBase64(value: String): Boolean {
        val payload = if (value.startsWith("data:")) value.substringAfter(",", "") else value
        if (payload.isEmpty() || payload.length % 4 != 0) return false
        return Regex("^[A-Za-z0-9+/]+={0,2}$").matches(payload)
    }

    private fun loadBitmapFromUrl(urlStr: String): Bitmap? {
        return try {
            val url = java.net.URL(urlStr)
            val connection = url.openConnection() as java.net.HttpURLConnection
            connection.doInput = true
            connection.connectTimeout = 10000 // 10 seconds timeout
            connection.readTimeout = 10000
            connection.connect()
            val inputStream = connection.inputStream
            val bitmap = BitmapFactory.decodeStream(inputStream)
            inputStream?.close()
            connection.disconnect()
            bitmap
        } catch (e: Exception) {
            e.printStackTrace()
            android.util.Log.e("QrCodeWidget", "Error loading image from URL: ${e.message}")
            null
        }
    }

    private fun loadBitmapFromBase64(data: String): Bitmap? {
        return try {
            val payload = if (data.startsWith("data:")) data.substringAfter(",") else data
            val bytes = Base64.decode(payload, Base64.DEFAULT)
            BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
        } catch (e: Exception) {
            android.util.Log.e("QrCodeWidget", "Error decoding base64 image: ${e.message}")
            null
        }
    }

    private fun loadBitmapFromAsset(context: Context, assetPath: String): Bitmap? {
        return try {
            val key = flutterAssets.getAssetFilePathBySubpath(assetPath)
            context.assets.open(key).use { BitmapFactory.decodeStream(it) }
        } catch (e: Exception) {
            android.util.Log.e("QrCodeWidget", "Error loading asset image: ${e.message}")
            null
        }
    }

    private fun overlayIconOnQRCode(bitmap: Bitmap, iconBitmap: Bitmap?): Bitmap {
        if (iconBitmap == null) return bitmap

        // Create a new Bitmap with the some dimensions as the QR Code
        val combinedBitmap =
            createBitmap(bitmap.width, bitmap.height, bitmap.config ?: Bitmap.Config.ARGB_8888)
        val canvas = Canvas(combinedBitmap)
        val paint = Paint()

        // Draw the QR code on the canvas
        canvas.drawBitmap(bitmap, 0f, 0f, paint)

        // Calculate the position to place the icon at the center
        val iconSize = bitmap.width / 5   // Make icon bigger (was /7, now /5)
        val left = (bitmap.width - iconSize) / 2
        val top = (bitmap.height - iconSize) / 2

        val centerX = left + iconSize / 2f
        val centerY = top + iconSize / 2f
        val radius = iconSize / 2f

        // Create circular image with border
        val circlePaint = Paint().apply {
            color = android.graphics.Color.WHITE  // White background
            isAntiAlias = true
        }

        val borderPaint = Paint().apply {
            color = android.graphics.Color.BLACK  // Black border
            style = Paint.Style.STROKE
            strokeWidth = 2f  // Border width
            isAntiAlias = true
        }

        // Create circular clipping for the image
        val clipPath = android.graphics.Path()
        clipPath.addCircle(centerX, centerY, radius - 2f, android.graphics.Path.Direction.CW)

        // Save canvas state
        canvas.withClip(clipPath) {

            // Apply circular clipping
            // Draw white circle background
            drawCircle(centerX, centerY, radius, circlePaint)

            // Draw the icon with circular clipping
            val iconRect = Rect(left, top, left + iconSize, top + iconSize)
            drawBitmap(iconBitmap, null, iconRect, paint)

            // Restore canvas state
        }

        // Draw black border on top
        canvas.drawCircle(centerX, centerY, radius, borderPaint)

        return combinedBitmap
    }

    private fun generateQRCode(content: String): Bitmap {
        val writer = MultiFormatWriter()
        val bitMatrix = writer.encode(content, BarcodeFormat.QR_CODE, 512, 512)

        // Tìm vùng chứa QR thực sự (bỏ padding trắng)
        val width = bitMatrix.width
        val height = bitMatrix.height
        var minX = width
        var minY = height
        var maxX = 0
        var maxY = 0

        for (x in 0 until width) {
            for (y in 0 until height) {
                if (bitMatrix.get(x, y)) {
                    if (x < minX) minX = x
                    if (x > maxX) maxX = x
                    if (y < minY) minY = y
                    if (y > maxY) maxY = y
                }
            }
        }

        // Crop lại vùng có QR code
        val qrWidth = maxX - minX + 1
        val qrHeight = maxY - minY + 1
        val croppedMatrix = BitMatrix(qrWidth, qrHeight)
        for (x in 0 until qrWidth) {
            for (y in 0 until qrHeight) {
                if (bitMatrix.get(x + minX, y + minY)) {
                    croppedMatrix.set(x, y)
                }
            }
        }

        // Tạo bitmap từ matrix đã crop
        val pixelsPerModule = 2  // nếu bạn muốn phóng to QR
        val bitmap = createBitmap(qrWidth * pixelsPerModule, qrHeight * pixelsPerModule)

        for (x in 0 until qrWidth) {
            for (y in 0 until qrHeight) {
                val color = if (croppedMatrix.get(x, y)) 0xFF000000.toInt() else 0xFFFFFFFF.toInt()
                for (px in 0 until pixelsPerModule) {
                    for (py in 0 until pixelsPerModule) {
                        bitmap[x * pixelsPerModule + px, y * pixelsPerModule + py] = color
                    }
                }
            }
        }

        return bitmap
    }

    override fun getView(): View? {
        return rootView
    }

    override fun dispose() {
        executor.shutdown()
    }

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
    }
}
