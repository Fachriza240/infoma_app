class TransactionModel {
  final int id;
  final String transactionCode;
  final int buyerId;
  final int sellerId;
  final int productId;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final String buyerName;
  final String buyerPhone;
  final String buyerAddress;
  final String pickupMethod; // 'pickup', 'delivery', 'meetup'
  final String? pickupAddress;
  final String? pickupNotes;
  final String
      status; // 'pending', 'confirmed', 'in_progress', 'completed', 'cancelled', 'refunded'
  final String? paymentMethod;
  final String paymentStatus; // 'pending', 'paid', 'failed', 'refunded'
  final String? paymentProof;
  final String? sellerNotes;
  final String? cancellationReason;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Computed properties
  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  bool get isPaid => paymentStatus == 'paid';
  bool get isPaymentPending => paymentStatus == 'pending';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Menunggu Konfirmasi';
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'in_progress':
        return 'Dalam Proses';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      case 'refunded':
        return 'Dikembalikan';
      default:
        return status;
    }
  }

  String get pickupMethodLabel {
    switch (pickupMethod) {
      case 'pickup':
        return 'Ambil di Tempat';
      case 'delivery':
        return 'Diantar';
      case 'meetup':
        return 'COD / Ketemu';
      default:
        return pickupMethod;
    }
  }

  TransactionModel({
    required this.id,
    required this.transactionCode,
    required this.buyerId,
    required this.sellerId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.buyerName,
    required this.buyerPhone,
    required this.buyerAddress,
    required this.pickupMethod,
    this.pickupAddress,
    this.pickupNotes,
    required this.status,
    this.paymentMethod,
    required this.paymentStatus,
    this.paymentProof,
    this.sellerNotes,
    this.cancellationReason,
    this.completedAt,
    this.cancelledAt,
    this.createdAt,
    this.updatedAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? 0,
      transactionCode: json['transaction_code'] ?? '',
      buyerId: json['buyer_id'] ?? 0,
      sellerId: json['seller_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      quantity: json['quantity'] ?? 1,
      unitPrice: json['unit_price'] != null
          ? double.parse(json['unit_price'].toString())
          : 0.0,
      totalAmount: json['total_amount'] != null
          ? double.parse(json['total_amount'].toString())
          : 0.0,
      buyerName: json['buyer_name'] ?? '',
      buyerPhone: json['buyer_phone'] ?? '',
      buyerAddress: json['buyer_address'] ?? '',
      pickupMethod: json['pickup_method'] ?? 'pickup',
      pickupAddress: json['pickup_address'],
      pickupNotes: json['pickup_notes'],
      status: json['status'] ?? 'pending',
      paymentMethod: json['payment_method'],
      paymentStatus: json['payment_status'] ?? 'pending',
      paymentProof: json['payment_proof'],
      sellerNotes: json['seller_notes'],
      cancellationReason: json['cancellation_reason'],
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_code': transactionCode,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_amount': totalAmount,
      'buyer_name': buyerName,
      'buyer_phone': buyerPhone,
      'buyer_address': buyerAddress,
      'pickup_method': pickupMethod,
      'pickup_address': pickupAddress,
      'pickup_notes': pickupNotes,
      'status': status,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'payment_proof': paymentProof,
      'seller_notes': sellerNotes,
      'cancellation_reason': cancellationReason,
      'completed_at': completedAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'transaction_code': transactionCode,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_amount': totalAmount,
      'buyer_name': buyerName,
      'buyer_phone': buyerPhone,
      'buyer_address': buyerAddress,
      'pickup_method': pickupMethod,
      'pickup_address': pickupAddress,
      'pickup_notes': pickupNotes,
      'status': status,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory TransactionModel.fromDatabase(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      transactionCode: map['transaction_code'],
      buyerId: map['buyer_id'],
      sellerId: map['seller_id'],
      productId: map['product_id'],
      quantity: map['quantity'],
      unitPrice: map['unit_price'],
      totalAmount: map['total_amount'],
      buyerName: map['buyer_name'],
      buyerPhone: map['buyer_phone'],
      buyerAddress: map['buyer_address'],
      pickupMethod: map['pickup_method'],
      pickupAddress: map['pickup_address'],
      pickupNotes: map['pickup_notes'],
      status: map['status'],
      paymentMethod: map['payment_method'],
      paymentStatus: map['payment_status'],
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }
}
