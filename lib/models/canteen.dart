class Canteen {
  final String id;
  final String name;
  final String code;
  final bool active;

  Canteen({
    required this.id,
    required this.name,
    required this.code,
    required this.active,
  });

  // ======================
  // FROM JSON (BACKEND → FLUTTER)
  // ======================
  factory Canteen.fromJson(Map<String, dynamic> json) {
    return Canteen(
      id: json['_id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      active: json['active'] ?? true,
    );
  }

  // ======================
  // TO JSON (OPTIONAL)
  // ======================
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'code': code,
      'active': active,
    };
  }
}
