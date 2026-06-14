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
}

class OrdersException implements Exception {
  const OrdersException(this.message);

  final String message;

  @override
  String toString() => message;
}
