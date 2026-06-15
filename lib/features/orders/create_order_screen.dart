import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/current_user.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/customers/customer_model.dart';
import '../../features/customers/customers_repository.dart';
import '../../features/products/product_model.dart';
import '../../features/products/products_repository.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_view.dart';
import 'order_permission_policy.dart';
import 'orders_repository.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authRepository = AuthRepository();
  final _customersRepository = CustomersRepository();
  final _productsRepository = ProductsRepository();
  final _ordersRepository = OrdersRepository();

  final _quantityController = TextEditingController(text: '1');
  final _paidAmountController = TextEditingController(text: '0');

  late Future<_CreateOrderData> _dataFuture;

  String? _selectedCustomerId;
  String? _selectedProductId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  Future<_CreateOrderData> _loadData() async {
    final user = await _authRepository.readCurrentUser();

    if (user == null) {
      throw const CreateOrderException('Session topilmadi');
    }

    if (!OrderPermissionPolicy.canCreateOrder(user.role)) {
      throw const CreateOrderException('Siz zakaz yarata olmaysiz');
    }

    final customers = await _customersRepository.listCustomers();
    final products = await _productsRepository.listActiveProducts();

    return _CreateOrderData(
      user: user,
      customers: customers,
      products: products,
    );
  }

  void _reload() {
    setState(() {
      _dataFuture = _loadData();
    });
  }

  CustomerModel? _selectedCustomer(List<CustomerModel> customers) {
    final id = _selectedCustomerId;
    if (id == null) return null;

    for (final customer in customers) {
      if (customer.id == id) return customer;
    }

    return null;
  }

  ProductModel? _selectedProduct(List<ProductModel> products) {
    final id = _selectedProductId;
    if (id == null) return null;

    for (final product in products) {
      if (product.id == id) return product;
    }

    return null;
  }

  int _quantity() {
    return int.tryParse(_quantityController.text.trim()) ?? 0;
  }

  num _paidAmount() {
    return num.tryParse(_paidAmountController.text.trim()) ?? 0;
  }

  String _formatMoney(num value) {
    return '${value.toInt().toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ' ',
        )} so‘m';
  }

  Future<void> _submit(List<ProductModel> products) async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _isSubmitting) return;

    final customerId = _selectedCustomerId;
    final productId = _selectedProductId;

    if (customerId == null || productId == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final order = await _ordersRepository.createOrder(
        customerId: customerId,
        productId: productId,
        quantity: _quantity(),
        paidAmount: _paidAmount(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zakaz yaratildi')),
      );

      context.go('/orders/${order.id}');
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
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Yangi zakaz'),
        leading: IconButton(
          onPressed: () => context.go('/orders'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: FutureBuilder<_CreateOrderData>(
        future: _dataFuture,
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
              message: 'Ma’lumot topilmadi',
              onRetry: _reload,
            );
          }

          final customer = _selectedCustomer(data.customers);
          final product = _selectedProduct(data.products);
          final quantity = _quantity();
          final total = product == null ? 0 : product.price * quantity;
          final paid = _paidAmount();
          final debt = total - paid;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              children: [
                _CompactSelectCard(
                  title: 'Mijoz',
                  value: customer?.name ?? 'Tanlanmagan',
                  subtitle: customer?.address ?? 'Yangi mijoz qo‘shish mumkin',
                  icon: Icons.storefront_rounded,
                  actionLabel: 'Yangi',
                  onAction: () => context.go('/customers/create'),
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _selectedCustomerId,
                    decoration: const InputDecoration(
                      labelText: 'Mijoz tanlang',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                    items: data.customers.map((item) {
                      return DropdownMenuItem(
                        value: item.id,
                        child: Text(
                          item.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Mijoz tanlang';
                      }

                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _selectedCustomerId = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _CompactSelectCard(
                  title: 'Mahsulot',
                  value: product?.name ?? 'Tanlanmagan',
                  subtitle: product == null ? 'Aktiv mahsulotlardan tanlang' : _formatMoney(product.price),
                  icon: Icons.inventory_2_rounded,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _selectedProductId,
                    decoration: const InputDecoration(
                      labelText: 'Mahsulot tanlang',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                    items: data.products.map((item) {
                      return DropdownMenuItem(
                        value: item.id,
                        child: Text(
                          item.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Mahsulot tanlang';
                      }

                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _selectedProductId = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Miqdor',
                              prefixIcon: Icon(Icons.numbers_rounded),
                            ),
                            validator: (value) {
                              final number = int.tryParse(value?.trim() ?? '');

                              if (number == null || number <= 0) {
                                return 'Noto‘g‘ri';
                              }

                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _paidAmountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'To‘langan',
                              prefixIcon: Icon(Icons.payments_rounded),
                            ),
                            validator: (value) {
                              final number = num.tryParse(value?.trim() ?? '');

                              if (number == null || number < 0) {
                                return 'Noto‘g‘ri';
                              }

                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _CompactSummaryCard(
                  total: total,
                  paid: paid,
                  debt: debt < 0 ? 0 : debt,
                  formatMoney: _formatMoney,
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: FutureBuilder<_CreateOrderData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          final data = snapshot.data;

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
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: data == null || _isSubmitting
                      ? null
                      : () => _submit(data.products),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : const Text('Yaratish'),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CreateOrderData {
  const _CreateOrderData({
    required this.user,
    required this.customers,
    required this.products,
  });

  final CurrentUser user;
  final List<CustomerModel> customers;
  final List<ProductModel> products;
}

class CreateOrderException implements Exception {
  const CreateOrderException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _CompactSelectCard extends StatelessWidget {
  const _CompactSelectCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (actionLabel != null && onAction != null)
                  TextButton(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _CompactSummaryCard extends StatelessWidget {
  const _CompactSummaryCard({
    required this.total,
    required this.paid,
    required this.debt,
    required this.formatMoney,
  });

  final num total;
  final num paid;
  final num debt;
  final String Function(num value) formatMoney;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: _SummaryTile(
                label: 'Jami',
                value: formatMoney(total),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryTile(
                label: 'Qarz',
                value: formatMoney(debt),
                isDanger: debt > 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
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
            fontSize: 12,
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
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
