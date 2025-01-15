package com.example.labs4

import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugins.flutterlocalnotifications.FlutterLocalNotificationsPlugin

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine() {
        super.configureFlutterEngine()
        // Register the plugin explicitly (for older Flutter versions or if auto registration fails)
        FlutterLocalNotificationsPlugin.registerWith(registrarFor("io.flutter.plugins.flutterlocalnotifications.FlutterLocalNotificationsPlugin"))
    }
}
