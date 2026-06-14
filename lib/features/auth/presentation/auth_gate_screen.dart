import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../auth/data/auth_repository.dart';
import '../../../shared/widgets/loading_view.dart';

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  final _authRepository = AuthRepository();

  late final Future<bool> _isAuthenticatedFuture;

  @override
  void initState() {
    super.initState();
    _isAuthenticatedFuture = _checkSession();
  }

  Future<bool> _checkSession() async {
    final user = await _authRepository.bootstrapUser();
    return user != null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAuthenticatedFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: LoadingView(),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;

          if (snapshot.data == true) {
            context.go('/home');
          } else {
            context.go('/login');
          }
        });

        return const Scaffold(
          body: LoadingView(),
        );
      },
    );
  }
}
