import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paisa_app/screens/index.dart';
import 'package:provider/provider.dart';
import 'package:paisa_app/screens/agent/agent_provider.dart';
import 'package:paisa_app/providers/background_service_status_provider.dart';
import './routes.dart' as routes;
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_logs/flutter_logs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FlutterLogs.initLogs(
    logLevelsEnabled: [
      LogLevel.INFO,
      LogLevel.WARNING,
      LogLevel.ERROR,
      LogLevel.SEVERE,
    ],
    timeStampFormat: TimeStampFormat.DATE_FORMAT_1,
    logSystemCrashes: true,
    directoryStructure: DirectoryStructure.FOR_DATE,
    logTypesEnabled: ["device", "network", "errors"],
    logFileExtension: LogFileExtension.CSV,
    debugFileOperations: true,
    isDebuggable: true,
    logsRetentionPeriodInDays: 14,
    zipsRetentionPeriodInDays: 3,
    autoDeleteZipOnExport: false,
    enabled: true,
  );

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

        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (context) => AgentProvider()),
            ChangeNotifierProvider(create: (context) => TransactionsProvider()),
            ChangeNotifierProvider(
              create: (context) {
                final provider = BackgroundServiceStatusProvider();
                // Start monitoring automatically when provider is created
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  provider.startStatusMonitoring();
                });
                return provider;
              },
            ),
          ],
          child: MaterialApp(
            theme: ThemeData(
              colorScheme: lightScheme,
              useMaterial3: true,
              textTheme: GoogleFonts.robotoTextTheme(
                Theme.of(context).textTheme,
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: darkScheme,
              useMaterial3: true,
              textTheme: GoogleFonts.robotoTextTheme(
                Theme.of(context).textTheme,
              ),
            ),
            themeMode: ThemeMode.system,
            initialRoute: routes.initalRoute,
            routes: {
              routes.transactions: (context) => const TransactionsScreen(),
              routes.agent: (context) => const AgentScreen(),
            },
          ),
        );
      },
    );
  }
}
