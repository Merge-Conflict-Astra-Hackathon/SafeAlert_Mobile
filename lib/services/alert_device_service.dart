import 'package:flutter/services.dart';

class AlertDeviceService {
  static const MethodChannel _channel = MethodChannel('safealert/device_alert');

  Future<void> activateAlertMode() async {
    try {
      await _channel.invokeMethod<void>('activateAlertMode');
    } on MissingPluginException {
      // Non-Android targets do not support this native alert mode.
    } on PlatformException {
      // Keep the emergency screen usable even if the OS blocks volume changes.
    }
  }

  Future<void> restoreAlertMode() async {
    try {
      await _channel.invokeMethod<void>('restoreAlertMode');
    } on MissingPluginException {
      // Non-Android targets do not support this native alert mode.
    } on PlatformException {
      // Nothing actionable for the user here; returning to the app is safer.
    }
  }
}
