import 'package:hive/hive.dart';

part 'business_info_model.g.dart';

@HiveType(typeId: 0)
class BusinessInfoModel extends HiveObject {
  @HiveField(0)
  bool success;

  @HiveField(1)
  String message;

  @HiveField(2)
  User user;

  @HiveField(3)
  Business business;

  BusinessInfoModel({
    required this.success,
    required this.message,
    required this.user,
    required this.business,
  });

  factory BusinessInfoModel.fromJson(Map<String, dynamic> json) {
    return BusinessInfoModel(
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

@HiveType(typeId: 1)
class User extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String email;

  User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};
}

@HiveType(typeId: 2)
class Business extends HiveObject {
  @HiveField(0)
  String businessName;

  @HiveField(1)
  String phone;

  @HiveField(2)
  String address;

  @HiveField(3)
  String receiptFooter;

  @HiveField(4)
  String logoUrl;

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

  Map<String, dynamic> toJson() => {
    'business_name': businessName,
    'phone': phone,
    'address': address,
    'receipt_footer': receiptFooter,
    'logo_url': logoUrl,
  };
}
