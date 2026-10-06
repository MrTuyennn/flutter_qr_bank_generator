package com.mobile.flutter_qr_bank_generator.qrcode

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.View
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.ProgressBar
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.platform.PlatformView
import java.util.concurrent.Executors

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

        // Check if image URL is provided
        if (image.isNotEmpty()) {
            // Show loading indicator
            mainHandler.post {
                loading?.visibility = View.VISIBLE
                loading?.bringToFront()
            }

            // Render asynchronously (image may be a network URL)
            executor.execute {
                val finalBitmap = QrImageRenderer.render(context, content, image, flutterAssets)
                mainHandler.post {
                    // Hide loading indicator
                    loading?.visibility = View.GONE
                    qrCodeImageView.setImageBitmap(finalBitmap)
                }
            }
        } else {
            val finalBitmap = QrImageRenderer.render(context, content, image, flutterAssets)
            qrCodeImageView.setImageBitmap(finalBitmap)
        }
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
