import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/todo_list_screen.dart';
import 'screens/splash_screen.dart';
import 'providers/todo_provider.dart';
import 'providers/theme_mode_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await NotificationService.initialize();

  final prefs = await SharedPreferences.getInstance();
  final savedThemeMode = prefs.getInt('theme_mode') ?? 0;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TodoProvider()),
        ChangeNotifierProvider(create: (context) => ThemeModeProvider(savedThemeMode)),
      ],
      child: const HabitsPlusPlus(),
    ),
  );
}

class HabitsPlusPlus extends StatelessWidget {
  const HabitsPlusPlus({super.key});

  @override
  Widget build(BuildContext context) {
    final themeModeProvider = Provider.of<ThemeModeProvider>(context);

    // Define a base color scheme
    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.light,
    );

    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
    );

    // Create text themes with Poppins font
    final lightTextTheme = GoogleFonts.poppinsTextTheme(
      ThemeData.light().textTheme,
    );

    final darkTextTheme = GoogleFonts.poppinsTextTheme(
      ThemeData.dark().textTheme,
    );

    return MaterialApp(
      title: 'Habits++',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: lightColorScheme,
        textTheme: lightTextTheme,
        useMaterial3: true,
        brightness: Brightness.light,
        appBarTheme: AppBarTheme(
          backgroundColor: lightColorScheme.surface,
          foregroundColor: lightColorScheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: lightColorScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: lightColorScheme.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: lightColorScheme.primary, width: 2),
          ),
          hintStyle: GoogleFonts.poppins(
            color: lightColorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
          labelStyle: GoogleFonts.poppins(
            color: lightColorScheme.onSurfaceVariant,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: lightColorScheme.primary,
            foregroundColor: lightColorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: darkColorScheme,
        textTheme: darkTextTheme,
        useMaterial3: true,
        brightness: Brightness.dark,
        appBarTheme: AppBarTheme(
          backgroundColor: darkColorScheme.surface,
          foregroundColor: darkColorScheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: darkColorScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: darkColorScheme.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: darkColorScheme.primary, width: 2),
          ),
          hintStyle: GoogleFonts.poppins(
            color: darkColorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
          labelStyle: GoogleFonts.poppins(
            color: darkColorScheme.onSurfaceVariant,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: darkColorScheme.primary,
            foregroundColor: darkColorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      themeMode: themeModeProvider.themeMode,
      home: const SplashScreen(),
    );
  }
}
