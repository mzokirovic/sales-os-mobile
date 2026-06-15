import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/current_user.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/customers/customer_model.dart';
import '../../features/customers/customer_permission_policy.dart';
import '../../features/customers/customers_repository.dart';
import '../../features/products/product_model.dart';
import '../../features/products/products_repository.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_view.dart';
import 'order_permission_policy.dart';
import 'orders_repository.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({
    this.initialCustomerId,
    super.key,
  });

  final String? initialCustomerId;

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authRepository = AuthRepository();
  final _customersRepository = CustomersRepository();
  final _productsRepository = ProductsRepository();
  final _ordersRepository = OrdersRepository();

  final _paidAmountController = TextEditingController(text: '0');

  late Future<_CreateOrderData> _dataFuture;

  String? _selectedCustomerId;
  final List<_SelectedOrderItem> _items = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedCustomerId = widget.initialCustomerId;
    _dataFuture = _loadData();
  }

  @override
  void dispose() {
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

  num _paidAmount() {
    return num.tryParse(_paidAmountController.text.trim()) ?? 0;
  }

  num _totalAmount() {
    return _items.fold<num>(0, (sum, item) => sum + item.total);
  }

  num _debtAmount() {
    final debt = _totalAmount() - _paidAmount();
    return debt < 0 ? 0 : debt;
  }

  String _formatMoney(num value) {
    return '${value.toInt().toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ' ',
        )} so‘m';
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFDC2626) : null,
      ),
    );
  }

  Future<void> _openAddProductSheet(List<ProductModel> products) async {
    if (products.isEmpty) {
      _showMessage('Aktiv mahsulotlar yo‘q', isError: true);
      return;
    }

    final item = await showModalBottomSheet<_SelectedOrderItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return _AddProductSheet(
          products: products,
          formatMoney: _formatMoney,
        );
      },
    );

    if (item == null || !mounted) return;

    setState(() {
      final index = _items.indexWhere(
        (existing) => existing.product.id == item.product.id,
      );

      if (index == -1) {
        _items.add(item);
      } else {
        final existing = _items[index];
        _items[index] = existing.copyWith(
          quantity: existing.quantity + item.quantity,
        );
      }
    });
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _isSubmitting) return;

    final customerId = _selectedCustomerId;

    if (customerId == null) {
      _showMessage('Mijoz tanlang', isError: true);
      return;
    }

    if (_items.isEmpty) {
      _showMessage('Kamida bitta mahsulot qo‘shing', isError: true);
      return;
    }

    if (_paidAmount() > _totalAmount()) {
      _showMessage('To‘langan summa jami summadan katta bo‘lmasin', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final order = await _ordersRepository.createOrder(
        customerId: customerId,
        items: _items
            .map(
              (item) => CreateOrderItemInput(
                productId: item.product.id,
                quantity: item.quantity,
              ),
            )
            .toList(),
        paidAmount: _paidAmount(),
      );

      if (!mounted) return;

      _showMessage('Zakaz yaratildi');
      context.go('/orders/${order.id}');
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString(), isError: true);
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

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              children: [
                _CustomerSelectCard(
                  customer: customer,
                  customers: data.customers,
                  selectedCustomerId: _selectedCustomerId,
                  canCreateCustomer: CustomerPermissionPolicy.canCreateCustomer(data.user.role),
                  onChanged: (value) {
                    setState(() {
                      _selectedCustomerId = value;
                    });
                  },
                  onCreateCustomer: () => context.go('/customers/create?next=order'),
                ),
                const SizedBox(height: 12),
                _ItemsCard(
                  items: _items,
                  formatMoney: _formatMoney,
                  onAdd: () => _openAddProductSheet(data.products),
                  onRemove: (item) {
                    setState(() {
                      _items.remove(item);
                    });
                  },
                ),
                const SizedBox(height: 12),
                _PaymentCard(
                  controller: _paidAmountController,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 12),
                _SummaryCard(
                  total: _totalAmount(),
                  paid: _paidAmount(),
                  debt: _debtAmount(),
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
                  onPressed: data == null || _isSubmitting ? null : _submit,
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

class _SelectedOrderItem {
  const _SelectedOrderItem({
    required this.product,
    required this.quantity,
  });

  final ProductModel product;
  final int quantity;

  num get total => product.price * quantity;

  _SelectedOrderItem copyWith({
    int? quantity,
  }) {
    return _SelectedOrderItem(
      product: product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class _CustomerSelectCard extends StatelessWidget {
  const _CustomerSelectCard({
    required this.customer,
    required this.customers,
    required this.selectedCustomerId,
    required this.canCreateCustomer,
    required this.onChanged,
    required this.onCreateCustomer,
  });

  final CustomerModel? customer;
  final List<CustomerModel> customers;
  final String? selectedCustomerId;
  final bool canCreateCustomer;
  final ValueChanged<String?> onChanged;
  final VoidCallback onCreateCustomer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _SectionHeader(
              icon: Icons.storefront_rounded,
              title: 'Mijoz',
              value: customer?.name ?? 'Tanlanmagan',
              subtitle: customer?.address ?? 'Mijoz tanlang',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: selectedCustomerId,
              decoration: const InputDecoration(
                labelText: 'Mijoz tanlang',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              items: customers.map((item) {
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
              onChanged: onChanged,
            ),
            if (canCreateCustomer) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onCreateCustomer,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Yangi mijoz'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({
    required this.items,
    required this.formatMoney,
    required this.onAdd,
    required this.onRemove,
  });

  final List<_SelectedOrderItem> items;
  final String Function(num value) formatMoney;
  final VoidCallback onAdd;
  final ValueChanged<_SelectedOrderItem> onRemove;

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
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Qo‘shish'),
                ),
              ],
            ),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Mahsulot qo‘shilmagan',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              )
            else
              ...items.map((item) {
                return _ItemRow(
                  item: item,
                  formatMoney: formatMoney,
                  onRemove: () => onRemove(item),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.formatMoney,
    required this.onRemove,
  });

  final _SelectedOrderItem item;
  final String Function(num value) formatMoney;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.product.name,
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
            '${item.quantity} × ${formatMoney(item.product.price)}',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          controller: controller,
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
          onChanged: (_) => onChanged(),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
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


class _AddProductSheet extends StatefulWidget {
  const _AddProductSheet({
    required this.products,
    required this.formatMoney,
  });

  final List<ProductModel> products;
  final String Function(num value) formatMoney;

  @override
  State<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<_AddProductSheet> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');

  String? _selectedProductId;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  ProductModel? get _selectedProduct {
    final id = _selectedProductId;
    if (id == null) return null;

    for (final product in widget.products) {
      if (product.id == id) return product;
    }

    return null;
  }

  int get _quantity {
    return int.tryParse(_quantityController.text.trim()) ?? 0;
  }

  num get _total {
    final product = _selectedProduct;
    if (product == null) return 0;

    return product.price * _quantity;
  }

  void _submit() {
    final valid = _formKey.currentState?.validate() ?? false;
    final product = _selectedProduct;

    if (!valid || product == null) return;

    Navigator.of(context).pop(
      _SelectedOrderItem(
        product: product,
        quantity: _quantity,
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
                  'Mahsulot qo‘shish',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _selectedProductId,
                  decoration: const InputDecoration(
                    labelText: 'Mahsulot',
                    prefixIcon: Icon(Icons.inventory_2_rounded),
                  ),
                  items: widget.products.map((product) {
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
                _BottomSheetTotal(
                  label: 'Jami',
                  value: widget.formatMoney(_total),
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

class _BottomSheetTotal extends StatelessWidget {
  const _BottomSheetTotal({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
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
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
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
      ],
    );
  }
}
