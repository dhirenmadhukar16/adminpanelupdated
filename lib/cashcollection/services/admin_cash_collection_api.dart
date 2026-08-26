import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/admin_cash_collection.dart';

class AdminCashCollectionApi {
  final Dio dio;

  AdminCashCollectionApi({
    Dio? dio,
  }) : dio = dio ?? ApiClient.dio;

  Future<List<AdminCashCollection>> getCollections({
    DateTime? date,
    String? storeId,
  }) async {
    final selectedDate =
        date ?? DateTime.now();

    final queryParameters =
        <String, dynamic>{
      'date': _formatDate(
        selectedDate,
      ),
    };

    if (storeId != null &&
        storeId.isNotEmpty) {
      queryParameters['storeId'] =
          storeId;
    }

    final response = await dio.get(
      '/api/admin/cash-collections',
      queryParameters:
          queryParameters,
    );

    if (response.data is! List) {
      throw Exception(
        'Invalid cash collection response.',
      );
    }

    return (response.data as List)
        .map(
          (json) =>
              AdminCashCollection.fromJson(
            Map<String, dynamic>.from(
              json as Map,
            ),
          ),
        )
        .toList();
  }

  Future<AdminCashCollection>
      getCollectionById(
    String collectionId,
  ) async {
    if (collectionId.isEmpty) {
      throw Exception(
        'Collection ID is required.',
      );
    }

    final response = await dio.get(
      '/api/admin/cash-collections/'
      '$collectionId',
    );

    if (response.data is! Map) {
      throw Exception(
        'Invalid collection details response.',
      );
    }

    return AdminCashCollection.fromJson(
      Map<String, dynamic>.from(
        response.data as Map,
      ),
    );
  }

  Future<List<Map<String, dynamic>>>
      getCustomerWiseCollections({
    DateTime? date,
  }) async {
    final selectedDate =
        date ?? DateTime.now();

    final response = await dio.get(
      '/api/admin/cash-collections/'
      'customer-wise',
      queryParameters: {
        'date': _formatDate(
          selectedDate,
        ),
      },
    );

    if (response.data is! List) {
      throw Exception(
        'Invalid customer-wise response.',
      );
    }

    return (response.data as List)
        .map(
          (json) =>
              Map<String, dynamic>.from(
            json as Map,
          ),
        )
        .toList();
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}