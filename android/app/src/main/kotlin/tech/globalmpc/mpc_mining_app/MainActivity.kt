package tech.globalmpc.mpc_mining_app

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity, not FlutterActivity: local_auth shows the biometric
// prompt through androidx.biometric, which needs a FragmentActivity host and
// otherwise fails every call with NOT_FRAGMENT_ACTIVITY.
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mpc/secure_screen")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enable" -> {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(null)
                    }
                    "disable" -> {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        // Opens an https destination in the system browser. The Dart side has
        // already filtered the scheme; this re-checks it so the platform never
        // launches an arbitrary intent on behalf of a page.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mpc/external_link")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "open" -> {
                        val url = call.argument<String>("url")
                        val uri = url?.let { Uri.parse(it) }
                        if (uri == null || uri.scheme?.lowercase() != "https") {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        try {
                            startActivity(Intent(Intent.ACTION_VIEW, uri))
                            result.success(true)
                        } catch (e: ActivityNotFoundException) {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
