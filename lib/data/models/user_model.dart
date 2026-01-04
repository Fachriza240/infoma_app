class UserModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String? profilePicture;
  final String role; // 'user' or 'provider'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.profilePicture,
    required this.role,
    this.createdAt,
    this.updatedAt,
  });

  // From JSON (API Response)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      profilePicture: json['profile_picture'],
      role: json['role'] ?? 'user',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  // To JSON (untuk simpan ke API/Database)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'profile_picture': profilePicture,
      'role': role,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // To Database (SQLite format)
  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'profile_picture': profilePicture,
      'role': role,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // From Database
  factory UserModel.fromDatabase(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      address: map['address'],
      profilePicture: map['profile_picture'],
      role: map['role'],
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  // CopyWith untuk update data
  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? profilePicture,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      profilePicture: profilePicture ?? this.profilePicture,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Getter untuk cek role
  bool get isProvider => role == 'provider';
  bool get isUser => role == 'user';
}
