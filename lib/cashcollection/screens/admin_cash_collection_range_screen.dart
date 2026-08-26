class AdminCashCollection {
  final String id;
  final String storeId;
  final String? storeName;
  final DateTime collectionDate;

  final double openingCash;
  final double cashSales;
  final double cashRefunds;
  final double expectedCash;

  final double? declaredCash;
  final double? cashDifference;

  final double onlineCollection;
  final double totalCollection;

  final int cashOrderCount;
  final int onlineOrderCount;

  final String? status;
  final String? reconciliationStatus;

  final String? reconciledBy;
  final DateTime? reconciledAt;
  final String? remarks;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminCashCollection({
    required this.id,
    required this.storeId,
    this.storeName,
    required this.collectionDate,
    required this.openingCash,
    required this.cashSales,
    required this.cashRefunds,
    required this.expectedCash,
    this.declaredCash,
    this.cashDifference,
    required this.onlineCollection,
    required this.totalCollection,
    required this.cashOrderCount,
    required this.onlineOrderCount,
    this.status,
    this.reconciliationStatus,
    this.reconciledBy,
    this.reconciledAt,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });

  factory AdminCashCollection.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminCashCollection(
      id: json['id']?.toString() ?? '',
      storeId: json['storeId']?.toString() ?? '',
      storeName: json['storeName']?.toString(),

      collectionDate: _parseDate(
        json['collectionDate'],
      ),

      openingCash: _toDouble(json['openingCash']),
      cashSales: _toDouble(json['cashSales']),
      cashRefunds: _toDouble(json['cashRefunds']),
      expectedCash: _toDouble(json['expectedCash']),

      declaredCash: json['declaredCash'] == null
          ? null
          : _toDouble(json['declaredCash']),

      cashDifference: json['cashDifference'] == null
          ? null
          : _toDouble(json['cashDifference']),

      onlineCollection:
          _toDouble(json['onlineCollection']),

      totalCollection:
          _toDouble(json['totalCollection']),

      cashOrderCount:
          _toInt(json['cashOrderCount']),

      onlineOrderCount:
          _toInt(json['onlineOrderCount']),

      status: json['status']?.toString(),

      reconciliationStatus:
          json['reconciliationStatus']?.toString(),

      reconciledBy:
          json['reconciledBy']?.toString(),

      reconciledAt: json['reconciledAt'] == null
          ? null
          : DateTime.tryParse(
              json['reconciledAt'].toString(),
            ),

      remarks: json['remarks']?.toString(),

      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(
              json['createdAt'].toString(),
            ),

      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse(
              json['updatedAt'].toString(),
            ),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }

    return DateTime.parse(value.toString());
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }
}