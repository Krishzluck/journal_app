import 'package:flutter/material.dart';
import 'package:journal_app/firebase_options.dart';
import 'package:journal_app/providers/auth_provider.dart';
import 'package:journal_app/providers/blocked_users_provider.dart';
import 'package:journal_app/providers/follow_provider.dart';
import 'package:journal_app/providers/journal_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:journal_app/screens/splash_screen.dart';
import 'package:journal_app/providers/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://fpwokldgmdwikejniuxz.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZwd29rbGRnbWR3aWtlam5pdXh6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzgxMzUzNDAsImV4cCI6MjA1MzcxMTM0MH0.ocpnHjXorEK8xvkQlO_mc3G1TLt3F9qOBywUH2xgA50',
  );
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

    await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => JournalProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => BlockedUsersProvider()),
        ChangeNotifierProvider(create: (_) => FollowProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Journal App',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: themeProvider.themeData,
      darkTheme: themeProvider.themeData,
      navigatorKey: navigatorKey,
      home: const SplashScreen(),
    );
  }
}