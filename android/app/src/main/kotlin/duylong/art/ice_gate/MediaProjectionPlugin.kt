package duylong.art.ice_gate

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.Image
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Handler
import android.os.HandlerThread
import android.util.Base64
import android.util.DisplayMetrics
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

/**
 * Cross-app screen capture via MediaProjection.
 *
 * This is the only supported way to read another app's pixels on Android.
 *
 * Consent cannot be persisted: the projection grant is invalidated on reboot
 * and app restart, so [requestConsent] must re-launch the system dialog on
 * every cold start. A declined or revoked grant fails closed — capture returns
 * null rather than retrying.
 *
 * iOS has no equivalent API, so this plugin has no counterpart there.
 */
class MediaProjectionPlugin(
    private val context: Context,
    private val activityProvider: () -> Activity?,
) : MethodChannel.MethodCallHandler {

    companion object {
        private const val CHANNEL = "duylong.art/mediaprojection"
        private const val REQUEST_CODE = 0x5CA7
    }

    private var pendingResult: MethodChannel.Result? = null
    private var projection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    private var screenThread: HandlerThread? = null
    private var screenHandler: Handler? = null
    private var hasConsent = false

    fun register(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler(this)
    }

    /** Re-checked on every launch; the grant does not survive a restart. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE) return false
        val result = pendingResult ?: return true
        pendingResult = null

        if (resultCode != Activity.RESULT_OK || data == null) {
            hasConsent = false
            result.success(false)
            return true
        }

        val manager =
            context.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as? MediaProjectionManager
        if (manager == null) {
            hasConsent = false
            result.success(false)
            return true
        }

        projection = runCatching { manager.getMediaProjection(resultCode, data) }.getOrNull()
        hasConsent = projection != null
        result.success(hasConsent)
        return true
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "requestConsent" -> requestConsent(result)
            "capture" -> capture(result)
            "isSupported" -> result.success(true)
            else -> result.notImplemented()
        }
    }

    private fun requestConsent(result: MethodChannel.Result) {
        if (hasConsent && projection != null) {
            result.success(true)
            return
        }
        val activity = activityProvider()
        val manager =
            context.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as? MediaProjectionManager
        if (activity == null || manager == null) {
            result.success(false)
            return
        }
        // Only one consent flow at a time; a second caller overwrites the first.
        if (pendingResult != null) {
            result.success(false)
            return
        }
        pendingResult = result
        runCatching {
            activity.startActivityForResult(
                manager.createScreenCaptureIntent(),
                REQUEST_CODE,
            )
        }.onFailure {
            pendingResult = null
            result.success(false)
        }
    }

    private fun capture(result: MethodChannel.Result) {
        val activeProjection = projection
        if (!hasConsent || activeProjection == null) {
            // Fail closed: never retry without a fresh grant.
            result.success(null)
            return
        }

        val metrics = displaySize() ?: run {
            result.success(null)
            return
        }

        try {
            val reader = ImageReader.newInstance(
                metrics.first,
                metrics.second,
                PixelFormat.RGBA_8888,
                2,
            )
            val thread = HandlerThread("media-projection-capture").apply { start() }
            val handler = Handler(thread.looper)
            imageReader = reader
            screenThread = thread
            screenHandler = handler

            virtualDisplay = activeProjection.createVirtualDisplay(
                "ice_gate_capture",
                metrics.first,
                metrics.second,
                metrics.density,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                reader.surface,
                null,
                handler,
            )

            reader.setOnImageAvailableListener({ available ->
                val image = runCatching { available.acquireLatestImage() }.getOrNull()
                if (image != null) {
                    val bytes = runCatching { image.toPngBytes() }.getOrNull()
                    image.close()
                    releaseDisplay()
                    if (bytes != null) {
                        result.success(
                            mapOf(
                                "bytes" to Base64.encodeToString(bytes, Base64.NO_WRAP),
                                "width" to metrics.first,
                                "height" to metrics.second,
                            )
                        )
                    } else {
                        result.success(null)
                    }
                }
            }, handler)
        } catch (_: Exception) {
            releaseDisplay()
            result.success(null)
        }
    }

    private fun Image.toPngBytes(): ByteArray {
        val plane = planes[0]
        val rowPadding = plane.rowStride - plane.pixelStride * width
        val paddedWidth = width + rowPadding / plane.pixelStride
        val bitmap = android.graphics.Bitmap.createBitmap(
            paddedWidth,
            height,
            android.graphics.Bitmap.Config.ARGB_8888,
        )
        bitmap.copyPixelsFromBuffer(plane.buffer)

        val cropped =
            if (rowPadding > 0) {
                android.graphics.Bitmap.createBitmap(
                    bitmap,
                    0,
                    0,
                    width,
                    height,
                )
            } else {
                bitmap
            }

        val out = ByteArrayOutputStream()
        cropped.compress(android.graphics.Bitmap.CompressFormat.PNG, 90, out)
        if (cropped !== bitmap) cropped.recycle()
        bitmap.recycle()
        return out.toByteArray()
    }

    private fun displaySize(): Triple<Int, Int, Int>? {
        val wm = context.getSystemService(Context.WINDOW_SERVICE) as? WindowManager
            ?: return null
        val metrics = DisplayMetrics()
        @Suppress("DEPRECATION")
        wm.defaultDisplay.getRealMetrics(metrics)
        return Triple(metrics.widthPixels, metrics.heightPixels, metrics.densityDpi)
    }

    private fun releaseDisplay() {
        virtualDisplay?.release()
        virtualDisplay = null
        imageReader?.close()
        imageReader = null
        screenThread?.quitSafely()
        screenThread = null
        screenHandler = null
    }

    fun dispose() {
        releaseDisplay()
        projection?.release()
        projection = null
        hasConsent = false
    }
}
