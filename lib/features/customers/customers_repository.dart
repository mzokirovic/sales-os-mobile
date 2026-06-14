import '../../core/api/api_client.dart';
import 'customer_model.dart';

class CustomersRepository {
  CustomersRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<CustomerModel>> listCustomers() async {
    final result = await _apiClient.get('/customers');

    if (result is! List<dynamic>) {
      throw const CustomersException('Mijozlar noto‘g‘ri formatda keldi');
    }

    return result
        .map((item) => CustomerModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

class CustomersException implements Exception {
  const CustomersException(this.message);

  final String message;

  @override
  String toString() => message;
}
