import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_view.dart';
import 'order_models.dart';
import 'order_status_policy.dart';
import 'orders_repository.dart';

enum OrdersFilter {
  active,
  closed,
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _ordersRepository = OrdersRepository();
  final _authRepository = AuthRepository();

  late Future<List<OrderModel>> _ordersFuture;
  OrdersFilter _filter = OrdersFilter.active;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _ordersRepository.listOrders();
  }

  void _reload() {
    setState(() {
      _ordersFuture = _ordersRepository.listOrders();
    });
  }

  Future<void> _logout() async {
    await _authRepository.logout();

    if (!mounted) return;

    context.go('/login');
  }

  List<OrderModel> _applyFilter(List<OrderModel> orders) {
    return switch (_filter) {
      OrdersFilter.active => orders.where((order) => order.status != 'PAID').toList(),
      OrdersFilter.closed => orders.where((order) => order.status == 'PAID').toList(),
    };
  }

  String _emptyMessage() {
    return switch (_filter) {
      OrdersFilter.active => 'Aktiv zakaz yo‘q',
      OrdersFilter.closed => 'Yopilgan zakaz yo‘q',
    };
  }

  String _formatMoney(num value) {
    return value.toInt().toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ' ',
        );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'NEW' => const Color(0xFF2563EB),
      'CHECKED' => const Color(0xFF4F46E5),
      'CONFIRMED' => const Color(0xFF7C3AED),
      'PREPARING' => const Color(0xFFD97706),
      'SHIPPED' => const Color(0xFFEA580C),
      'DELIVERED' => const Color(0xFF059669),
      'PAID' => const Color(0xFF0F172A),
      _ => const Color(0xFF64748B),
    };
  }

  String _shortId(String value) {
    if (value.length <= 8) return value;
    return value.substring(0, 8);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Zakazlar'),
        leading: IconButton(
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
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
      body: FutureBuilder<List<OrderModel>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }

          if (snapshot.hasError) {
            return ErrorView(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }

          final allOrders = snapshot.data ?? [];
          final activeCount = allOrders.where((order) => order.status != 'PAID').length;
          final closedCount = allOrders.where((order) => order.status == 'PAID').length;
          final visibleOrders = _applyFilter(allOrders);

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _ModernFilterTabs(
                  selected: _filter,
                  activeCount: activeCount,
                  closedCount: closedCount,
                  onChanged: (filter) {
                    setState(() {
                      _filter = filter;
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (visibleOrders.isEmpty)
                  _EmptyOrdersCard(message: _emptyMessage())
                else
                  ...visibleOrders.map((order) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _OrderCard(
                        order: order,
                        statusColor: _statusColor(order.status),
                        formatMoney: _formatMoney,
                        shortId: _shortId,
                        onTap: () => context.go('/orders/${order.id}'),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ModernFilterTabs extends StatelessWidget {
  const _ModernFilterTabs({
    required this.selected,
    required this.activeCount,
    required this.closedCount,
    required this.onChanged,
  });

  final OrdersFilter selected;
  final int activeCount;
  final int closedCount;
  final ValueChanged<OrdersFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            Expanded(
              child: _FilterTab(
                label: 'Aktiv',
                count: activeCount,
                isSelected: selected == OrdersFilter.active,
                onTap: () => onChanged(OrdersFilter.active),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _FilterTab(
                label: 'Yopilgan',
                count: closedCount,
                isSelected: selected == OrdersFilter.closed,
                onTap: () => onChanged(OrdersFilter.closed),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textColor = isSelected ? Colors.white : const Color(0xFF475569);
    final badgeColor = isSelected ? Colors.white.withValues(alpha: 0.16) : Colors.white;
    final badgeTextColor = isSelected ? Colors.white : const Color(0xFF0F172A);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: badgeTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyOrdersCard extends StatelessWidget {
  const _EmptyOrdersCard({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(
              Icons.inbox_outlined,
              color: Color(0xFF64748B),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.statusColor,
    required this.formatMoney,
    required this.shortId,
    required this.onTap,
  });

  final OrderModel order;
  final Color statusColor;
  final String Function(num value) formatMoney;
  final String Function(String value) shortId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.customer.address ?? 'Manzil yo‘q',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusPill(
                    label: OrderStatusPolicy.label(order.status),
                    color: statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MiniMetric(
                      label: 'Jami',
                      value: '${formatMoney(order.totalAmount)} so‘m',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniMetric(
                      label: 'Qarz',
                      value: '${formatMoney(order.debtAmount)} so‘m',
                      isDanger: order.debtAmount > 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    '#${shortId(order.id)}',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${order.items.length} mahsulot',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 112),
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    this.isDanger = false,
  });

  final String label;
  final String value;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? const Color(0xFFDC2626) : const Color(0xFF0F172A);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
    );
  }
}
