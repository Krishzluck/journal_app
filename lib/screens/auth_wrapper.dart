import 'package:flutter/material.dart';
import 'package:journal_app/providers/auth_provider.dart';
import 'package:journal_app/screens/auth_page.dart';
import 'package:journal_app/screens/home_page.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.userProfile != null) {
          return HomePage();
        } else {
          return AuthPage();
        }
      },
    );
  }
}

