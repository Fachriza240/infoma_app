import 'dart:convert';

class ResidenceModel {
  final int id;
  final int providerId;
  final int categoryId;
  final String name;
  final String description;
  final String address;
  final double? latitude;
  final double? longitude;
  final String rentalPeriod; // 'monthly' or 'yearly'
  final double price;
  final int capacity;
  final int availableSlots;
  final List<String> facilities;
  final List<String> images;
  final String? discountType; // 'percentage' or 'flat'
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

  ResidenceModel({
    required this.id,
    required this.providerId,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.address,
    this.latitude,
    this.longitude,
    required this.rentalPeriod,
    required this.price,
    required this.capacity,
    required this.availableSlots,
    required this.facilities,
    required this.images,
    this.discountType,
    this.discountValue,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory ResidenceModel.fromJson(Map<String, dynamic> json) {
    return ResidenceModel(
      id: json['id'] ?? 0,
      providerId: json['provider_id'] ?? 0,
      categoryId: json['category_id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      rentalPeriod: json['rental_period'] ?? 'monthly',
      price:
          json['price'] != null ? double.parse(json['price'].toString()) : 0.0,
      capacity: json['capacity'] ?? 0,
      availableSlots: json['available_slots'] ?? 0,
      facilities: json['facilities'] is String
          ? List<String>.from(jsonDecode(json['facilities']))
          : List<String>.from(json['facilities'] ?? []),
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
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'rental_period': rentalPeriod,
      'price': price,
      'capacity': capacity,
      'available_slots': availableSlots,
      'facilities': jsonEncode(facilities),
      'images': jsonEncode(images),
      'discount_type': discountType,
      'discount_value': discountValue,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'provider_id': providerId,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'rental_period': rentalPeriod,
      'price': price,
      'capacity': capacity,
      'available_slots': availableSlots,
      'facilities': jsonEncode(facilities),
      'images': jsonEncode(images),
      'discount_type': discountType,
      'discount_value': discountValue,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory ResidenceModel.fromDatabase(Map<String, dynamic> map) {
    return ResidenceModel(
      id: map['id'],
      providerId: map['provider_id'],
      categoryId: map['category_id'],
      name: map['name'],
      description: map['description'],
      address: map['address'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      rentalPeriod: map['rental_period'],
      price: map['price'],
      capacity: map['capacity'],
      availableSlots: map['available_slots'],
      facilities: List<String>.from(jsonDecode(map['facilities'])),
      images: List<String>.from(jsonDecode(map['images'])),
      discountType: map['discount_type'],
      discountValue: map['discount_value'],
      isActive: map['is_active'] == 1,
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }
}
