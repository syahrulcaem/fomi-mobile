import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ExternalUrlLauncher {
  static const MethodChannel _androidChannel =
      MethodChannel('com.fomi/external_intent');

  static Future<bool> launch(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      debugPrint('[ExternalUrlLauncher] invalid url: $rawUrl');
      return false;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final launched = await _androidChannel.invokeMethod<bool>(
          'launchExternalUrl',
          <String, Object?>{'url': rawUrl},
        );
        if (launched == true) {
          return true;
        }
      } on PlatformException catch (error) {
        debugPrint('[ExternalUrlLauncher] Android intent failed: $error');
      } on MissingPluginException catch (error) {
        debugPrint('[ExternalUrlLauncher] Android channel missing: $error');
      }
    }

    try {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error) {
      debugPrint('[ExternalUrlLauncher] url_launcher failed: $error');
      return false;
    }
  }
}
