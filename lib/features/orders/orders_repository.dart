import '../../core/api/api_client.dart';
import 'order_models.dart';

class CreatePaymentInput {
  const CreatePaymentInput({
    required this.amount,
    required this.paymentMethod,
  });

  final num amount;
  final String paymentMethod;

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'paymentMethod': paymentMethod,
    };
  }
}

class CreateOrderItemInput {
  const CreateOrderItemInput({
    required this.productId,
    required this.quantity,
  });

  final String productId;
  final int quantity;

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
    };
  }
}

class OrdersRepository {
  OrdersRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<OrderModel>> listOrders() async {
    final result = await _apiClient.get('/orders');

    if (result is! List<dynamic>) {
      throw const OrdersException('Zakazlar noto‘g‘ri formatda keldi');
    }

    return result
        .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<OrderModel>> listOrdersByCustomer(String customerId) async {
    final result = await _apiClient.get('/orders?customerId=$customerId');

    if (result is! List<dynamic>) {
      throw const OrdersException('Mijoz zakazlari noto‘g‘ri formatda keldi');
    }

    return result
        .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<OrderModel> getOrder(String orderId) async {
    final result = await _apiClient.get('/orders/$orderId');

    if (result is! Map<String, dynamic>) {
      throw const OrdersException('Zakaz detail noto‘g‘ri formatda keldi');
    }

    return OrderModel.fromJson(result);
  }

  Future<OrderModel> createOrder({
    required String customerId,
    required List<CreateOrderItemInput> items,
    required num paidAmount,
  }) async {
    final result = await _apiClient.post(
      '/orders',
      body: {
        'customerId': customerId,
        'items': items.map((item) => item.toJson()).toList(),
        'paidAmount': paidAmount,
      },
    );

    if (result is! Map<String, dynamic>) {
      throw const OrdersException('Zakaz yaratish javobi noto‘g‘ri formatda keldi');
    }

    return OrderModel.fromJson(result);
  }

  Future<OrderModel> addPayment({
    required String orderId,
    required CreatePaymentInput input,
  }) async {
    final result = await _apiClient.post(
      '/orders/$orderId/payments',
      body: input.toJson(),
    );

    if (result is! Map<String, dynamic>) {
      throw const OrdersException('To‘lov qo‘shish javobi noto‘g‘ri formatda keldi');
    }

    return OrderModel.fromJson(result);
  }

  Future<OrderModel> updateStatus({
    required String orderId,
    required String status,
  }) async {
    final result = await _apiClient.patch(
      '/orders/$orderId/status',
      body: {
        'status': status,
      },
    );

    if (result is! Map<String, dynamic>) {
      throw const OrdersException('Status javobi noto‘g‘ri formatda keldi');
    }

    return OrderModel.fromJson(result);
  }
}

class OrdersException implements Exception {
  const OrdersException(this.message);

  final String message;

  @override
  String toString() => message;
}
