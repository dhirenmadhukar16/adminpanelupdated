import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/admin_cash_collection.dart';
import '../repositories/admin_cash_collection_repository.dart';
import '../services/admin_cash_collection_api.dart';

final adminCashCollectionRepositoryProvider =
    Provider<AdminCashCollectionRepository>(
  (ref) {
    return AdminCashCollectionRepository(
      AdminCashCollectionApi(),
    );
  },
);

final adminCashCollectionProvider =
    ChangeNotifierProvider<AdminCashCollectionNotifier>(
  (ref) {
    return AdminCashCollectionNotifier(
      ref.read(
        adminCashCollectionRepositoryProvider,
      ),
    );
  },
);

class AdminCashCollectionNotifier
    extends ChangeNotifier {
  final AdminCashCollectionRepository repository;

  AdminCashCollectionNotifier(
    this.repository,
  );

  List<AdminCashCollection> _collections = [];

  AdminCashCollection? _selectedCollection;

  bool _isLoading = false;

  bool _isDetailsLoading = false;

  String? _error;

  DateTime _selectedDate = DateTime.now();

  String? _selectedStoreId;

  List<AdminCashCollection> get collections =>
      List.unmodifiable(_collections);

  AdminCashCollection? get selectedCollection =>
      _selectedCollection;

  bool get isLoading => _isLoading;

  bool get isDetailsLoading => _isDetailsLoading;

  String? get error => _error;

  DateTime get selectedDate => _selectedDate;

  String? get selectedStoreId => _selectedStoreId;

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setSelectedStore(String? storeId) {
    _selectedStoreId = storeId;
    notifyListeners();
  }

  Future<void> loadCollections({
    DateTime? date,
    String? storeId,
  }) async {
    _selectedDate = date ?? _selectedDate;
    _selectedStoreId = storeId;

    _isLoading = true;
    _error = null;

    notifyListeners();

    try {
      _collections = await repository.getCollections(
        date: _selectedDate,
        storeId: _selectedStoreId,
      );
    } catch (e) {
      _collections = [];
      _error = _cleanError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> applyFilters() async {
    await loadCollections(
      date: _selectedDate,
      storeId: _selectedStoreId,
    );
  }

  Future<void> loadCollectionById(
    String id,
  ) async {
    if (id.isEmpty) {
      _error = 'Collection ID is required.';
      notifyListeners();
      return;
    }

    _isDetailsLoading = true;
    _error = null;

    notifyListeners();

    try {
      _selectedCollection =
          await repository.getCollectionById(id);
    } catch (e) {
      _selectedCollection = null;
      _error = _cleanError(e);
    } finally {
      _isDetailsLoading = false;
      notifyListeners();
    }
  }

  void clearFilters() {
    _selectedDate = DateTime.now();
    _selectedStoreId = null;
    _collections = [];
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSelectedCollection() {
    _selectedCollection = null;
    notifyListeners();
  }

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }

    return message;
  }
}