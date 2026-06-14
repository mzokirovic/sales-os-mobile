import '../../core/api/api_client.dart';
import 'product_model.dart';

class ProductsRepository {
  ProductsRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<ProductModel>> listActiveProducts() async {
    final result = await _apiClient.get('/products/active');

    if (result is! List<dynamic>) {
      throw const ProductsException('Mahsulotlar noto‘g‘ri formatda keldi');
    }

    return result
        .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

class ProductsException implements Exception {
  const ProductsException(this.message);

  final String message;

  @override
  String toString() => message;
}
