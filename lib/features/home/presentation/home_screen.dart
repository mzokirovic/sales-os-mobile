import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/current_user.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/data/auth_repository.dart';
import '../../dashboard/dashboard_model.dart';
import '../../dashboard/dashboard_repository.dart';
import '../../orders/order_status_policy.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authRepository = AuthRepository();
  final _dashboardRepository = DashboardRepository();

  late Future<_HomeData> _homeFuture;

  @override
  void initState() {
    super.initState();
    _homeFuture = _loadHome();
  }

  Future<_HomeData> _loadHome() async {
    final user = await _authRepository.readCurrentUser();

    if (user == null) {
      throw const HomeException('Session topilmadi. Qayta login qiling.');
    }

    final summary = await _dashboardRepository.getSummary();

    return _HomeData(
      user: user,
      summary: summary,
    );
  }

  void _reload() {
    setState(() {
      _homeFuture = _loadHome();
    });
  }

  Future<void> _logout() async {
    await _authRepository.logout();

    if (!mounted) return;

    context.go('/login');
  }

  String _formatMoney(num value) {
    return '${value.toInt().toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ' ',
        )} so‘m';
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
      'OWNER' => 'Savdo, qarz va zakaz oqimini nazorat qiling.',
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
    return FutureBuilder<_HomeData>(
      future: _homeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: LoadingView(),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Sales OS'),
              actions: [
                IconButton(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded),
                ),
              ],
            ),
            body: ErrorView(
              message: snapshot.error.toString(),
              onRetry: _reload,
            ),
          );
        }

        final data = snapshot.data;

        if (data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Sales OS')),
            body: ErrorView(
              message: 'Home ma’lumoti topilmadi',
              onRetry: _reload,
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text('Sales OS'),
            actions: [
              IconButton(
                onPressed: _reload,
                icon: const Icon(Icons.refresh_rounded),
              ),
              IconButton(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeroHomeCard(
                  title: _roleTitle(data.user.role),
                  subtitle: _roleTask(data.user.role),
                  icon: _roleIcon(data.user.role),
                  user: data.user,
                ),
                const SizedBox(height: 14),
                _DashboardMetrics(
                  summary: data.summary,
                  formatMoney: _formatMoney,
                ),
                const SizedBox(height: 14),
                _PrimaryActionCard(
                  label: _primaryActionLabel(data.user.role),
                  description: 'Real serverdagi zakazlar ro‘yxatini ochish',
                  icon: Icons.receipt_long_rounded,
                  onTap: () => context.go('/orders'),
                ),
                const SizedBox(height: 14),
                _StatusBreakdownCard(
                  summary: data.summary,
                ),
                const SizedBox(height: 14),
                _RecentOrdersCard(
                  summary: data.summary,
                  formatMoney: _formatMoney,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HomeData {
  const _HomeData({
    required this.user,
    required this.summary,
  });

  final CurrentUser user;
  final DashboardSummary summary;
}

class HomeException implements Exception {
  const HomeException(this.message);

  final String message;

  @override
  String toString() => message;
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

class _DashboardMetrics extends StatelessWidget {
  const _DashboardMetrics({
    required this.summary,
    required this.formatMoney,
  });

  final DashboardSummary summary;
  final String Function(num value) formatMoney;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Savdo',
                value: formatMoney(summary.totalSales),
                icon: Icons.trending_up_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                title: 'Ochiq qarz',
                value: formatMoney(summary.openDebt),
                icon: Icons.warning_amber_rounded,
                isDanger: summary.openDebt > 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Zakazlar',
                value: summary.ordersCount.toString(),
                icon: Icons.receipt_long_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                title: 'Mijozlar',
                value: summary.customersCount.toString(),
                icon: Icons.groups_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    this.isDanger = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final bool isDanger;

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
              color: isDanger ? const Color(0xFFDC2626) : const Color(0xFF475569),
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
              style: TextStyle(
                color: isDanger ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
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

class _StatusBreakdownCard extends StatelessWidget {
  const _StatusBreakdownCard({
    required this.summary,
  });

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final items = summary.statusBreakdown;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statuslar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Text(
                'Status statistikasi hali yo‘q',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              ...items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          OrderStatusPolicy.label(item.status),
                          style: const TextStyle(
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          item.count.toString(),
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _RecentOrdersCard extends StatelessWidget {
  const _RecentOrdersCard({
    required this.summary,
    required this.formatMoney,
  });

  final DashboardSummary summary;
  final String Function(num value) formatMoney;

  @override
  Widget build(BuildContext context) {
    final orders = summary.recentOrders;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'So‘nggi zakazlar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            if (orders.isEmpty)
              const Text(
                'Hozircha zakazlar yo‘q',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              ...orders.map((order) {
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.go('/orders/${order.id}'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.customer.name,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${OrderStatusPolicy.label(order.status)} • ${formatMoney(order.totalAmount)}',
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
                          size: 16,
                          color: Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
