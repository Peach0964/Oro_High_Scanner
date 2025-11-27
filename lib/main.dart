import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'core/services/theme_service.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/scanner/scanner_screen.dart' show MainTabsScreen;
import 'presentation/screens/records/records_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'generate_qr_code/generate_qr_code_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env (root)
  await dotenv.load(fileName: '.env');

  // Only initialize Supabase when both URL and a plausible anon key are present.
  // This prevents 401 "Invalid API key" errors when the key is missing/placeholder.
  final String? supabaseUrl = dotenv.maybeGet('SUPABASE_URL');
  final String? supabaseAnonKey = dotenv.maybeGet('SUPABASE_ANON_KEY');

  bool hasValidUrl = supabaseUrl != null && supabaseUrl.isNotEmpty;
  // A valid anon key is a JWT with at least 3 dot-separated parts.
  bool hasValidAnon = supabaseAnonKey != null &&
      supabaseAnonKey.isNotEmpty &&
      supabaseAnonKey.split('.').length >= 3;

  if (hasValidUrl && hasValidAnon) {
    await Supabase.initialize(
      url: supabaseUrl!,
      anonKey: supabaseAnonKey!,
    );
  } else {
    // Skip Supabase so the app falls back to demo login instead of throwing 401s.
    debugPrint(
        '[Supabase] Skipped initialization (missing/invalid SUPABASE_URL or SUPABASE_ANON_KEY in .env). Using demo auth.');
  }

  runApp(const OroHighScannerApp());
}

class OroHighScannerApp extends StatelessWidget {
  const OroHighScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, child) {
        return MaterialApp(
          title: AppStrings.appTitle,
          debugShowCheckedModeBanner: false,
          themeMode: ThemeService().themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            fontFamily: 'Roboto',
            scaffoldBackgroundColor: AppColors.backgroundLight,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textDark,
              elevation: 0,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
              brightness: Brightness.dark,
              surface: const Color(0xFF1C1C1E), // iOS Dark Surface
              onSurface: Colors.white,
            ),
            useMaterial3: true,
            fontFamily: 'Roboto',
            scaffoldBackgroundColor:
                const Color(0xFF000000), // iOS Dark Background
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1C1C1E),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            // cardTheme removed to fix type error
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[800]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.accent, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[800]!),
              ),
              filled: true,
              fillColor: const Color(0xFF2C2C2E),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => const LoginScreen(),
            '/login': (context) => const LoginScreen(),
            '/scanner': (context) => const MainTabsScreen(),
            '/records': (context) => const RecordsPage(users: [], logs: []),
            '/settings': (context) => const SettingsScreen(),
            '/generate-qr': (context) => const GenerateQRCodeScreen(),
          },
          onGenerateRoute: (settings) {
            // Handle any dynamic routes or routes with arguments here
            switch (settings.name) {
              case '/records':
                // If you need to pass arguments to records screen
                final args = settings.arguments as Map<String, dynamic>?;
                if (args != null) {
                  // Handle arguments if needed
                  return MaterialPageRoute(
                    builder: (context) =>
                        const RecordsPage(users: [], logs: []),
                  );
                }
                break;
            }

            // Fallback to login for unknown routes
            return MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            );
          },
        );
      },
    );
  }
}
