// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/foundation.dart';

class PwaInstallController extends ChangeNotifier {
  dynamic _deferredPrompt;
  bool _isInstalled = false;
  bool _isInitialized = false;
  bool _isIOS = false;

  late final void Function(dynamic event) _beforeInstallListener;
  late final void Function(dynamic event) _appInstalledListener;
  late final void Function(dynamic event) _installReadyListener;

  bool get canInstall => _deferredPrompt != null && !_isInstalled;

  bool get isIOS => _isIOS;

  bool get isInstalled => _isInstalled;

  bool get shouldShowIOSGuide => _isIOS && !_isInstalled;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    _isInitialized = true;
    _isInstalled = _detectInstalledMode();
    _isIOS = _detectIOS();

    _beforeInstallListener = (event) {
      _deferredPrompt = event;
      final dynamic promptEvent = event;
      try {
        promptEvent.preventDefault();
      } catch (_) {
      }
      notifyListeners();
    };

    _appInstalledListener = (_) {
      _isInstalled = true;
      _deferredPrompt = null;
      notifyListeners();
    };

    _installReadyListener = (event) {
      if (_deferredPrompt == null) {
        _deferredPrompt = (event as dynamic).detail;
        notifyListeners();
      }
    };

    html.window.addEventListener('beforeinstallprompt', _beforeInstallListener);
    html.window.addEventListener('appinstalled', _appInstalledListener);
    html.window.addEventListener('pwa-install-ready', _installReadyListener);

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

  bool _detectIOS() {
    final navigator = html.window.navigator;
    final userAgent = navigator.userAgent.toLowerCase();
    if (userAgent.contains('iphone') ||
        userAgent.contains('ipad') ||
        userAgent.contains('ipod')) {
      return true;
    }
    // iPadOS 13+ reports desktop Safari user agent
    if (userAgent.contains('macintosh') &&
        navigator.maxTouchPoints != null &&
        navigator.maxTouchPoints > 1) {
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    if (_isInitialized) {
      html.window.removeEventListener(
        'beforeinstallprompt',
        _beforeInstallListener,
      );
      html.window.removeEventListener('appinstalled', _appInstalledListener);
      html.window.removeEventListener(
        'pwa-install-ready',
        _installReadyListener,
      );
    }

    super.dispose();
  }
}
