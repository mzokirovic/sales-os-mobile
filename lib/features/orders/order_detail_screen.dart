import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/current_user.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_view.dart';
import '../auth/data/auth_repository.dart';
import 'order_models.dart';
import 'order_permission_policy.dart';
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

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) return 'Sana yo‘q';

    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;

    return '${parsed.day.toString().padLeft(2, '0')}.${parsed.month.toString().padLeft(2, '0')}.${parsed.year}';
  }

  Future<void> _openAddPaymentSheet(OrderModel order) async {
    if (order.debtAmount <= 0) {
      _showMessage('Bu zakaz qarzi yopilgan');
      return;
    }

    final input = await showModalBottomSheet<CreatePaymentInput>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return _AddPaymentSheet(
          debtAmount: order.debtAmount,
          formatMoney: _formatMoney,
        );
      },
    );

    if (input == null || !mounted) return;

    try {
      _showMessage('To‘lov qo‘shilmoqda...');

      await _ordersRepository.addPayment(
        orderId: order.id,
        input: input,
      );

      if (!mounted) return;

      _showMessage('To‘lov qo‘shildi');
      _reload();
    } catch (error) {
      if (!mounted) return;

      _showMessage(error.toString(), isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFDC2626) : null,
      ),
    );
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

      _showMessage('Status yangilandi');
      _reload();
    } catch (error) {
      if (!mounted) return;

      _showMessage(error.toString(), isError: true);
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
            : OrderStatusPolicy.nextStatusForRole(
                role: role,
                currentStatus: order.status,
              );

        final canAddPayment = order != null &&
            role != null && OrderPermissionPolicy.canAddPayment(role) &&
            order.debtAmount > 0;

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
                    nextStatus == null && !canAddPayment ? 16 : 110,
                  ),
                  children: [
                    _OrderHero(order: data.order),
                    const SizedBox(height: 12),
                    _MoneySummaryCard(
                      order: data.order,
                      formatMoney: _formatMoney,
                    ),
                    const SizedBox(height: 12),
                    _PaymentCard(
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
                      actionText: nextStatus == null
                          ? null
                          : OrderStatusPolicy.actionLabel(nextStatus),
                    ),
                    const SizedBox(height: 12),
                    _ProductsCard(
                      items: data.order.items,
                      formatMoney: _formatMoney,
                    ),
                    const SizedBox(height: 12),
                    _PaymentsHistoryCard(
                      payments: data.order.payments,
                      formatMoney: _formatMoney,
                      formatDate: _formatDate,
                    ),
                  ],
                ),
              );
            },
          ),
          bottomNavigationBar: order == null
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
                    child: Row(
                      children: [
                        if (canAddPayment) ...[
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: OutlinedButton.icon(
                                onPressed: () => _openAddPaymentSheet(order),
                                icon: const Icon(Icons.payments_rounded),
                                label: const Text('To‘lov'),
                              ),
                            ),
                          ),
                          if (nextStatus != null) const SizedBox(width: 10),
                        ],
                        if (nextStatus != null)
                          Expanded(
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
                                    : Text(OrderStatusPolicy.actionLabel(nextStatus)),
                              ),
                            ),
                          ),
                      ],
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
                _PaymentStatusPill(status: order.paymentStatus),
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
    return _Pill(
      text: OrderStatusPolicy.label(status),
      background: const Color(0xFFEFF6FF),
      foreground: const Color(0xFF2563EB),
    );
  }
}

class _PaymentStatusPill extends StatelessWidget {
  const _PaymentStatusPill({
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      'UNPAID' => 'To‘lanmagan',
      'PARTIAL' => 'Qisman',
      'PAID' => 'To‘liq to‘langan',
      _ => status,
    };

    final background = switch (status) {
      'UNPAID' => const Color(0xFFFEF2F2),
      'PARTIAL' => const Color(0xFFFFFBEB),
      'PAID' => const Color(0xFFF0FDF4),
      _ => const Color(0xFFF1F5F9),
    };

    final foreground = switch (status) {
      'UNPAID' => const Color(0xFFDC2626),
      'PARTIAL' => const Color(0xFFD97706),
      'PAID' => const Color(0xFF16A34A),
      _ => const Color(0xFF64748B),
    };

    return _Pill(
      text: label,
      background: background,
      foreground: foreground,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
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

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.order,
    required this.formatMoney,
  });

