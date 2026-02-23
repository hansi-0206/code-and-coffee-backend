class User {
  final String id;
  final String name;
  final String email;
  final String role;

  // 🔥 ADD THIS
  final String? canteenId;

  final String? token;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.canteenId,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',

      // 🔥 READ FROM BACKEND
      canteenId: json['canteenId'] ??
          json['canteen']?['_id'] ??
          json['canteen'],

      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'canteenId': canteenId,
      'token': token,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? canteenId,
    String? token,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      canteenId: canteenId ?? this.canteenId,
      token: token ?? this.token,
    );
  }
}
