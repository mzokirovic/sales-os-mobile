import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/current_user.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_view.dart';
import '../auth/data/auth_repository.dart';
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
    final user = await _authRepository.readCurrentUser();
    final order = await _ordersRepository.getOrder(widget.orderId);

    return _OrderDetailData(
      user: user,
      order: order,
    );
  }

  void _reload() {
    setState(() {
      _detailFuture = _loadDetail();
    });
  }

  String _formatMoney(num value) {
    return '${value.toInt().toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ' ',
        )} so‘m';
  }

  String _actionText(String nextStatus) {
    return switch (nextStatus) {
      'CHECKED' => 'Tekshirish',
      'CONFIRMED' => 'Tasdiqlash',
      'PREPARING' => 'Tayyorlash',
      'SHIPPED' => 'Yo‘lga chiqarish',
      'DELIVERED' => 'Yetkazildi',
      'PAID' => 'To‘landi',
      _ => 'Statusni yangilash',
    };
  }

  Future<void> _updateStatus(String nextStatus) async {
    if (_isUpdatingStatus) return;

    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      await _ordersRepository.updateStatus(
        orderId: widget.orderId,
        status: nextStatus,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status yangilandi')),
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_OrderDetailData>(
      future: _detailFuture,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final order = data?.order;
        final role = data?.user?.role;

        final nextStatus = role == null || order == null
            ? null
            : OrderStatusPolicy.nextStatusForRole(role: role, currentStatus: order.status);

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text('Zakaz detail'),
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
          body: Builder(
            builder: (context) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingView();
              }

              if (snapshot.hasError) {
                return ErrorView(
                  message: snapshot.error.toString(),
                  onRetry: _reload,
                );
              }

              if (data == null) {
                return ErrorView(
                  message: 'Zakaz topilmadi',
                  onRetry: _reload,
                );
              }

              return RefreshIndicator(
                onRefresh: () async => _reload(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    nextStatus == null ? 16 : 110,
                  ),
                  children: [
                    _OrderHero(order: data.order),
                    const SizedBox(height: 12),
                    _MoneySummaryCard(
                      order: data.order,
                      formatMoney: _formatMoney,
                    ),
                    const SizedBox(height: 12),
                    _StatusFlowCard(order: data.order),
                    const SizedBox(height: 12),
                    _RoleHintCard(
                      role: data.user?.role,
                      order: data.order,
                      nextStatus: nextStatus,
                      actionText: nextStatus == null ? null : _actionText(nextStatus),
                    ),
                    const SizedBox(height: 12),
                    _ProductsCard(
                      items: data.order.items,
                      formatMoney: _formatMoney,
                    ),
                  ],
                ),
              );
            },
          ),
          bottomNavigationBar: nextStatus == null
              ? null
              : SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _isUpdatingStatus
                            ? null
                            : () => _updateStatus(nextStatus),
                        child: _isUpdatingStatus
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.4),
                              )
                            : Text(_actionText(nextStatus)),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _OrderDetailData {
  const _OrderDetailData({
    required this.user,
    required this.order,
  });

  final CurrentUser? user;
  final OrderModel order;
}

