class User {
  User({required this.id, required this.name, required this.email, this.role = 'customer'});

  final int id;
  final String name;
  final String email;
  final String role;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] as String? ?? 'customer',
      );
}
