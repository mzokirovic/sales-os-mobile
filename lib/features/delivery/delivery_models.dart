class DeliveryTrip {
  const DeliveryTrip({
    required this.id,
    required this.status,
    required this.startedAt,
    required this.completedAt,
    required this.createdAt,
    required this.stops,
  });

  final String id;
  final String status;
  final String? startedAt;
  final String? completedAt;
  final String createdAt;
  final List<DeliveryStop> stops;

  factory DeliveryTrip.fromJson(Map<String, dynamic> json) {
    return DeliveryTrip(
      id: json['id'].toString(),
      status: json['status'].toString(),
      startedAt: json['startedAt']?.toString(),
      completedAt: json['completedAt']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
      stops: (json['stops'] as List<dynamic>? ?? [])
          .map((item) => DeliveryStop.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  int get pendingStopsCount {
    return stops.where((stop) => stop.status == 'PENDING').length;
  }

  int get deliveredStopsCount {
    return stops.where((stop) => stop.status == 'DELIVERED').length;
  }
}

class DeliveryStop {
  const DeliveryStop({
    required this.id,
    required this.sortOrder,
    required this.status,
    required this.deliveredAt,
    required this.order,
  });

  final String id;
  final int sortOrder;
  final String status;
  final String? deliveredAt;
  final DeliveryOrder order;

  factory DeliveryStop.fromJson(Map<String, dynamic> json) {
    return DeliveryStop(
      id: json['id'].toString(),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      status: json['status'].toString(),
      deliveredAt: json['deliveredAt']?.toString(),
      order: DeliveryOrder.fromJson(json['order'] as Map<String, dynamic>),
    );
  }
}

class DeliveryOrder {
  const DeliveryOrder({
    required this.id,
    required this.status,
    required this.customer,
    required this.items,
  });

  final String id;
  final String status;
  final DeliveryCustomer customer;
  final List<DeliveryOrderItem> items;

  factory DeliveryOrder.fromJson(Map<String, dynamic> json) {
    return DeliveryOrder(
      id: json['id'].toString(),
      status: json['status'].toString(),
      customer: DeliveryCustomer.fromJson(
        json['customer'] as Map<String, dynamic>,
      ),
      items: (json['items'] as List<dynamic>? ?? [])
          .map(
            (item) => DeliveryOrderItem.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class DeliveryCustomer {
  const DeliveryCustomer({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
  });

  final String id;
  final String name;
  final String? phone;
  final String? address;

  factory DeliveryCustomer.fromJson(Map<String, dynamic> json) {
    return DeliveryCustomer(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? 'Mijoz',
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
    );
  }
}

class DeliveryOrderItem {
  const DeliveryOrderItem({
    required this.id,
    required this.productName,
    required this.quantity,
  });

  final String id;
  final String productName;
  final num quantity;

  factory DeliveryOrderItem.fromJson(Map<String, dynamic> json) {
    return DeliveryOrderItem(
      id: json['id'].toString(),
      productName: json['productName']?.toString() ?? 'Mahsulot',
      quantity: json['quantity'] as num? ?? 0,
    );
  }
}
