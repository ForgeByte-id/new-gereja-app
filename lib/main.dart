import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';
import 'src/core/app_colors.dart';
import 'src/core/api_client.dart';
import 'src/core/session_controller.dart';
import 'src/pages/home_router_page.dart';
import 'src/pages/login_page.dart';
import 'src/widgets/pwa_install_fab.dart';
import 'src/services/firebase_message_handler.dart' show setupFirebaseMessaging;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  // Setup Firebase messaging handlers for push notifications
  setupFirebaseMessaging();
  runApp(const GerejaApp());
}

class GerejaApp extends StatefulWidget {
  const GerejaApp({super.key});

  @override
  State<GerejaApp> createState() => _GerejaAppState();
}

class _GerejaAppState extends State<GerejaApp> {
  late final SessionController _session;
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    const envBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    final baseUrl = _resolveBaseUrl(envBaseUrl);
    _session = SessionController(apiClient: ApiClient(baseUrl: baseUrl));
    _session.bootstrap();
  }

  String _resolveBaseUrl(String envBaseUrl) {
    final trimmed = envBaseUrl.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }

    if (kIsWeb) {
      final host = Uri.base.host.toLowerCase();
      final isLocalHost =
          host == 'localhost' || host == '127.0.0.1' || host == '0.0.0.0';
      if (isLocalHost) {
        return 'http://localhost:8080/api/v1';
      }

      final origin =
          '${Uri.base.scheme}://${Uri.base.host}${Uri.base.hasPort ? ':${Uri.base.port}' : ''}';
      return '$origin/api/v1';
    }

    return 'https://api.gpi-yehuda.org/api/v1';
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  void _setDarkMode(bool darkMode) {
    setState(() {
      _themeMode = darkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lightScheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D3D3A),
          brightness: Brightness.light,
        ).copyWith(
          surface: const Color(0xFFFFFFFF),
          surfaceContainerLow: const Color(0xFFF7FAF9),
          surfaceContainer: const Color(0xFFF1F5F4),
          surfaceContainerHigh: const Color(0xFFEAF0EE),
          outlineVariant: const Color(0xFFD6DEDB),
        );
    final darkScheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D3D3A),
          brightness: Brightness.dark,
        ).copyWith(
          surface: const Color(0xFF1E1E1E),
          surfaceContainerLow: const Color(0xFF171717),
          surfaceContainer: const Color(0xFF1E1E1E),
          surfaceContainerHigh: const Color(0xFF2C2C2C),
          outlineVariant: const Color(0xFF3A3A3A),
        );

    final baseRadius = BorderRadius.circular(16);
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    );
    final inputBorderLight = OutlineInputBorder(
      borderRadius: baseRadius,
      borderSide: BorderSide(color: lightScheme.outlineVariant),
    );
    final inputBorderDark = OutlineInputBorder(
      borderRadius: baseRadius,
      borderSide: BorderSide(color: darkScheme.outlineVariant),
    );

    return AnimatedBuilder(
      animation: _session,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'GPI Yehuda',
          themeMode: _themeMode,
          builder: (context, child) {
            return Stack(
              children: [
                child ?? const SizedBox.shrink(),
                const PwaInstallFab(),
              ],
            );
          },
          theme: ThemeData(
            colorScheme: lightScheme,
            useMaterial3: true,
            fontFamily: 'Poppins',
            scaffoldBackgroundColor: const Color(0xFFF7FAF9),
            extensions: const [
              AppColors(
                success: Color(0xFF059669),
                danger: Color(0xFFDC2626),
                warning: Color(0xFFD97706),
                info: Color(0xFF2563EB),
                secondary: Color(0xFF475569),
              ),
            ],
            splashFactory: InkSparkle.splashFactory,
            appBarTheme: AppBarTheme(
              centerTitle: false,
              backgroundColor: lightScheme.surface,
              foregroundColor: lightScheme.onSurface,
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
            dividerTheme: DividerThemeData(color: lightScheme.outlineVariant),
            cardTheme: CardThemeData(
              color: lightScheme.surface,
              elevation: 0,
              margin: const EdgeInsets.symmetric(vertical: 4),
              shape: cardShape,
              clipBehavior: Clip.antiAlias,
            ),
            listTileTheme: ListTileThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              iconColor: lightScheme.primary,
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: lightScheme.surface,
              indicatorColor: lightScheme.primaryContainer,
              surfaceTintColor: Colors.transparent,
            ),
            drawerTheme: DrawerThemeData(
              backgroundColor: lightScheme.surface,
              shape: const RoundedRectangleBorder(),
            ),
            dataTableTheme: DataTableThemeData(
              headingRowColor: WidgetStatePropertyAll(
                lightScheme.surfaceContainerHigh,
              ),
              headingTextStyle: TextStyle(
                color: lightScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
              dividerThickness: 0.6,
              dataRowMinHeight: 56,
              headingRowHeight: 54,
              horizontalMargin: 12,
              columnSpacing: 18,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: lightScheme.surfaceContainerLow,
              border: inputBorderLight,
              enabledBorder: inputBorderLight,
              focusedBorder: OutlineInputBorder(
                borderRadius: baseRadius,
                borderSide: BorderSide(color: lightScheme.primary, width: 1.6),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
            iconButtonTheme: IconButtonThemeData(
              style: IconButton.styleFrom(
                backgroundColor: lightScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(borderRadius: baseRadius),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(borderRadius: baseRadius),
                side: BorderSide(color: lightScheme.outlineVariant),
              ),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: darkScheme,
            useMaterial3: true,
            fontFamily: 'Poppins',
            scaffoldBackgroundColor: const Color(0xFF121212),
            extensions: const [
              AppColors(
                success: Color(0xFF10B981),
                danger: Color(0xFFEF4444),
                warning: Color(0xFFF59E0B),
                info: Color(0xFF3B82F6),
                secondary: Color(0xFF64748B),
              ),
            ],
            splashFactory: InkSparkle.splashFactory,
            appBarTheme: AppBarTheme(
              centerTitle: false,
              backgroundColor: const Color(0xFF1E1E1E),
              foregroundColor: darkScheme.onSurface,
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
            dividerTheme: DividerThemeData(color: darkScheme.outlineVariant),
            cardTheme: CardThemeData(
              color: const Color(0xFF1E1E1E),
              elevation: 0,
              margin: const EdgeInsets.symmetric(vertical: 4),
              shape: cardShape,
              clipBehavior: Clip.antiAlias,
            ),
            listTileTheme: ListTileThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: const Color(0xFF1E1E1E),
              selectedTileColor: const Color(0xFF2C2C2C),
              iconColor: darkScheme.primary,
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: const Color(0xFF1E1E1E),
              indicatorColor: const Color(0xFF2C2C2C),
              surfaceTintColor: Colors.transparent,
            ),
            drawerTheme: const DrawerThemeData(
              backgroundColor: Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(),
            ),
            dataTableTheme: DataTableThemeData(
              headingRowColor: const WidgetStatePropertyAll(Color(0xFF2C2C2C)),
              headingTextStyle: TextStyle(
                color: darkScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
              dividerThickness: 0.6,
              dataRowMinHeight: 56,
              headingRowHeight: 54,
              horizontalMargin: 12,
              columnSpacing: 18,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              border: inputBorderDark,
              enabledBorder: inputBorderDark,
              focusedBorder: OutlineInputBorder(
                borderRadius: baseRadius,
                borderSide: BorderSide(color: darkScheme.primary, width: 1.6),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
            iconButtonTheme: IconButtonThemeData(
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF2C2C2C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(borderRadius: baseRadius),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(borderRadius: baseRadius),
                side: const BorderSide(color: Color(0xFF3A3A3A)),
              ),
            ),
          ),
          home: _session.initializing
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : _session.isAuthenticated
              ? HomeRouterPage(
                  session: _session,
                  darkMode: _themeMode == ThemeMode.dark,
                  onThemeChanged: _setDarkMode,
                )
              : LoginPage(session: _session),
        );
      },
    );
  }
}
