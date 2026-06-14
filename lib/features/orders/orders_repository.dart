import '../../core/api/api_client.dart';
import 'order_models.dart';

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

  Future<OrderModel> getOrder(String orderId) async {
    final result = await _apiClient.get('/orders/$orderId');

    if (result is! Map<String, dynamic>) {
      throw const OrdersException('Zakaz detail noto‘g‘ri formatda keldi');
    }

    return OrderModel.fromJson(result);
  }

  Future<OrderModel> createOrder({
    required String customerId,
    required String productId,
    required int quantity,
    required num paidAmount,
  }) async {
    final result = await _apiClient.post(
      '/orders',
      body: {
        'customerId': customerId,
        'items': [
          {
            'productId': productId,
            'quantity': quantity,
          },
        ],
        'paidAmount': paidAmount,
      },
    );

    if (result is! Map<String, dynamic>) {
      throw const OrdersException('Zakaz yaratish javobi noto‘g‘ri formatda keldi');
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
