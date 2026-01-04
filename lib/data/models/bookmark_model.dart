class BookmarkModel {
  final int id;
  final int userId;
  final String
      bookmarkableType; // Polymorphic: Residence, Activity, atau MarketplaceProduct
  final int bookmarkableId;
  final DateTime? createdAt;

  // Computed properties
  bool get isResidence => bookmarkableType.contains('Residence');
  bool get isActivity => bookmarkableType.contains('Activity');
  bool get isMarketplace => bookmarkableType.contains('MarketplaceProduct');

  BookmarkModel({
    required this.id,
    required this.userId,
    required this.bookmarkableType,
    required this.bookmarkableId,
    this.createdAt,
  });

  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    return BookmarkModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      bookmarkableType: json['bookmarkable_type'] ?? '',
      bookmarkableId: json['bookmarkable_id'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'bookmarkable_type': bookmarkableType,
      'bookmarkable_id': bookmarkableId,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'user_id': userId,
      'bookmarkable_type': bookmarkableType,
      'bookmarkable_id': bookmarkableId,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory BookmarkModel.fromDatabase(Map<String, dynamic> map) {
    return BookmarkModel(
      id: map['id'],
      userId: map['user_id'],
      bookmarkableType: map['bookmarkable_type'],
      bookmarkableId: map['bookmarkable_id'],
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    );
  }
}
