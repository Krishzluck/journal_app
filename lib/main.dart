import 'package:flutter/material.dart';
import 'package:journal_app/providers/auth_provider.dart';
import 'package:journal_app/providers/journal_provider.dart';
import 'package:journal_app/screens/auth_wrapper.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Journal App',
      theme: ThemeData(
        primaryColor: Color(0xFF4D6BFE),
        primarySwatch: MaterialColor(0xFF4D6BFE, {
          50: Color(0xFFEEF1FF),
          100: Color(0xFFD4DCFF),
          200: Color(0xFFB7C5FF),
          300: Color(0xFF9AADFF),
          400: Color(0xFF839CFF),
          500: Color(0xFF4D6BFE),
          600: Color(0xFF4763E5),
          700: Color(0xFF3F57CC),
          800: Color(0xFF374BB2),
          900: Color(0xFF2F3F99),
        }),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF4D6BFE),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        colorScheme: ColorScheme.light(
          primary: Color(0xFF4D6BFE),
          onPrimary: Colors.white,
        ),
      ),
      home: AuthWrapper(),
    );
  }
}