class _OrderHero extends StatelessWidget {
  const _OrderHero({
    required this.order,
  });

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              order.customer.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _StatusPill(status: order.status),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ID: ${order.id.substring(0, 8)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoLine(
              icon: Icons.phone_outlined,
              text: order.customer.phone ?? 'Telefon yo‘q',
            ),
            const SizedBox(height: 8),
            _InfoLine(
              icon: Icons.location_on_outlined,
              text: order.customer.address ?? 'Manzil yo‘q',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        OrderStatusPolicy.label(status),
        style: const TextStyle(
          color: Color(0xFF2563EB),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
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

class _MoneySummaryCard extends StatelessWidget {
  const _MoneySummaryCard({
    required this.order,
    required this.formatMoney,
  });

  final OrderModel order;
  final String Function(num value) formatMoney;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: _MoneyTile(
                label: 'Jami',
                value: formatMoney(order.totalAmount),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MoneyTile(
                label: 'To‘langan',
                value: formatMoney(order.paidAmount),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MoneyTile(
                label: 'Qarz',
                value: formatMoney(order.debtAmount),
                isDanger: order.debtAmount > 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoneyTile extends StatelessWidget {
  const _MoneyTile({
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _StatusFlowCard extends StatelessWidget {
  const _StatusFlowCard({
    required this.order,
  });

  final OrderModel order;

  static const _statuses = [
    'NEW',
    'CHECKED',
    'CONFIRMED',
    'PREPARING',
    'SHIPPED',
    'DELIVERED',
    'PAID',
  ];

  int get _currentIndex {
    final index = _statuses.indexOf(order.status);
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _statuses.asMap().entries.map((entry) {
              final index = entry.key;
              final status = entry.value;
              final done = index <= currentIndex;

              return Row(
                children: [
                  _StatusStep(
                    label: OrderStatusPolicy.label(status),
                    done: done,
                  ),
                  if (index != _statuses.length - 1)
                    Container(
                      width: 26,
                      height: 2,
                      color: done ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _StatusStep extends StatelessWidget {
  const _StatusStep({
    required this.label,
    required this.done,
  });

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final color = done ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: done ? color : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: done
              ? const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 15,
                )
              : null,
        ),
        const SizedBox(height: 5),
        SizedBox(
          width: 74,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: done ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}


class _RoleHintCard extends StatelessWidget {
  const _RoleHintCard({
    required this.role,
    required this.order,
    required this.nextStatus,
    required this.actionText,
  });

  final String? role;
  final OrderModel order;
  final String? nextStatus;
  final String? actionText;

  bool get _isDone => order.status == 'PAID';

  String get _title {
    if (_isDone) return 'Zakaz yakunlangan';
    if (nextStatus != null && actionText != null) return 'Keyingi amal: $actionText';
    return 'Bu bosqich sizning rolingiz uchun emas';
  }

  String get _subtitle {
    if (_isDone) {
      return 'Bu zakaz bo‘yicha status flow tugagan.';
    }

    if (nextStatus != null) {
      return 'Role: ${role ?? 'Noma’lum'} • Hozirgi status: ${OrderStatusPolicy.label(order.status)}';
    }

    return 'Role: ${role ?? 'Noma’lum'} • Siz hozir bu statusni o‘zgartira olmaysiz.';
  }

  IconData get _icon {
    if (_isDone) return Icons.verified_rounded;
    if (nextStatus != null) return Icons.play_circle_rounded;
    return Icons.info_outline_rounded;
  }

  Color get _color {
    if (_isDone) return const Color(0xFF16A34A);
    if (nextStatus != null) return const Color(0xFF2563EB);
    return const Color(0xFFF59E0B);
  }

  Color get _background {
    if (_isDone) return const Color(0xFFF0FDF4);
    if (nextStatus != null) return const Color(0xFFEFF6FF);
    return const Color(0xFFFFFBEB);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _background,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _icon,
                color: _color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: TextStyle(
                      color: _color,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
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

class _ProductsCard extends StatelessWidget {
  const _ProductsCard({
    required this.items,
    required this.formatMoney,
  });

  final List<OrderItem> items;
  final String Function(num value) formatMoney;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: items.isEmpty
            ? const Text(
                'Mahsulotlar yo‘q',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w800,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mahsulotlar',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;

                    return Column(
                      children: [
                        if (index != 0)
                          const Divider(height: 18, color: Color(0xFFE2E8F0)),
                        _ProductItemRow(
                          item: item,
                          formatMoney: formatMoney,
                        ),
                      ],
                    );
                  }),
                ],
              ),
      ),
    );
  }
}

class _ProductItemRow extends StatelessWidget {
  const _ProductItemRow({
    required this.item,
    required this.formatMoney,
  });

  final OrderItem item;
  final String Function(num value) formatMoney;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.inventory_2_rounded,
            color: Color(0xFF475569),
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.quantity} × ${formatMoney(item.price)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          formatMoney(item.total),
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
