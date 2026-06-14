import '../../core/api/api_client.dart';
import 'dashboard_model.dart';

class DashboardRepository {
  DashboardRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<DashboardSummary> getSummary() async {
    final result = await _apiClient.get('/dashboard/summary');

    if (result is! Map<String, dynamic>) {
      throw const DashboardException('Dashboard javobi noto‘g‘ri formatda keldi');
    }

    return DashboardSummary.fromJson(result);
  }
}

class DashboardException implements Exception {
  const DashboardException(this.message);

  final String message;

  @override
  String toString() => message;
}
