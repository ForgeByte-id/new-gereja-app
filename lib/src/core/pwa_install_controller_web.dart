import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';

@JS('window.__pwa.canInstall')
external bool get _jsCanInstall;

@JS('window.__pwa.installed')
external bool get _jsInstalled;

@JS('window.__pwa.isIOS')
external bool get _jsIsIOS;

@JS('window.pwaPollChanged')
external bool Function() get _pwaPollChanged;

@JS('window.pwaPromptInstall')
external void Function() get _pwaPromptInstall;

class PwaInstallController extends ChangeNotifier {
  bool _isInitialized = false;
  Timer? _pollTimer;

  bool get canInstall => _jsCanInstall && !_jsInstalled;

  bool get isIOS => _jsIsIOS;

  bool get isInstalled => _jsInstalled;

  bool get shouldShowIOSGuide => _jsIsIOS && !_jsInstalled;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    _startPolling();
    notifyListeners();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_pwaPollChanged()) {
        notifyListeners();
      }
    });
  }

  Future<void> promptInstall() async {
    _pwaPromptInstall();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
