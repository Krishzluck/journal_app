import 'package:flutter/material.dart';
import 'package:journal_app/providers/auth_provider.dart';
import 'package:journal_app/providers/journal_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:journal_app/screens/splash_screen.dart';
import 'package:journal_app/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // await Supabase.initialize(
  //   url: 'https://ssyzhnqtkvgmmqzmkqnl.supabase.co',
  //   anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNzeXpobnF0a3ZnbW1xem1rcW5sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzc5ODAxODYsImV4cCI6MjA1MzU1NjE4Nn0.ns6EqdptDVUb6a9gWWM6g9wULZNMn88SZC1z8NOpeR0',
  // );
  await Supabase.initialize(
    url: 'https://fpwokldgmdwikejniuxz.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZwd29rbGRnbWR3aWtlam5pdXh6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzgxMzUzNDAsImV4cCI6MjA1MzcxMTM0MH0.ocpnHjXorEK8xvkQlO_mc3G1TLt3F9qOBywUH2xgA50',
  );

    await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => JournalProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
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
      home: const SplashScreen(),
    );
  }
}