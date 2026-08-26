import '../models/admin_cash_collection.dart';
import '../services/admin_cash_collection_api.dart';

class AdminCashCollectionRepository {
  final AdminCashCollectionApi api;

  AdminCashCollectionRepository(
    this.api,
  );

  Future<List<AdminCashCollection>>
      getCollections({
    DateTime? date,
    String? storeId,
  }) {
    return api.getCollections(
      date: date,
      storeId: storeId,
    );
  }

  Future<AdminCashCollection>
      getCollectionById(
    String id,
  ) {
    return api.getCollectionById(
      id,
    );
  }

  Future<List<Map<String, dynamic>>>
      getCustomerWiseCollections({
    DateTime? date,
  }) {
    return api.getCustomerWiseCollections(
      date: date,
    );
  }
}