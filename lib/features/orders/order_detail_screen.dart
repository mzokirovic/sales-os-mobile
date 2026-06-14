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

  late Future<_OrderDetailData> _detailFuture;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadDetail();
  }

  Future<_OrderDetailData> _loadDetail() async {
    final order = await _ordersRepository.getOrder(widget.orderId);
    final user = await _authRepository.readCurrentUser();

    return _OrderDetailData(
      order: order,
      user: user,
    );
  }

  void _reload() {
    setState(() {
      _detailFuture = _loadDetail();
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

  String _shortId(String value) {
    if (value.length <= 8) return value;
    return value.substring(0, 8);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
      body: FutureBuilder<_OrderDetailData>(
        future: _detailFuture,
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

          final data = snapshot.data;

          if (data == null) {
            return ErrorView(
              message: 'Zakaz topilmadi',
              onRetry: _reload,
            );
          }

          return _OrderDetailContent(
            order: data.order,
            role: data.user?.role ?? 'UNKNOWN',
            statusColor: _statusColor(data.order.status),
            formatMoney: _formatMoney,
            shortId: _shortId,
          );
        },
      ),
      bottomNavigationBar: FutureBuilder<_OrderDetailData>(
        future: _detailFuture,
        builder: (context, snapshot) {
          final data = snapshot.data;

          if (data == null) {
            return const SizedBox.shrink();
          }

          final role = data.user?.role ?? 'UNKNOWN';
          final nextStatus = OrderStatusPolicy.nextStatusForRole(
            role: role,
            currentStatus: data.order.status,
          );

          return _BottomStatusAction(
            role: role,
            nextStatus: nextStatus,
            isUpdatingStatus: _isUpdatingStatus,
            onMoveNext: nextStatus == null
                ? null
                : () => _moveNext(
                      order: data.order,
                      nextStatus: nextStatus,
                    ),
          );
        },
      ),
    );
  }
}

class _OrderDetailData {
  const _OrderDetailData({
    required this.order,
    required this.user,
  });

  final OrderModel order;
  final CurrentUser? user;
}

class _OrderDetailContent extends StatelessWidget {
  const _OrderDetailContent({
    required this.order,
    required this.role,
    required this.statusColor,
    required this.formatMoney,
    required this.shortId,
  });

  final OrderModel order;
  final String role;
  final Color statusColor;
  final String Function(num value) formatMoney;
  final String Function(String value) shortId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
      children: [
        _HeroOrderCard(
          order: order,
          role: role,
          statusColor: statusColor,
          formatMoney: formatMoney,
        ),
        const SizedBox(height: 14),
        _StatusTimeline(
          currentStatus: order.status,
        ),
        const SizedBox(height: 14),
        _ProductsCard(
          order: order,
          formatMoney: formatMoney,
        ),
        const SizedBox(height: 14),
        Text(
          'ID: ${shortId(order.id)}',
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

class _HeroOrderCard extends StatelessWidget {
  const _HeroOrderCard({
    required this.order,
    required this.role,
    required this.statusColor,
    required this.formatMoney,
  });

  final OrderModel order;
  final String role;
  final Color statusColor;
  final String Function(num value) formatMoney;

  @override
  Widget build(BuildContext context) {
    return Card(
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
            Row(
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Text(
                  role,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({
    required this.currentStatus,
  });

  final String currentStatus;

  static const _steps = <String>[
    'NEW',
    'CHECKED',
    'CONFIRMED',
    'PREPARING',
    'SHIPPED',
    'DELIVERED',
    'PAID',
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = _steps.indexOf(currentStatus);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status yo‘li',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 14),
            ..._steps.asMap().entries.map((entry) {
              final index = entry.key;
              final status = entry.value;
              final isDone = currentIndex >= index;
              final isCurrent = currentIndex == index;
              final isLast = index == _steps.length - 1;

              return _TimelineStep(
                label: OrderStatusPolicy.label(status),
                isDone: isDone,
                isCurrent: isCurrent,
                isLast: isLast,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.label,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
  });

  final String label;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final circleColor = isDone ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0);
    final textColor = isDone ? const Color(0xFF0F172A) : const Color(0xFF94A3B8);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: circleColor,
                borderRadius: BorderRadius.circular(999),
                border: isCurrent
                    ? Border.all(
                        color: const Color(0xFF2563EB),
                        width: 3,
                      )
                    : null,
              ),
              child: Icon(
                isDone ? Icons.check_rounded : Icons.circle,
                size: isDone ? 18 : 8,
                color: isDone ? Colors.white : const Color(0xFFCBD5E1),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 24,
                color: isDone ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductsCard extends StatelessWidget {
  const _ProductsCard({
    required this.order,
    required this.formatMoney,
  });

  final OrderModel order;
  final String Function(num value) formatMoney;

  @override
  Widget build(BuildContext context) {
    return Card(
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
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            ...order.items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.quantity} dona × ${formatMoney(item.price)}',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatMoney(item.total),
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
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
    );
  }
}

class _BottomStatusAction extends StatelessWidget {
  const _BottomStatusAction({
    required this.role,
    required this.nextStatus,
    required this.isUpdatingStatus,
    required this.onMoveNext,
  });

  final String role;
  final String? nextStatus;
  final bool isUpdatingStatus;
  final VoidCallback? onMoveNext;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        child: nextStatus == null
            ? _LockedAction(role: role)
            : SizedBox(
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
              ),
      ),
    );
  }
}

class _LockedAction extends StatelessWidget {
  const _LockedAction({
    required this.role,
  });

  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
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
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
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
