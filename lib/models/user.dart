class User {
  final int? id;
  final String name;
  final String email;
  final String password;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
  });

  factory User.fromMap(Map<String, Object?> map) {
    return User(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
    };
  }
}