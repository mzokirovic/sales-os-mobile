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

    return _OrderDetailData(order: order, user: user);
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

          return _CompactOrderDetail(
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

          return _BottomActionBar(
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

class _CompactOrderDetail extends StatelessWidget {
  const _CompactOrderDetail({
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        _CustomerCard(
          order: order,
          role: role,
          statusColor: statusColor,
          shortId: shortId,
        ),
        const SizedBox(height: 12),
        _MoneySummary(
          order: order,
          formatMoney: formatMoney,
        ),
        const SizedBox(height: 12),
        _MiniStatusFlow(
          currentStatus: order.status,
        ),
        const SizedBox(height: 12),
        _ProductsCard(
          order: order,
          formatMoney: formatMoney,
        ),
      ],
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.order,
    required this.role,
    required this.statusColor,
    required this.shortId,
  });

  final OrderModel order;
  final String role;
  final Color statusColor;
  final String Function(String value) shortId;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.customer.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _StatusChip(
                  label: OrderStatusPolicy.label(order.status),
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _TinyInfo(
              icon: Icons.location_on_outlined,
              text: order.customer.address ?? 'Manzil yo‘q',
            ),
            const SizedBox(height: 6),
            _TinyInfo(
              icon: Icons.phone_outlined,
              text: order.customer.phone ?? 'Telefon yo‘q',
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _SmallPill(text: role),
                const SizedBox(width: 8),
                _SmallPill(text: '#${shortId(order.id)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MoneySummary extends StatelessWidget {
  const _MoneySummary({
    required this.order,
    required this.formatMoney,
  });

  final OrderModel order;
  final String Function(num value) formatMoney;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _WideMetric(
          label: 'Jami',
          value: formatMoney(order.totalAmount),
          icon: Icons.payments_outlined,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SmallMetric(
                label: 'To‘langan',
                value: formatMoney(order.paidAmount),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SmallMetric(
                label: 'Qarz',
                value: formatMoney(order.debtAmount),
                isDanger: order.debtAmount > 0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniStatusFlow extends StatelessWidget {
  const _MiniStatusFlow({
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
        padding: const EdgeInsets.all(14),
        child: Row(
          children: _steps.asMap().entries.map((entry) {
            final index = entry.key;
            final status = entry.value;
            final isDone = currentIndex >= index;
            final isCurrent = currentIndex == index;

            return Expanded(
              child: _StatusDot(
                label: OrderStatusPolicy.label(status),
                isDone: isDone,
                isCurrent: isCurrent,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({
    required this.label,
    required this.isDone,
    required this.isCurrent,
  });

  final String label;
  final bool isDone;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final color = isDone ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isCurrent ? 18 : 12,
          height: isCurrent ? 18 : 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: isCurrent
                ? Border.all(
                    color: const Color(0xFF2563EB),
                    width: 3,
                  )
                : null,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label.split(' ').first,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isCurrent ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w700,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Mahsulotlar',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  order.items.length.toString(),
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...order.items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.productName,
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
                      '${item.quantity} × ${formatMoney(item.price)}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
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

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
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
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        child: nextStatus == null
            ? _LockedAction(role: role)
            : SizedBox(
                height: 52,
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
      height: 52,
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
              role == 'SALES' ? 'Status action yo‘q' : 'Bu bosqichda action yo‘q',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 118),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

class _TinyInfo extends StatelessWidget {
  const _TinyInfo({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: const Color(0xFF64748B)),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SmallPill extends StatelessWidget {
  const _SmallPill({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF475569),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _WideMetric extends StatelessWidget {
  const _WideMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF0F172A)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
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

class _SmallMetric extends StatelessWidget {
  const _SmallMetric({
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
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
            const SizedBox(height: 4),
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
