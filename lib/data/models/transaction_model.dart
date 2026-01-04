class TransactionModel {
  final int? id;
  final int productId;
  final int buyerId;
  final int sellerId;
  final int quantity;
  final double totalPrice;
  final String status; // pending, accepted, rejected
  final String? buyerNotes;
  final String? sellerNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // 🆕 Extra fields dari JOIN query (tidak disimpan di database)
  final String? productName;
  final double? productPrice;
  final String? productImages;
  final String? productCondition;
  final String? buyerName;
  final String? buyerPhone;
  final String? sellerName;

  TransactionModel({
    this.id,
    required this.productId,
    required this.buyerId,
    required this.sellerId,
    required this.quantity,
    required this.totalPrice,
    this.status = 'pending',
    this.buyerNotes,
    this.sellerNotes,
    required this.createdAt,
    required this.updatedAt,
    // Extra fields
    this.productName,
    this.productPrice,
    this.productImages,
    this.productCondition,
    this.buyerName,
    this.buyerPhone,
    this.sellerName,
  });

  // 🔹 toDatabase - untuk INSERT/UPDATE
  Map<String, dynamic> toDatabase() {
    return {
      if (id != null) 'id': id,
      'product_id': productId,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'quantity': quantity,
      'total_price': totalPrice,
      'status': status,
      'buyer_notes': buyerNotes,
      'seller_notes': sellerNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // 🔹 fromDatabase - dari SQLite (basic query)
  factory TransactionModel.fromDatabase(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      buyerId: map['buyer_id'] as int,
      sellerId: map['seller_id'] as int,
      quantity: map['quantity'] as int,
      totalPrice: (map['total_price'] as num).toDouble(),
      status: map['status'] as String,
      buyerNotes: map['buyer_notes'] as String?,
      sellerNotes: map['seller_notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // 🔹 fromJoinQuery - dari JOIN query (dengan product & user details)
  factory TransactionModel.fromJoinQuery(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      buyerId: map['buyer_id'] as int,
      sellerId: map['seller_id'] as int,
      quantity: map['quantity'] as int,
      totalPrice: (map['total_price'] as num).toDouble(),
      status: map['status'] as String,
      buyerNotes: map['buyer_notes'] as String?,
      sellerNotes: map['seller_notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      // Extra fields dari JOIN
      productName: map['product_name'] as String?,
      productPrice: map['product_price'] != null 
          ? (map['product_price'] as num).toDouble() 
          : null,
      productImages: map['product_images'] as String?,
      productCondition: map['product_condition'] as String?,
      buyerName: map['buyer_name'] as String?,
      buyerPhone: map['buyer_phone'] as String?,
      sellerName: map['seller_name'] as String?,
    );
  }

  // 🔹 copyWith - untuk update status
  TransactionModel copyWith({
    int? id,
    int? productId,
    int? buyerId,
    int? sellerId,
    int? quantity,
    double? totalPrice,
    String? status,
    String? buyerNotes,
    String? sellerNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? productName,
    double? productPrice,
    String? productImages,
    String? productCondition,
    String? buyerName,
    String? buyerPhone,
    String? sellerName,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      buyerNotes: buyerNotes ?? this.buyerNotes,
      sellerNotes: sellerNotes ?? this.sellerNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      productName: productName ?? this.productName,
      productPrice: productPrice ?? this.productPrice,
      productImages: productImages ?? this.productImages,
      productCondition: productCondition ?? this.productCondition,
      buyerName: buyerName ?? this.buyerName,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      sellerName: sellerName ?? this.sellerName,
    );
  }

  // 🔹 Helper: Get first image URL
  String? get firstImage {
    if (productImages == null || productImages!.isEmpty) return null;
    final imageList = productImages!.split(',');
    return imageList.isNotEmpty ? imageList.first : null;
  }

  // 🔹 Helper: Status color
  String get statusColor {
    switch (status) {
      case 'pending':
        return 'warning'; // yellow
      case 'accepted':
        return 'success'; // green
      case 'rejected':
        return 'error'; // red
      default:
        return 'info'; // blue
    }
  }

  // 🔹 Helper: Status label Indonesia
  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Menunggu Konfirmasi';
      case 'accepted':
        return 'Diterima';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }
}