package com.luizpaulobarroca.vlibras_flutter

import android.os.Build
import android.util.Log
import android.webkit.WebView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.webviewflutter.WebViewFlutterAndroidExternalApi

/**
 * Plugin Android do vlibras_flutter.
 *
 * O player roda num WebView do webview_flutter. O plugin existe para:
 *
 * 1. Registrar o pacote como plugin Android, o que faz o manifest merger pegar
 *    src/main/AndroidManifest.xml (permissão INTERNET e network security config
 *    que libera cleartext só para 127.0.0.1).
 * 2. Proteger o app da queda do renderer do WebView. Quando o Android encerra
 *    o processo de renderização (falta de memória, travamento), o Chromium
 *    encerra o app inteiro se o WebViewClient não tratar onRenderProcessGone.
 *    O webview_flutter não trata, então aqui o client do WebView do player é
 *    embrulhado por um que trata e avisa o Dart pelo canal
 *    "vlibras_flutter/render_process".
 */
class VLibrasFlutterPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private var channel: MethodChannel? = null
    private var engine: FlutterEngine? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        @Suppress("DEPRECATION")
        engine = binding.flutterEngine
        channel = MethodChannel(binding.binaryMessenger, CHANNEL).also {
            it.setMethodCallHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        engine = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "watch" -> {
                val id = (call.argument<Number>("id"))?.toLong()
                result.success(id != null && watch(id))
            }
            else -> result.notImplemented()
        }
    }

    private fun watch(id: Long): Boolean {
        // getWebViewClient() e onRenderProcessGone existem a partir do Android 8.0.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        val flutterEngine = engine ?: return false
        val webView: WebView =
            WebViewFlutterAndroidExternalApi.getWebView(flutterEngine, id) ?: run {
                Log.w(TAG, "WebView $id não encontrado; renderer sem proteção")
                return false
            }

        val current = webView.webViewClient
        if (current is RenderProcessGuardClient) return true

        webView.webViewClient = RenderProcessGuardClient(current) { didCrash ->
            channel?.invokeMethod(
                "renderProcessGone",
                mapOf("id" to id, "didCrash" to didCrash),
            )
        }
        return true
    }

    private companion object {
        const val CHANNEL = "vlibras_flutter/render_process"
        const val TAG = "VLibrasFlutter"
    }
}