  final OrderModel order;
  final String Function(num value) formatMoney;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFFBEB),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(
              Icons.payments_rounded,
              color: Color(0xFFD97706),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                order.debtAmount > 0
                    ? 'Qarz ochiq: ${formatMoney(order.debtAmount)}'
                    : 'Qarz yopilgan',
                style: const TextStyle(
                  color: Color(0xFF92400E),
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

class _StatusFlowCard extends StatelessWidget {
  const _StatusFlowCard({
    required this.order,
  });

  final OrderModel order;

  int get _currentIndex {
    final index = OrderStatusPolicy.statusFlow.indexOf(order.status);
    return index < 0 ? OrderStatusPolicy.statusFlow.length - 1 : index;
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
            children: OrderStatusPolicy.statusFlow.asMap().entries.map((entry) {
              final index = entry.key;
              final status = entry.value;
              final done = index <= currentIndex;

              return Row(
                children: [
                  _StatusStep(
                    label: OrderStatusPolicy.label(status),
                    done: done,
                  ),
                  if (index != OrderStatusPolicy.statusFlow.length - 1)
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

  bool get _isDelivered => order.status == 'DELIVERED';

  String get _title {
    if (nextStatus != null && actionText != null) return 'Keyingi amal: $actionText';
    if (_isDelivered) return 'Mahsulot yetkazilgan';
    return 'Bu bosqich sizning rolingiz uchun emas';
  }

  String get _subtitle {
    if (_isDelivered) {
      return 'Pul holati alohida to‘lovlarda yuritiladi.';
    }

    if (nextStatus != null) {
      return 'Role: ${role ?? 'Noma’lum'} • Status: ${OrderStatusPolicy.label(order.status)}';
    }

    return 'Role: ${role ?? 'Noma’lum'} • Siz hozir bu statusni o‘zgartira olmaysiz.';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFEFF6FF),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF2563EB),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.inventory_2_rounded,
            color: Color(0xFF475569),
            size: 19,
          ),
        ),
        const SizedBox(width: 10),
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
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            formatMoney(item.total),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentsHistoryCard extends StatelessWidget {
  const _PaymentsHistoryCard({
    required this.payments,
    required this.formatMoney,
    required this.formatDate,
  });

  final List<OrderPayment> payments;
  final String Function(num value) formatMoney;
  final String Function(String? value) formatDate;

  String _methodLabel(String? method) {
    return switch (method) {
      'cash' => 'Naqd',
      'card' => 'Karta',
      'click' => 'Click',
      'transfer' => 'Bank',
      'other' => 'Boshqa',
      _ => 'Boshqa',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: payments.isEmpty
            ? const Text(
                'Hali to‘lov yo‘q',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w800,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'To‘lovlar tarixi',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...payments.map((payment) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_methodLabel(payment.paymentMethod)} • ${formatDate(payment.createdAt)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            formatMoney(payment.amount),
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

class _AddPaymentSheet extends StatefulWidget {
  const _AddPaymentSheet({
    required this.debtAmount,
    required this.formatMoney,
  });

  final num debtAmount;
  final String Function(num value) formatMoney;

  @override
  State<_AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends State<_AddPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  String _paymentMethod = 'cash';

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.debtAmount.toInt().toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    final valid = _formKey.currentState?.validate() ?? false;

    if (!valid) return;

    Navigator.of(context).pop(
      CreatePaymentInput(
        amount: num.parse(_amountController.text.trim()),
        paymentMethod: _paymentMethod,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'To‘lov qo‘shish',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Qarz: ${widget.formatMoney(widget.debtAmount)}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Summa',
                    prefixIcon: Icon(Icons.payments_rounded),
                  ),
                  validator: (value) {
                    final amount = num.tryParse(value?.trim() ?? '');

                    if (amount == null || amount <= 0) {
                      return 'To‘g‘ri summa kiriting';
                    }

                    if (amount > widget.debtAmount) {
                      return 'To‘lov qarzdan katta bo‘lmasin';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'To‘lov turi',
                    prefixIcon: Icon(Icons.account_balance_wallet_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Naqd')),
                    DropdownMenuItem(value: 'card', child: Text('Karta')),
                    DropdownMenuItem(value: 'click', child: Text('Click')),
                    DropdownMenuItem(value: 'transfer', child: Text('Bank')),
                    DropdownMenuItem(value: 'other', child: Text('Boshqa')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _paymentMethod = value ?? 'cash';
                    });
                  },
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Text('Qo‘shish'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
