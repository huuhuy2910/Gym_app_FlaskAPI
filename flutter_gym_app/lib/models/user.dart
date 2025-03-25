class User {
  final int id;
  final String username;
  final String email;
  final String phone;
  final String address;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    required this.address,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? -1, // Provide a default value for null IDs
      username: json['username'],
      email: json['email'],
      phone: json['phone'] ?? 'No phone provided',
      address: json['address'] ?? 'No address provided',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone': phone,
      'address': address,
    };
  }
}
