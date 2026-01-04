import 'dart:convert';

class MarketplaceProductModel {
  final int id;
  final int sellerId;
  final int categoryId;
  final String name;
  final String description;
  final String condition; // 'new', 'like_new', 'good', 'fair', 'needs_repair'
  final double price;
  final int stockQuantity;
  final String location;
  final double? latitude;
  final double? longitude;
  final List<String> images;
  final List<String>? tags;
  final String status; // 'draft', 'active', 'sold', 'inactive'
  final int viewsCount;
  final DateTime? soldAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Computed properties
  bool get isAvailable => status == 'active' && stockQuantity > 0;
  bool get isSold => status == 'sold' || stockQuantity == 0;
  bool get isNew => condition == 'new';

  String get conditionLabel {
    switch (condition) {
      case 'new':
        return 'Baru';
      case 'like_new':
        return 'Seperti Baru';
      case 'good':
        return 'Baik';
      case 'fair':
        return 'Lumayan';
      case 'needs_repair':
        return 'Perlu Perbaikan';
      default:
        return condition;
    }
  }

  MarketplaceProductModel({
    required this.id,
    required this.sellerId,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.condition,
    required this.price,
    required this.stockQuantity,
    required this.location,
    this.latitude,
    this.longitude,
    required this.images,
    this.tags,
    required this.status,
    this.viewsCount = 0,
    this.soldAt,
    this.createdAt,
    this.updatedAt,
  });

  factory MarketplaceProductModel.fromJson(Map<String, dynamic> json) {
    return MarketplaceProductModel(
      id: json['id'] ?? 0,
      sellerId: json['seller_id'] ?? 0,
      categoryId: json['category_id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      condition: json['condition'] ?? 'good',
      price:
          json['price'] != null ? double.parse(json['price'].toString()) : 0.0,
      stockQuantity: json['stock_quantity'] ?? 1,
      location: json['location'] ?? '',
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      images: json['images'] is String
          ? List<String>.from(jsonDecode(json['images']))
          : List<String>.from(json['images'] ?? []),
      tags: json['tags'] != null
          ? (json['tags'] is String
              ? List<String>.from(jsonDecode(json['tags']))
              : List<String>.from(json['tags']))
          : null,
      status: json['status'] ?? 'draft',
      viewsCount: json['views_count'] ?? 0,
      soldAt: json['sold_at'] != null ? DateTime.parse(json['sold_at']) : null,
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
      'seller_id': sellerId,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'condition': condition,
      'price': price,
      'stock_quantity': stockQuantity,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'images': jsonEncode(images),
      'tags': tags != null ? jsonEncode(tags) : null,
      'status': status,
      'views_count': viewsCount,
      'sold_at': soldAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Convert to Database Map (untuk SQLite)
  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'seller_id': sellerId,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'condition': condition,
      'price': price,
      'stock_quantity': stockQuantity,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'images': jsonEncode(images),
      'tags': tags != null ? jsonEncode(tags) : null,
      'status': status,
      'views_count': viewsCount,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create from Database Map (dari SQLite)
  factory MarketplaceProductModel.fromDatabase(Map<String, dynamic> map) {
    return MarketplaceProductModel(
      id: map['id'] as int,
      sellerId: map['seller_id'] as int,
      categoryId: map['category_id'] as int,
      name: map['name'] as String,
      description: map['description'] as String,
      condition: map['condition'] as String,
      price: map['price'] as double,
      stockQuantity: map['stock_quantity'] as int,
      location: map['location'] as String,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      images: (jsonDecode(map['images']) as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      tags: map['tags'] != null
          ? (jsonDecode(map['tags']) as List<dynamic>)
              .map((e) => e as String)
              .toList()
          : null,
      status: map['status'] as String,
      viewsCount: map['views_count'] as int,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}
