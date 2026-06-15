import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/current_user.dart';
import '../../../features/auth/data/auth_repository.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../orders/order_models.dart';
import '../../orders/order_permission_policy.dart';
import '../../orders/order_status_policy.dart';
import '../../orders/orders_repository.dart';
import '../customer_model.dart';
import '../customers_repository.dart';

class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({
    required this.customerId,
    super.key,
  });

  final String customerId;

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final _customersRepository = CustomersRepository();
  final _ordersRepository = OrdersRepository();
  final _authRepository = AuthRepository();

  late Future<_CustomerDetailData> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadDetail();
  }

  Future<_CustomerDetailData> _loadDetail() async {
    final user = await _authRepository.readCurrentUser();
    final customer = await _customersRepository.getCustomer(widget.customerId);
    final orders = await _ordersRepository.listOrdersByCustomer(widget.customerId);

    return _CustomerDetailData(
      user: user,
      customer: customer,
      orders: orders,
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

  num _totalDebt(List<OrderModel> orders) {
    return orders.fold<num>(0, (sum, order) => sum + order.debtAmount);
  }

  void _createOrderForCustomer(CustomerModel customer) {
    context.go('/orders/create?customerId=${customer.id}');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_CustomerDetailData>(
      future: _detailFuture,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final role = data?.user?.role;
        final canCreateOrder =
            role != null && OrderPermissionPolicy.canCreateOrder(role);

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text('Mijoz'),
            leading: IconButton(
              onPressed: () => context.go('/customers'),
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
                  message: 'Mijoz topilmadi',
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
                    canCreateOrder ? 110 : 16,
                  ),
                  children: [
                    _CustomerHero(customer: data.customer),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniMetric(
                            label: 'Zakaz',
                            value: data.orders.length.toString(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniMetric(
                            label: 'Qarz',
                            value: _formatMoney(_totalDebt(data.orders)),
                            isDanger: _totalDebt(data.orders) > 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _CustomerOrdersCard(
                      orders: data.orders,
                      formatMoney: _formatMoney,
                    ),
                  ],
                ),
              );
            },
          ),
          bottomNavigationBar: data == null || !canCreateOrder
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
                      child: FilledButton.icon(
                        onPressed: () => _createOrderForCustomer(data.customer),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Zakaz yaratish'),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _CustomerDetailData {
  const _CustomerDetailData({
    required this.user,
    required this.customer,
    required this.orders,
  });

  final CurrentUser? user;
  final CustomerModel customer;
  final List<OrderModel> orders;
}

class _CustomerHero extends StatelessWidget {
  const _CustomerHero({
    required this.customer,
  });

  final CustomerModel customer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              customer.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            _InfoLine(
              icon: Icons.phone_outlined,
              text: customer.phone ?? 'Telefon yo‘q',
            ),
            const SizedBox(height: 8),
            _InfoLine(
              icon: Icons.location_on_outlined,
              text: customer.address ?? 'Manzil yo‘q',
            ),
          ],
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

class _CustomerOrdersCard extends StatelessWidget {
  const _CustomerOrdersCard({
    required this.orders,
    required this.formatMoney,
  });

  final List<OrderModel> orders;
  final String Function(num value) formatMoney;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: orders.isEmpty
            ? const Text(
                'Bu mijozda zakaz yo‘q',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w800,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Zakazlar',
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
                                OrderStatusPolicy.label(order.status),
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Text(
                              formatMoney(order.totalAmount),
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
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
