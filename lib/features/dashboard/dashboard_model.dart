class DashboardSummary {
  const DashboardSummary({
    required this.totalSales,
    required this.openDebt,
    required this.ordersCount,
    required this.customersCount,
    required this.productsCount,
    required this.activeProductsCount,
    required this.newOrdersCount,
    required this.statusBreakdown,
    required this.recentOrders,
  });

  final num totalSales;
  final num openDebt;
  final int ordersCount;
  final int customersCount;
  final int productsCount;
  final int activeProductsCount;
  final int newOrdersCount;
  final List<DashboardStatusCount> statusBreakdown;
  final List<DashboardRecentOrder> recentOrders;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final statusBreakdownJson =
        json['statusBreakdown'] as List<dynamic>? ?? [];
    final recentOrdersJson = json['recentOrders'] as List<dynamic>? ?? [];

    return DashboardSummary(
      totalSales: json['totalSales'] as num? ?? 0,
      openDebt: json['openDebt'] as num? ?? 0,
      ordersCount: (json['ordersCount'] as num? ?? 0).toInt(),
      customersCount: (json['customersCount'] as num? ?? 0).toInt(),
      productsCount: (json['productsCount'] as num? ?? 0).toInt(),
      activeProductsCount: (json['activeProductsCount'] as num? ?? 0).toInt(),
      newOrdersCount: (json['newOrdersCount'] as num? ?? 0).toInt(),
      statusBreakdown: statusBreakdownJson
          .map((item) => DashboardStatusCount.fromJson(item as Map<String, dynamic>))
          .toList(),
      recentOrders: recentOrdersJson
          .map((item) => DashboardRecentOrder.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DashboardStatusCount {
  const DashboardStatusCount({
    required this.status,
    required this.count,
  });

  final String status;
  final int count;

  factory DashboardStatusCount.fromJson(Map<String, dynamic> json) {
    return DashboardStatusCount(
      status: json['status'] as String,
      count: (json['count'] as num? ?? 0).toInt(),
    );
  }
}

class DashboardRecentOrder {
  const DashboardRecentOrder({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.debtAmount,
    required this.createdAt,
    required this.customer,
  });

  final String id;
  final String status;
  final num totalAmount;
  final num debtAmount;
  final DateTime createdAt;
  final DashboardCustomer customer;

  factory DashboardRecentOrder.fromJson(Map<String, dynamic> json) {
    return DashboardRecentOrder(
      id: json['id'] as String,
      status: json['status'] as String,
      totalAmount: json['totalAmount'] as num? ?? 0,
      debtAmount: json['debtAmount'] as num? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      customer: DashboardCustomer.fromJson(json['customer'] as Map<String, dynamic>),
    );
  }
}

class DashboardCustomer {
  const DashboardCustomer({
    required this.id,
    required this.name,
    this.phone,
    this.address,
  });

  final String id;
  final String name;
  final String? phone;
  final String? address;

  factory DashboardCustomer.fromJson(Map<String, dynamic> json) {
    return DashboardCustomer(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
    );
  }
}
