package com.fomi

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.fomi/external_intent"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "launchExternalUrl" -> {
                    val url = call.argument<String>("url")
                    if (url.isNullOrBlank()) {
                        result.success(false)
                        return@setMethodCallHandler
                    }

                    result.success(launchExternalUrl(url))
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun launchExternalUrl(rawUrl: String): Boolean {
        return try {
            val intent = buildExternalIntent(rawUrl)
            val fallbackUrl = intent.getStringExtra("browser_fallback_url")
            intent.removeExtra("browser_fallback_url")

            try {
                startActivity(intent)
                true
            } catch (_: ActivityNotFoundException) {
                if (fallbackUrl.isNullOrBlank()) {
                    false
                } else {
                    launchExternalUrl(fallbackUrl)
                }
            }
        } catch (_: Exception) {
            false
        }
    }

    private fun buildExternalIntent(rawUrl: String): Intent {
        val intent = if (rawUrl.startsWith("intent:", ignoreCase = true)) {
            Intent.parseUri(rawUrl, Intent.URI_INTENT_SCHEME)
        } else {
            Intent(Intent.ACTION_VIEW, Uri.parse(rawUrl))
        }

        intent.addCategory(Intent.CATEGORY_BROWSABLE)
        intent.component = null
        intent.selector = null
        return intent
    }
}
