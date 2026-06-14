import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_view.dart';
import 'order_models.dart';
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

  late Future<OrderModel> _orderFuture;
  bool _isUpdatingStatus = false;

  static const _nextStatusMap = <String, String?>{
    'NEW': 'CHECKED',
    'CHECKED': 'CONFIRMED',
    'CONFIRMED': 'PREPARING',
    'PREPARING': 'SHIPPED',
    'SHIPPED': 'DELIVERED',
    'DELIVERED': 'PAID',
    'PAID': null,
  };

  static const _statusLabels = <String, String>{
    'NEW': 'Yangi',
    'CHECKED': 'Tekshirildi',
    'CONFIRMED': 'Tasdiqlandi',
    'PREPARING': 'Tayyorlanmoqda',
    'SHIPPED': 'Yo‘lda',
    'DELIVERED': 'Yetkazildi',
    'PAID': 'Yopildi',
  };

  static const _actionLabels = <String, String>{
    'NEW': 'Tekshirishga yuborish',
    'CHECKED': 'Tasdiqlash',
    'CONFIRMED': 'Skladga berish',
    'PREPARING': 'Yo‘lga chiqarish',
    'SHIPPED': 'Yetkazildi',
    'DELIVERED': 'To‘liq yopish',
    'PAID': 'Yopilgan',
  };

  @override
  void initState() {
    super.initState();
    _orderFuture = _ordersRepository.getOrder(widget.orderId);
  }

  void _reload() {
    setState(() {
      _orderFuture = _ordersRepository.getOrder(widget.orderId);
    });
  }

  Future<void> _moveNext(OrderModel order) async {
    final nextStatus = _nextStatusMap[order.status];

    if (nextStatus == null || _isUpdatingStatus) return;

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
          content: Text('Status: ${_statusLabel(nextStatus)}'),
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

  String _statusLabel(String status) {
    return _statusLabels[status] ?? status;
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

          final order = snapshot.data;

          if (order == null) {
            return ErrorView(
              message: 'Zakaz topilmadi',
              onRetry: _reload,
            );
          }

          final statusColor = _statusColor(order.status);
          final nextStatus = _nextStatusMap[order.status];
          final actionLabel = _actionLabels[order.status] ?? 'Status';

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
                              _statusLabel(order.status),
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
                              value: _formatMoney(order.totalAmount),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MetricCard(
                              label: 'To‘langan',
                              value: _formatMoney(order.paidAmount),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _MetricCard(
                        label: 'Qarz',
                        value: _formatMoney(order.debtAmount),
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
                                      '${item.quantity} dona × ${_formatMoney(item.price)}',
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _formatMoney(item.total),
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
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: nextStatus == null || _isUpdatingStatus
                      ? null
                      : () => _moveNext(order),
                  child: _isUpdatingStatus
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : Text(actionLabel),
                ),
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
        },
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
