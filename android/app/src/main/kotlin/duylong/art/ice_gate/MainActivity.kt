package duylong.art.ice_gate

import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterFragmentActivity() {

    private var projectionPlugin: MediaProjectionPlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        projectionPlugin = MediaProjectionPlugin(
            context = applicationContext,
            activityProvider = { this },
        ).also { it.register(flutterEngine) }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        // MediaProjection consent result; handled by the plugin rather than
        // Flutter's own result plumbing.
        if (projectionPlugin?.onActivityResult(requestCode, resultCode, data) == true) {
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onDestroy() {
        projectionPlugin?.dispose()
        projectionPlugin = null
        super.onDestroy()
    }
}
