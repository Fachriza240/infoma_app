import 'dart:convert';

class BookingModel {
  final int id;
  final int userId;
  final String
      bookableType; // 'App\Models\Residence' atau 'App\Models\MarketplaceProduct'
  final int bookableId;
  final String bookingCode;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final List<String> documents;
  final String
      status; // 'pending', 'approved', 'rejected', 'completed', 'cancelled'
  final String? rejectionReason;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Computed properties
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  bool get isResidence => bookableType.contains('Residence');
  bool get isMarketplace => bookableType.contains('MarketplaceProduct');

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Menunggu Persetujuan';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  BookingModel({
    required this.id,
    required this.userId,
    required this.bookableType,
    required this.bookableId,
    required this.bookingCode,
    required this.checkInDate,
    required this.checkOutDate,
    required this.documents,
    required this.status,
    this.rejectionReason,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      bookableType: json['bookable_type'] ?? '',
      bookableId: json['bookable_id'] ?? 0,
      bookingCode: json['booking_code'] ?? '',
      checkInDate: json['check_in_date'] != null
          ? DateTime.parse(json['check_in_date'])
          : DateTime.now(),
      checkOutDate: json['check_out_date'] != null
          ? DateTime.parse(json['check_out_date'])
          : DateTime.now(),
      documents: json['documents'] is String
          ? List<String>.from(jsonDecode(json['documents']))
          : List<String>.from(json['documents'] ?? []),
      status: json['status'] ?? 'pending',
      rejectionReason: json['rejection_reason'],
      notes: json['notes'],
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
      'user_id': userId,
      'bookable_type': bookableType,
      'bookable_id': bookableId,
      'booking_code': bookingCode,
      'check_in_date': checkInDate.toIso8601String().split('T')[0],
      'check_out_date': checkOutDate.toIso8601String().split('T')[0],
      'documents': jsonEncode(documents),
      'status': status,
      'rejection_reason': rejectionReason,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'user_id': userId,
      'bookable_type': bookableType,
      'bookable_id': bookableId,
      'booking_code': bookingCode,
      'check_in_date': checkInDate.toIso8601String().split('T')[0],
      'check_out_date': checkOutDate.toIso8601String().split('T')[0],
      'documents': jsonEncode(documents),
      'status': status,
      'rejection_reason': rejectionReason,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory BookingModel.fromDatabase(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'],
      userId: map['user_id'],
      bookableType: map['bookable_type'],
      bookableId: map['bookable_id'],
      bookingCode: map['booking_code'],
      checkInDate: DateTime.parse(map['check_in_date']),
      checkOutDate: DateTime.parse(map['check_out_date']),
      documents: List<String>.from(jsonDecode(map['documents'])),
      status: map['status'],
      rejectionReason: map['rejection_reason'],
      notes: map['notes'],
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }
}
