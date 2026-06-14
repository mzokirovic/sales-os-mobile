import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/current_user.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_view.dart';
import 'order_models.dart';
import 'order_status_policy.dart';
import 'orders_repository.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({
    required this.orderId,
    super.key,
  });

  final String orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _ordersRepository = OrdersRepository();
  final _authRepository = AuthRepository();

  late Future<OrderModel> _orderFuture;
  late Future<CurrentUser?> _currentUserFuture;

  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _orderFuture = _ordersRepository.getOrder(widget.orderId);
    _currentUserFuture = _authRepository.readCurrentUser();
  }

  void _reload() {
    setState(() {
      _orderFuture = _ordersRepository.getOrder(widget.orderId);
      _currentUserFuture = _authRepository.readCurrentUser();
    });
  }

  Future<void> _moveNext({
    required OrderModel order,
    required String nextStatus,
  }) async {
    if (_isUpdatingStatus) return;

    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      await _ordersRepository.updateStatus(
        orderId: order.id,
        status: nextStatus,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status: ${OrderStatusPolicy.label(nextStatus)}'),
        ),
      );

      _reload();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  String _formatMoney(num value) {
    return '${value.toInt().toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ' ',
        )} so‘m';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zakaz'),
        leading: IconButton(
          onPressed: () => context.go('/orders'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<OrderModel>(
        future: _orderFuture,
        builder: (context, orderSnapshot) {
          if (orderSnapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }

          if (orderSnapshot.hasError) {
            return ErrorView(
              message: orderSnapshot.error.toString(),
              onRetry: _reload,
            );
          }

          final order = orderSnapshot.data;

          if (order == null) {
            return ErrorView(
              message: 'Zakaz topilmadi',
              onRetry: _reload,
            );
          }

          return FutureBuilder<CurrentUser?>(
            future: _currentUserFuture,
            builder: (context, userSnapshot) {
              final user = userSnapshot.data;
              final role = user?.role ?? 'UNKNOWN';

              final nextStatus = OrderStatusPolicy.nextStatusForRole(
                role: role,
                currentStatus: order.status,
              );

              return _OrderDetailContent(
                order: order,
                role: role,
                nextStatus: nextStatus,
                isUserLoading:
                    userSnapshot.connectionState == ConnectionState.waiting,
                isUpdatingStatus: _isUpdatingStatus,
                statusColor: _statusColor(order.status),
                formatMoney: _formatMoney,
                onMoveNext: nextStatus == null
                    ? null
                    : () => _moveNext(
                          order: order,
                          nextStatus: nextStatus,
                        ),
              );
            },
          );
        },
      ),
    );
  }
}

class _OrderDetailContent extends StatelessWidget {
  const _OrderDetailContent({
    required this.order,
    required this.role,
    required this.nextStatus,
    required this.isUserLoading,
    required this.isUpdatingStatus,
    required this.statusColor,
    required this.formatMoney,
    required this.onMoveNext,
  });

  final OrderModel order;
  final String role;
  final String? nextStatus;
  final bool isUserLoading;
  final bool isUpdatingStatus;
  final Color statusColor;
  final String Function(num value) formatMoney;
  final VoidCallback? onMoveNext;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        order.customer.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        OrderStatusPolicy.label(order.status),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  order.customer.phone ?? 'Telefon kiritilmagan',
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  order.customer.address ?? 'Manzil kiritilmagan',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: 'Jami',
                        value: formatMoney(order.totalAmount),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricCard(
                        label: 'To‘langan',
                        value: formatMoney(order.paidAmount),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _MetricCard(
                  label: 'Qarz',
                  value: formatMoney(order.debtAmount),
                  isDanger: order.debtAmount > 0,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mahsulotlar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                ...order.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.quantity} dona × ${formatMoney(item.price)}',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatMoney(item.total),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _RoleActionPanel(
          role: role,
          nextStatus: nextStatus,
          isUserLoading: isUserLoading,
          isUpdatingStatus: isUpdatingStatus,
          onMoveNext: onMoveNext,
        ),
        const SizedBox(height: 12),
        Text(
          'ID: ${order.id.substring(0, 8)}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RoleActionPanel extends StatelessWidget {
  const _RoleActionPanel({
    required this.role,
    required this.nextStatus,
    required this.isUserLoading,
    required this.isUpdatingStatus,
    required this.onMoveNext,
  });

  final String role;
  final String? nextStatus;
  final bool isUserLoading;
  final bool isUpdatingStatus;
  final VoidCallback? onMoveNext;

  @override
  Widget build(BuildContext context) {
    if (isUserLoading) {
      return const SizedBox(
        height: 54,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (nextStatus == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFF64748B),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                role == 'SALES'
                    ? 'Sotuvchi statusni o‘zgartirmaydi'
                    : 'Bu bosqichda siz uchun action yo‘q',
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 54,
      child: FilledButton(
        onPressed: isUpdatingStatus ? null : onMoveNext,
        child: isUpdatingStatus
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : Text(OrderStatusPolicy.actionLabel(nextStatus!)),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    this.isDanger = false,
  });

  final String label;
  final String value;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: isDanger ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
