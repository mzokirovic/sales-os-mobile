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
      throw const HomeException('Session topilmadi');
    }

    final summary = await _dashboardRepository.getSummary();

    return _HomeData(user: user, summary: summary);
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

  String _roleName(String role) {
    return switch (role) {
      'OWNER' => 'Direktor',
      'MANAGER' => 'Manager',
      'SALES' => 'Sotuvchi',
      'OPERATOR' => 'Operator',
      'WAREHOUSE' => 'Sklad',
      'DELIVERY' => 'Yetkazuvchi',
      _ => role,
    };
  }

  String _roleFocus(String role) {
    return switch (role) {
      'OWNER' => 'Nazorat',
      'MANAGER' => 'Boshqaruv',
      'SALES' => 'Mijozlar',
      'OPERATOR' => 'Tekshiruv',
      'WAREHOUSE' => 'Sklad',
      'DELIVERY' => 'Yetkazish',
      _ => 'Ish paneli',
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HomeData>(
      future: _homeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: LoadingView());
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
              message: 'Ma’lumot topilmadi',
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
                _CompactHeader(
                  user: data.user,
                  roleName: _roleName(data.user.role),
                  roleFocus: _roleFocus(data.user.role),
                ),
                const SizedBox(height: 12),
                _MetricGrid(
                  summary: data.summary,
                  formatMoney: _formatMoney,
                ),
                const SizedBox(height: 12),
                _MainActionCard(
                  onTap: () => context.go('/orders'),
                ),
                const SizedBox(height: 12),
                _CustomersActionCard(
                  onTap: () => context.go('/customers'),
                ),
                const SizedBox(height: 12),
                _ProductsActionCard(
                  onTap: () => context.go('/products'),
                ),
                const SizedBox(height: 12),
                _StatusRow(summary: data.summary),
                const SizedBox(height: 12),
                _RecentOrders(
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

class _CompactHeader extends StatelessWidget {
  const _CompactHeader({
    required this.user,
    required this.roleName,
    required this.roleFocus,
  });

  final CurrentUser user;
  final String roleName;
  final String roleFocus;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.dashboard_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    roleName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${user.fullName} • $roleFocus',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
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

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.summary,
    required this.formatMoney,
  });

  final DashboardSummary summary;
  final String Function(num value) formatMoney;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: [
        _MetricTile(
          label: 'Savdo',
          value: formatMoney(summary.totalSales),
          icon: Icons.trending_up_rounded,
        ),
        _MetricTile(
          label: 'Qarz',
          value: formatMoney(summary.openDebt),
          icon: Icons.warning_amber_rounded,
          isDanger: summary.openDebt > 0,
        ),
        _MetricTile(
          label: 'Zakaz',
          value: summary.ordersCount.toString(),
          icon: Icons.receipt_long_rounded,
        ),
        _MetricTile(
          label: 'Mijoz',
          value: summary.customersCount.toString(),
          icon: Icons.groups_rounded,
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    this.isDanger = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? const Color(0xFFDC2626) : const Color(0xFF0F172A);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainActionCard extends StatelessWidget {
  const _MainActionCard({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                color: Color(0xFF2563EB),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Zakazlar',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _CustomersActionCard extends StatelessWidget {
  const _CustomersActionCard({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(
                Icons.groups_rounded,
                color: Color(0xFF2563EB),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Mijozlar',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _ProductsActionCard extends StatelessWidget {
  const _ProductsActionCard({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(
                Icons.inventory_2_rounded,
                color: Color(0xFF2563EB),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Mahsulotlar',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.summary,
  });

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final items = summary.statusBreakdown;

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            return Chip(
              label: Text(
                '${OrderStatusPolicy.label(item.status)} ${item.count}',
              ),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              backgroundColor: const Color(0xFFF8FAFC),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _RecentOrders extends StatelessWidget {
  const _RecentOrders({
    required this.summary,
    required this.formatMoney,
  });

  final DashboardSummary summary;
  final String Function(num value) formatMoney;

  @override
  Widget build(BuildContext context) {
    final orders = summary.recentOrders;

    if (orders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'So‘nggi',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            ...orders.map((order) {
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => context.go('/orders/${order.id}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.customer.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatMoney(order.totalAmount),
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w800,
                        ),
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
