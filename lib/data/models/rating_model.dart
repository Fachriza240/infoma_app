import 'dart:convert';

class RatingModel {
  final int id;
  final int userId;
  final String
      rateableType; // Polymorphic: Residence, Activity, atau MarketplaceProduct
  final int rateableId;
  final int? transactionId;
  final int rating; // 1-5
  final String? review;
  final List<String>? images;
  final bool? isRecommended;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Computed properties
  bool get hasReview => review != null && review!.isNotEmpty;
  bool get hasImages => images != null && images!.isNotEmpty;

  RatingModel({
    required this.id,
    required this.userId,
    required this.rateableType,
    required this.rateableId,
    this.transactionId,
    required this.rating,
    this.review,
    this.images,
    this.isRecommended,
    this.createdAt,
    this.updatedAt,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      rateableType: json['rateable_type'] ?? '',
      rateableId: json['rateable_id'] ?? 0,
      transactionId: json['transaction_id'],
      rating: json['rating'] ?? 5,
      review: json['review'],
      images: json['images'] != null
          ? (json['images'] is String
              ? List<String>.from(jsonDecode(json['images']))
              : List<String>.from(json['images']))
          : null,
      isRecommended:
          json['is_recommended'] == 1 || json['is_recommended'] == true,
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
      'rateable_type': rateableType,
      'rateable_id': rateableId,
      'transaction_id': transactionId,
      'rating': rating,
      'review': review,
      'images': images != null ? jsonEncode(images) : null,
      'is_recommended': isRecommended == true ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
