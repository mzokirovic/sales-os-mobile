class OrderCustomer {
  const OrderCustomer({
    required this.id,
    required this.name,
    this.phone,
    this.address,
  });

  final String id;
  final String name;
  final String? phone;
  final String? address;

  factory OrderCustomer.fromJson(Map<String, dynamic> json) {
    return OrderCustomer(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Noma’lum mijoz',
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
    );
  }
}

class OrderItem {
  const OrderItem({
    required this.id,
    this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.total,
  });

  final String id;
  final String? productId;
  final String productName;
  final int quantity;
  final num price;
  final num total;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString(),
      productName: json['productName']?.toString() ??
          json['product']?['name']?.toString() ??
          'Mahsulot',
      quantity: NumberParser.toInt(json['quantity']),
      price: NumberParser.toNum(json['price']),
      total: NumberParser.toNum(json['total']),
    );
  }
}

class OrderPayment {
  const OrderPayment({
    required this.id,
    required this.amount,
    this.paymentMethod,
    this.createdAt,
  });

  final String id;
  final num amount;
  final String? paymentMethod;
  final String? createdAt;

  factory OrderPayment.fromJson(Map<String, dynamic> json) {
    return OrderPayment(
      id: json['id']?.toString() ?? '',
      amount: NumberParser.toNum(json['amount']),
      paymentMethod: json['paymentMethod']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }
}

class OrderModel {
  const OrderModel({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.paidAmount,
    required this.debtAmount,
    required this.paymentStatus,
    required this.createdAt,
    required this.customer,
    required this.items,
    required this.payments,
  });

  final String id;
  final String status;
  final num totalAmount;
  final num paidAmount;
  final num debtAmount;
  final String paymentStatus;
  final String createdAt;
  final OrderCustomer customer;
  final List<OrderItem> items;
  final List<OrderPayment> payments;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final payments = (json['payments'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(OrderPayment.fromJson)
        .toList();

    final paidFromPayments = payments.fold<num>(
      0,
      (sum, payment) => sum + payment.amount,
    );

    final totalAmount = NumberParser.toNum(json['totalAmount']);
    final paidAmount = json.containsKey('paidAmount')
        ? NumberParser.toNum(json['paidAmount'])
        : paidFromPayments;
    final debtAmount = json.containsKey('debtAmount')
        ? NumberParser.toNum(json['debtAmount'])
        : (totalAmount - paidAmount);

    return OrderModel(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'NEW',
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      debtAmount: debtAmount < 0 ? 0 : debtAmount,
      paymentStatus:
          json['paymentStatus']?.toString() ?? _resolvePaymentStatus(paidAmount, debtAmount),
      createdAt: json['createdAt']?.toString() ?? '',
      customer: OrderCustomer.fromJson(
        (json['customer'] as Map<String, dynamic>?) ?? {},
      ),
      items: (json['items'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(OrderItem.fromJson)
          .toList(),
      payments: payments,
    );
  }

  static String _resolvePaymentStatus(num paidAmount, num debtAmount) {
    if (paidAmount <= 0 && debtAmount > 0) return 'UNPAID';
    if (debtAmount <= 0) return 'PAID';
    return 'PARTIAL';
  }
}

class NumberParser {
  const NumberParser._();

  static num toNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
