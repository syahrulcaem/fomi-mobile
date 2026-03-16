class UserModel {
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.role,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? role;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '-',
      email: json['email']?.toString() ?? '-',
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      role: json['role']?.toString(),
    );
  }
}
