class ApiResponse {
  final bool success;
  final String message;
  final User user;
  final Business business;

  ApiResponse({
    required this.success,
    required this.message,
    required this.user,
    required this.business,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      user: User.fromJson(json['user'] ?? {}),
      business: Business.fromJson(json['business'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'user': user.toJson(),
      'business': business.toJson(),
    };
  }
}

class User {
  final int id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email};
  }
}

class Business {
  final String businessName;
  final String phone;
  final String address;
  final String receiptFooter;
  final String logoUrl;

  Business({
    required this.businessName,
    required this.phone,
    required this.address,
    required this.receiptFooter,
    required this.logoUrl,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      businessName: json['business_name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      receiptFooter: json['receipt_footer'] ?? '',
      logoUrl: json['logo_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'business_name': businessName,
      'phone': phone,
      'address': address,
      'receipt_footer': receiptFooter,
      'logo_url': logoUrl,
    };
  }
}
