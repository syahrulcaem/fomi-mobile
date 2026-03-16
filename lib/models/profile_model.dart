class PrivacySettings {
  PrivacySettings({
    required this.showPhone,
    required this.showEmail,
    required this.allowFinderContact,
  });

  final bool showPhone;
  final bool showEmail;
  final bool allowFinderContact;

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      showPhone: json['show_phone'] == true,
      showEmail: json['show_email'] == true,
      allowFinderContact: json['allow_finder_contact'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'show_phone': showPhone,
      'show_email': showEmail,
      'allow_finder_contact': allowFinderContact,
    };
  }
}

class ProfileModel {
  ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.privacy,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final PrivacySettings? privacy;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '-',
      email: json['email']?.toString() ?? '-',
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      privacy: json['privacy'] is Map<String, dynamic>
          ? PrivacySettings.fromJson(json['privacy'] as Map<String, dynamic>)
          : null,
    );
  }
}
