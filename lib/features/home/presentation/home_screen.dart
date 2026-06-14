import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../auth/data/auth_repository.dart';
import '../../../core/auth/current_user.dart';
import '../../../shared/widgets/loading_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authRepository = AuthRepository();

  late Future<CurrentUser?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _authRepository.readCurrentUser();
  }

  Future<void> _logout() async {
    await _authRepository.logout();

    if (!mounted) return;

    context.go('/login');
  }

  String _roleTitle(String role) {
    return switch (role) {
      'OWNER' => 'Direktor paneli',
      'MANAGER' => 'Manager paneli',
      'SALES' => 'Sotuvchi paneli',
      'OPERATOR' => 'Operator paneli',
      'WAREHOUSE' => 'Sklad paneli',
      'DELIVERY' => 'Yetkazuvchi paneli',
      _ => 'Sales OS',
    };
  }

  String _roleTask(String role) {
    return switch (role) {
      'OWNER' => 'Bugungi zakazlar, qarzlar va ish jarayonini nazorat qiling.',
      'MANAGER' => 'Zakazlar oqimi va xodimlar ishini boshqaring.',
      'SALES' => 'Mijozlar va o‘zingiz yaratgan zakazlar bilan ishlang.',
      'OPERATOR' => 'Yangi zakazlarni tekshiring va tasdiqlang.',
      'WAREHOUSE' => 'Tasdiqlangan zakazlarni tayyorlang va yo‘lga chiqaring.',
      'DELIVERY' => 'Yo‘ldagi zakazlarni yetkazilgan holatga o‘tkazing.',
      _ => 'Ish jarayonini davom ettiring.',
    };
  }

  String _primaryActionLabel(String role) {
    return switch (role) {
      'SALES' => 'Mening zakazlarim',
      'OPERATOR' => 'Tekshiriladigan zakazlar',
      'WAREHOUSE' => 'Sklad zakazlari',
      'DELIVERY' => 'Yetkazish zakazlari',
      _ => 'Zakazlarni ko‘rish',
    };
  }

  IconData _roleIcon(String role) {
    return switch (role) {
      'OWNER' => Icons.admin_panel_settings_rounded,
      'MANAGER' => Icons.manage_accounts_rounded,
      'SALES' => Icons.handshake_rounded,
      'OPERATOR' => Icons.fact_check_rounded,
      'WAREHOUSE' => Icons.warehouse_rounded,
      'DELIVERY' => Icons.local_shipping_rounded,
      _ => Icons.apps_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CurrentUser?>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: LoadingView(),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go('/login');
            }
          });

          return const Scaffold(
            body: LoadingView(),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text('Sales OS'),
            actions: [
              IconButton(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeroHomeCard(
                title: _roleTitle(user.role),
                subtitle: _roleTask(user.role),
                icon: _roleIcon(user.role),
                user: user,
              ),
              const SizedBox(height: 14),
              _PrimaryActionCard(
                label: _primaryActionLabel(user.role),
                description: 'Real serverdagi zakazlar ro‘yxatini ochish',
                icon: Icons.receipt_long_rounded,
                onTap: () => context.go('/orders'),
              ),
              const SizedBox(height: 14),
              _InfoGrid(
                role: user.role,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroHomeCard extends StatelessWidget {
  const _HeroHomeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.user,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final CurrentUser user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${user.fullName} • ${user.role}',
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryActionCard extends StatelessWidget {
  const _PrimaryActionCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({
    required this.role,
  });

  final String role;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniInfoCard(
            title: 'Server',
            value: 'Render',
            icon: Icons.cloud_done_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniInfoCard(
            title: 'Role',
            value: role,
            icon: Icons.verified_user_rounded,
          ),
        ),
      ],
    );
  }
}

class _MiniInfoCard extends StatelessWidget {
  const _MiniInfoCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: const Color(0xFF475569),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
