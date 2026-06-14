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
        const SnackBar(
          content: Text('Zakaz yaratildi'),
        ),
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

          final selectedProduct = _selectedProduct(data.products);
          final quantity = _quantity();
          final total = selectedProduct == null ? 0 : selectedProduct.price * quantity;
          final debt = total - _paidAmount();

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              children: [
                _FormCard(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCustomerId,
                      decoration: const InputDecoration(
                        labelText: 'Mijoz',
                        prefixIcon: Icon(Icons.storefront_rounded),
                      ),
                      items: data.customers.map((customer) {
                        return DropdownMenuItem(
                          value: customer.id,
                          child: Text(
                            customer.name,
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
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedProductId,
                      decoration: const InputDecoration(
                        labelText: 'Mahsulot',
                        prefixIcon: Icon(Icons.inventory_2_rounded),
                      ),
                      items: data.products.map((product) {
                        return DropdownMenuItem(
                          value: product.id,
                          child: Text(
                            product.name,
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
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Miqdor',
                        prefixIcon: Icon(Icons.numbers_rounded),
                      ),
                      validator: (value) {
                        final number = int.tryParse(value?.trim() ?? '');

                        if (number == null || number <= 0) {
                          return 'Miqdor 1 dan katta bo‘lsin';
                        }

                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _paidAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'To‘langan',
                        prefixIcon: Icon(Icons.payments_rounded),
                      ),
                      validator: (value) {
                        final number = num.tryParse(value?.trim() ?? '');

                        if (number == null || number < 0) {
                          return 'To‘g‘ri summa kiriting';
                        }

                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SummaryCard(
                  product: selectedProduct,
                  quantity: quantity,
                  total: total,
                  paid: _paidAmount(),
                  debt: debt,
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

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.product,
    required this.quantity,
    required this.total,
    required this.paid,
    required this.debt,
    required this.formatMoney,
  });

  final ProductModel? product;
  final int quantity;
  final num total;
  final num paid;
  final num debt;
  final String Function(num value) formatMoney;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: product == null
            ? const Text(
                'Mahsulot tanlang',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w800,
                ),
              )
            : Column(
                children: [
                  _SummaryRow(
                    label: 'Narx',
                    value: formatMoney(product!.price),
                  ),
                  _SummaryRow(
                    label: 'Miqdor',
                    value: quantity.toString(),
                  ),
                  const Divider(height: 22),
                  _SummaryRow(
                    label: 'Jami',
                    value: formatMoney(total),
                    isStrong: true,
                  ),
                  _SummaryRow(
                    label: 'To‘langan',
                    value: formatMoney(paid),
                  ),
                  _SummaryRow(
                    label: 'Qarz',
                    value: formatMoney(debt < 0 ? 0 : debt),
                    isDanger: debt > 0,
                    isStrong: true,
                  ),
                ],
              ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isDanger = false,
    this.isStrong = false,
  });

  final String label;
  final String value;
  final bool isDanger;
  final bool isStrong;

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? const Color(0xFFDC2626) : const Color(0xFF0F172A);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: isStrong ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
