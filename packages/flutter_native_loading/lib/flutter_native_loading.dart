import 'dart:async';

import 'package:flutter/services.dart';

class FlutterNativeLoading {
  static const MethodChannel _channel =
      const MethodChannel('flutter_native_loading');

  static Future<void> show() async {
    try {
      await _channel.invokeMethod('showLoading');
    } catch(e) {}
  }

  static Future<void> hide() async {
    try {
      await _channel.invokeMethod('hideLoading');
    } catch(e) {}
  }
}
