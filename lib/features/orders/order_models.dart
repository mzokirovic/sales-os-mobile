class OrderCustomer {
  const OrderCustomer({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.lat,
    this.lng,
  });

  final String id;
  final String name;
  final String? phone;
  final String? address;
  final double? lat;
  final double? lng;

  factory OrderCustomer.fromJson(Map<String, dynamic> json) {
    return OrderCustomer(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
  }
}

class OrderItem {
  const OrderItem({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.total,
  });

  final String id;
  final String productName;
  final num quantity;
  final num price;
  final num total;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      productName: json['productName'] as String,
      quantity: json['quantity'] as num,
      price: json['price'] as num,
      total: json['total'] as num,
    );
  }
}

class OrderPayment {
  const OrderPayment({
    required this.id,
    required this.amount,
    this.paymentMethod,
  });

  final String id;
  final num amount;
  final String? paymentMethod;

  factory OrderPayment.fromJson(Map<String, dynamic> json) {
    return OrderPayment(
      id: json['id'] as String,
      amount: json['amount'] as num,
      paymentMethod: json['paymentMethod'] as String?,
    );
  }
}

class OrderModel {
  const OrderModel({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.debtAmount,
    required this.createdAt,
    required this.customer,
    required this.items,
    required this.payments,
  });

  final String id;
  final String status;
  final num totalAmount;
  final num debtAmount;
  final DateTime createdAt;
  final OrderCustomer customer;
  final List<OrderItem> items;
  final List<OrderPayment> payments;

  num get paidAmount {
    return payments.fold<num>(0, (sum, payment) => sum + payment.amount);
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    final paymentsJson = json['payments'] as List<dynamic>? ?? [];

    return OrderModel(
      id: json['id'] as String,
      status: json['status'] as String,
      totalAmount: json['totalAmount'] as num,
      debtAmount: json['debtAmount'] as num,
      createdAt: DateTime.parse(json['createdAt'] as String),
      customer: OrderCustomer.fromJson(json['customer'] as Map<String, dynamic>),
      items: itemsJson
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      payments: paymentsJson
          .map((payment) => OrderPayment.fromJson(payment as Map<String, dynamic>))
          .toList(),
    );
  }
}
