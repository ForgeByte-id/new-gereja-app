// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/foundation.dart';

class PwaInstallController extends ChangeNotifier {
  dynamic _deferredPrompt;
  bool _isInstalled = false;
  bool _isInitialized = false;

  late final void Function(dynamic event) _beforeInstallListener;
  late final void Function(dynamic event) _appInstalledListener;

  bool get canInstall => _deferredPrompt != null && !_isInstalled;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    _isInitialized = true;
    _isInstalled = _detectInstalledMode();

    _beforeInstallListener = (event) {
      _deferredPrompt = event;
      final dynamic promptEvent = event;
      try {
        promptEvent.preventDefault();
      } catch (_) {
        // Some browsers may not expose preventDefault on this event shape.
      }
      notifyListeners();
    };

    _appInstalledListener = (_) {
      _isInstalled = true;
      _deferredPrompt = null;
      notifyListeners();
    };

    html.window.addEventListener('beforeinstallprompt', _beforeInstallListener);
    html.window.addEventListener('appinstalled', _appInstalledListener);

    notifyListeners();
  }

  Future<void> promptInstall() async {
    final promptEvent = _deferredPrompt;
    if (promptEvent == null) {
      return;
    }

    try {
      promptEvent.prompt();
    } catch (_) {
      _deferredPrompt = null;
      notifyListeners();
      return;
    }

    final userChoice = promptEvent.userChoice;
    if (userChoice != null) {
      try {
        await userChoice;
      } catch (_) {
        // Browser/user can reject the prompt. Keep behavior silent.
      }
    }

    _deferredPrompt = null;
    notifyListeners();
  }

  bool _detectInstalledMode() {
    final mediaStandalone = html.window
        .matchMedia('(display-mode: standalone)')
        .matches;
    final dynamic navigator = html.window.navigator;
    bool iosStandalone = false;

    try {
      iosStandalone = navigator.standalone == true;
    } catch (_) {
      iosStandalone = false;
    }

    return mediaStandalone || iosStandalone;
  }

  @override
  void dispose() {
    if (_isInitialized) {
      html.window.removeEventListener(
        'beforeinstallprompt',
        _beforeInstallListener,
      );
      html.window.removeEventListener('appinstalled', _appInstalledListener);
    }

    super.dispose();
  }
}
