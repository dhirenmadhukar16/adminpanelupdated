import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth/screens/admin_login_screen.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'navigation/admin_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.init();

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  final isLoggedIn = token != null && token.isNotEmpty;

  runApp(
    ProviderScope(
      child: WhiteFoxAdminPanel(isLoggedIn: isLoggedIn),
    ),
  );
}

class WhiteFoxAdminPanel extends StatelessWidget {
  final bool isLoggedIn;
  const WhiteFoxAdminPanel({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WhiteFox Admin Panel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: isLoggedIn ? const AdminShell() : const AdminLoginScreen(),
    );
  }
}
