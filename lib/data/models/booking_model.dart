import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingModel {
  int id;
  final int residenceId;
  final int userId;
  final int providerId;
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

  int get durationDays => checkOutDate.difference(checkInDate).inDays;

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

  Color get statusColor {
    switch (status) {
      case 'pending':
        return const Color(0xFFFFA500); // Orange
      case 'approved':
        return const Color(0xFF4CAF50); // Green
      case 'rejected':
        return const Color(0xFFFF5252); // Red
      case 'completed':
        return const Color(0xFF2196F3); // Blue
      case 'cancelled':
        return const Color(0xFF9E9E9E); // Grey
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String get formattedCheckIn =>
      DateFormat('dd MMM yyyy', 'id_ID').format(checkInDate);
  String get formattedCheckOut =>
      DateFormat('dd MMM yyyy', 'id_ID').format(checkOutDate);
  String get formattedCreatedAt => DateFormat('dd MMM yyyy HH:mm', 'id_ID')
      .format(createdAt ?? DateTime.now());

  BookingModel({
    this.id = 0,
    required this.residenceId,
    required this.userId,
    required this.providerId,
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
      residenceId: json['residence_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      providerId: json['provider_id'] ?? 0,
      bookingCode: json['booking_code'] ?? '',
      checkInDate: json['check_in_date'] != null
          ? DateTime.parse(json['check_in_date'])
          : DateTime.now(),
      checkOutDate: json['check_out_date'] != null
          ? DateTime.parse(json['check_out_date'])
          : DateTime.now(),
      documents: json['documents'] is String
          ? (json['documents'] as String).split(',')
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
      'residence_id': residenceId,
      'user_id': userId,
      'provider_id': providerId,
      'booking_code': bookingCode,
      'check_in_date': DateFormat('yyyy-MM-dd').format(checkInDate),
      'check_out_date': DateFormat('yyyy-MM-dd').format(checkOutDate),
      'documents': documents.join(','),
      'status': status,
      'rejection_reason': rejectionReason,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toDatabase() {
    return {
      'residence_id': residenceId,
      'user_id': userId,
      'provider_id': providerId,
      'booking_code': bookingCode,
      'check_in_date': DateFormat('yyyy-MM-dd').format(checkInDate),
      'check_out_date': DateFormat('yyyy-MM-dd').format(checkOutDate),
      'documents': documents.join(','),
      'status': status,
      'rejection_reason': rejectionReason,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory BookingModel.fromDatabase(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'] ?? 0,
      residenceId: map['residence_id'] ?? 0,
      userId: map['user_id'] ?? 0,
      providerId: map['provider_id'] ?? 0,
      bookingCode: map['booking_code'] ?? '',
      checkInDate: DateTime.parse(map['check_in_date']),
      checkOutDate: DateTime.parse(map['check_out_date']),
      documents: (map['documents'] as String).split(','),
      status: map['status'] ?? 'pending',
      rejectionReason: map['rejection_reason'],
      notes: map['notes'],
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }
}
