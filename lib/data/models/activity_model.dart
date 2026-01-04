import 'dart:convert';

class ActivityModel {
  final int id;
  final int providerId;
  final int categoryId;
  final String name;
  final String description;
  final String location;
  final double? latitude;
  final double? longitude;
  final DateTime eventDate;
  final DateTime registrationDeadline;
  final double price;
  final int capacity;
  final int availableSlots;
  final List<String> images;
  final String? discountType;
  final double? discountValue;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Computed properties
  double get finalPrice {
    if (discountType == null || discountValue == null) return price;

    if (discountType == 'percentage') {
      return price - (price * discountValue! / 100);
    } else {
      return price - discountValue!;
    }
  }

  bool get hasDiscount => discountType != null && discountValue != null;
  bool get isAvailable => availableSlots > 0 && isActive;
  bool get isRegistrationOpen => DateTime.now().isBefore(registrationDeadline);
  bool get isUpcoming => eventDate.isAfter(DateTime.now());

  ActivityModel({
    required this.id,
    required this.providerId,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.location,
    this.latitude,
    this.longitude,
    required this.eventDate,
    required this.registrationDeadline,
    required this.price,
    required this.capacity,
    required this.availableSlots,
    required this.images,
    this.discountType,
    this.discountValue,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] ?? 0,
      providerId: json['provider_id'] ?? 0,
      categoryId: json['category_id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      eventDate: json['event_date'] != null
          ? DateTime.parse(json['event_date'])
          : DateTime.now(),
      registrationDeadline: json['registration_deadline'] != null
          ? DateTime.parse(json['registration_deadline'])
          : DateTime.now(),
      price:
          json['price'] != null ? double.parse(json['price'].toString()) : 0.0,
      capacity: json['capacity'] ?? 0,
      availableSlots: json['available_slots'] ?? 0,
      images: json['images'] is String
          ? List<String>.from(jsonDecode(json['images']))
          : List<String>.from(json['images'] ?? []),
      discountType: json['discount_type'],
      discountValue: json['discount_value'] != null
          ? double.tryParse(json['discount_value'].toString())
          : null,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
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
      'provider_id': providerId,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'event_date': eventDate.toIso8601String(),
      'registration_deadline': registrationDeadline.toIso8601String(),
      'price': price,
      'capacity': capacity,
      'available_slots': availableSlots,
      'images': jsonEncode(images),
      'discount_type': discountType,
      'discount_value': discountValue,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Convert to Database Map (untuk SQLite)
  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'provider_id': providerId,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'event_date': eventDate.toIso8601String(),
      'registration_deadline': registrationDeadline.toIso8601String(),
      'price': price,
      'capacity': capacity,
      'available_slots': availableSlots,
      'images': jsonEncode(images), // List to JSON string
      'discount_type': discountType,
      'discount_value': discountValue,
      'is_active': isActive ? 1 : 0, // Boolean to INTEGER
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create from Database Map (dari SQLite)
  factory ActivityModel.fromDatabase(Map<String, dynamic> map) {
    return ActivityModel(
      id: map['id'] as int,
      providerId: map['provider_id'] as int,
      categoryId: map['category_id'] as int,
      name: map['name'] as String,
      description: map['description'] as String,
      location: map['location'] as String,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      eventDate: DateTime.parse(map['event_date'] as String),
      registrationDeadline:
          DateTime.parse(map['registration_deadline'] as String),
      price: map['price'] as double,
      capacity: map['capacity'] as int,
      availableSlots: map['available_slots'] as int,
      images: (jsonDecode(map['images']) as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      discountType: map['discount_type'] as String?,
      discountValue: map['discount_value'] as double?,
      isActive: (map['is_active'] as int) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}
