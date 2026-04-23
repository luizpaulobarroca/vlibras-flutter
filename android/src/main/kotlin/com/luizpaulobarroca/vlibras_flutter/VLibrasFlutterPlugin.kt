package com.luizpaulobarroca.vlibras_flutter

import io.flutter.embedding.engine.plugins.FlutterPlugin

/**
 * Stub Android plugin for vlibras_flutter.
 *
 * The package has no native Android code — all behavior lives in Dart on top
 * of webview_flutter. This class exists only so the Flutter tool registers the
 * package as an Android plugin, which in turn causes the Android manifest
 * merger to pick up src/main/AndroidManifest.xml (INTERNET permission +
 * network security config for 127.0.0.1 cleartext).
 */
class VLibrasFlutterPlugin : FlutterPlugin {
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {}
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {}
}
