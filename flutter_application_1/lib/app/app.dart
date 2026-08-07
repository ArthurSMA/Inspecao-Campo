import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/network/api_client.dart';
import 'package:flutter_application_1/core/storage/token_storage.dart';
import 'package:flutter_application_1/feat/auth/data/models/login_response.dart';
import 'package:flutter_application_1/feat/auth/data/services/auth_service.dart';
import 'package:flutter_application_1/feat/auth/presentation/pages/login_page.dart';
import 'package:flutter_application_1/feat/home/presentation/pages/home_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inspeção de Campo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF9F9FF),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xfF00478D),
          primary: const Color(0xfF00478D),
          surface: Colors.white,
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xfFF9F9FF),

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xfF00478D), width: 2),
          ),

          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xfFBA1A1A)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF00478D),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final TokenStorage _tokenStorage = const TokenStorage();
  late final AuthService _authService;

  AuthUser? _user;
  bool _isCheckingSession = true;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(ApiClient());
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        return;
      }

      final user = await _authService.getCurrentUser(token);
      if (mounted) {
        setState(() => _user = user);
      }
    } on AuthException catch (error) {
      if (error.shouldClearSession) {
        await _tokenStorage.deleteToken();
      }
    } catch (_) {
      // Storage failures and malformed persisted data must not expose HomePage.
    } finally {
      if (mounted) {
        setState(() => _isCheckingSession = false);
      }
    }
  }

  void _handleLogin(AuthUser user) {
    setState(() => _user = user);
  }

  Future<void> _logout() async {
    await _tokenStorage.deleteToken();
    if (mounted) setState(() => _user = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingSession) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = _user;
    if (user == null) {
      return LoginPage(onLogin: _handleLogin);
    }

    return HomePage(
      userName: user.name,
      onLogout: _logout,
      onSessionInvalid: _logout,
    );
  }
}
