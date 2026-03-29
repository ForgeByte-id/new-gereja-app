import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'device_identity.dart';
import 'fcm_bootstrap_service.dart';
import 'models.dart';
import '../services/firebase_message_handler.dart';

class SessionController extends ChangeNotifier {
  SessionController({
    required this.apiClient,
    FcmBootstrapService? fcmBootstrapService,
  }) : _fcmBootstrapService = fcmBootstrapService ?? FcmBootstrapService();

  static const _tokenKey = 'auth_token';
  static const _roleKey = 'user_role';

  final ApiClient apiClient;
  final FcmBootstrapService _fcmBootstrapService;

  bool initializing = true;
  bool isAuthenticated = false;
  bool busy = false;
  String? token;
  String? fcmToken;
  bool usingDummyFcm = true;
  String fcmSource = 'unknown';
  UserRole role = UserRole.jemaat;
  Map<String, dynamic> me = <String, dynamic>{};

  Future<void> bootstrap() async {
    // Setup Firebase messaging handlers
    setupFirebaseMessaging();

    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_tokenKey);
    role = parseRole(prefs.getString(_roleKey));

    if (token == null || token!.isEmpty) {
      initializing = false;
      notifyListeners();
      return;
    }

    try {
      me = await apiClient.me(token!);
      role = parseRole(me['role'] as String?);
      isAuthenticated = true;
    } catch (_) {
      await _clearPrefs();
      token = null;
      isAuthenticated = false;
      me = <String, dynamic>{};
    }

    initializing = false;
    notifyListeners();
  }

  Future<void> signIn({
    required String username,
    required String password,
    String? preferredDeviceToken,
  }) async {
    busy = true;
    notifyListeners();

    try {
      final fcmBootstrap = await _fcmBootstrapService.resolveToken(
        preferredToken: preferredDeviceToken,
      );
      final deviceToken = fcmBootstrap.token;
      final session = await apiClient.login(
        username: username,
        password: password,
        fcmToken: deviceToken,
      );
      token = session.token;
      fcmToken = deviceToken;
      usingDummyFcm = fcmBootstrap.isDummy;
      fcmSource = fcmBootstrap.source;
      role = session.role;
      me = session.user;

      await apiClient.registerDevice(
        token: token!,
        deviceToken: deviceToken,
        deviceType: DeviceIdentity.deviceType,
        deviceName: 'Flutter ${DeviceIdentity.deviceType.toUpperCase()}',
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token!);
      await prefs.setString(_roleKey, role.name);
      isAuthenticated = true;

      // Subscribe to Firebase topics after successful login
      subscribeToFirebaseTopics(role.name, me['id'] as int? ?? 0);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> signUp({
    required String username,
    required String email,
    required String password,
    required String nomorKk,
    required String phoneNumber,
    String? name,
    String? jenisKelamin,
    int? usia,
    String? alamat,
    String? preferredDeviceToken,
  }) async {
    busy = true;
    notifyListeners();

    try {
      final fcmBootstrap = await _fcmBootstrapService.resolveToken(
        preferredToken: preferredDeviceToken,
      );
      final deviceToken = fcmBootstrap.token;
      final session = await apiClient.register(
        username: username,
        email: email,
        password: password,
        nomorKk: nomorKk,
        phoneNumber: phoneNumber,
        fcmToken: deviceToken,
        name: name,
        jenisKelamin: jenisKelamin,
        usia: usia,
        alamat: alamat,
      );

      token = session.token;
      fcmToken = deviceToken;
      usingDummyFcm = fcmBootstrap.isDummy;
      fcmSource = fcmBootstrap.source;
      role = session.role;
      me = session.user;

      await apiClient.registerDevice(
        token: token!,
        deviceToken: deviceToken,
        deviceType: DeviceIdentity.deviceType,
        deviceName: 'Flutter ${DeviceIdentity.deviceType.toUpperCase()}',
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token!);
      await prefs.setString(_roleKey, role.name);
      isAuthenticated = true;

      // Subscribe to Firebase topics after successful registration
      subscribeToFirebaseTopics(role.name, session.user['id'] as int? ?? 0);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    // Unsubscribe from Firebase topics before logout
    unsubscribeFromTopics(role.name, me['id'] as int? ?? 0);
    // Unsubscribe from Firebase topics before logout
    unsubscribeFromTopics(role.name, me['id'] as int? ?? 0);

    final oldToken = token;
    await _clearPrefs();

    token = null;
    fcmToken = null;
    usingDummyFcm = true;
    fcmSource = 'unknown';
    isAuthenticated = false;
    me = <String, dynamic>{};
    notifyListeners();

    if (oldToken != null && oldToken.isNotEmpty) {
      try {
        await apiClient.logout(oldToken);
      } catch (_) {
        // Best effort logout.
      }
    }
  }

  void updateCurrentUser(Map<String, dynamic> userData) {
    me = userData;
    role = parseRole(userData['role'] as String?);
    notifyListeners();
  }

  Future<void> _clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
  }
}
