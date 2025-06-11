import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paisa_app/screens/index.dart';
import './routes.dart' as routes;
import 'package:dynamic_color/dynamic_color.dart';

void main() {
  runApp(const MainApp());
}

ColorScheme _generateColorScheme(
  Color? primaryColor, [
  Brightness? brightness,
]) {
  final Color seedColor = primaryColor ?? Colors.blue;

  final ColorScheme newScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: brightness ?? Brightness.light,
  );

  return newScheme.harmonized();
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final ColorScheme lightScheme = _generateColorScheme(
          lightDynamic?.primary,
        );
        final ColorScheme darkScheme = _generateColorScheme(
          darkDynamic?.primary,
          Brightness.dark,
        );

        return MaterialApp(
          theme: ThemeData(
            colorScheme: lightScheme,
            useMaterial3: true,
            textTheme: GoogleFonts.robotoTextTheme(Theme.of(context).textTheme),
          ),
          darkTheme: ThemeData(
            colorScheme: darkScheme,
            useMaterial3: true,
            textTheme: GoogleFonts.robotoTextTheme(Theme.of(context).textTheme),
          ),
          themeMode: ThemeMode.system,
          initialRoute: routes.initalRoute,
          routes: {
            routes.home: (context) => const TransactionsScreen(),
            routes.agent: (context) => const AgentScreen(),
          },
        );
      },
    );
  }
}
