import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/wallet/domain/qr_model.dart';

class BankDeepLinkService {
  /// Stages payment details on the clipboard (auto-purged after 60s per the
  /// spec's clipboard-security requirement) then hands off to the target
  /// bank/e-wallet app, falling back to its store listing if not installed.
  static Future<bool> stageAndLaunch({
    required String provider,
    required String clipboardText,
  }) async {
    final links = bankDeepLinks[provider];
    if (links == null) return false;

    await Clipboard.setData(ClipboardData(text: clipboardText));
    Timer(const Duration(seconds: 60), () {
      Clipboard.setData(const ClipboardData(text: ''));
    });

    final appUri = Uri.parse(links['scheme']!);
    if (await canLaunchUrl(appUri)) {
      return launchUrl(appUri, mode: LaunchMode.externalApplication);
    }

    final storeKey = defaultTargetPlatform == TargetPlatform.iOS ? 'storeIos' : 'storeAndroid';
    return launchUrl(Uri.parse(links[storeKey]!), mode: LaunchMode.externalApplication);
  }
}