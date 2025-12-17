double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  return double.tryParse(v.toString()) ?? 0.0;
}

double? _toDoubleOrNull(dynamic v) {
  if (v == null) return null;
  return double.tryParse(v.toString());
}

// -------------------- ROOT --------------------
class OrderResponse {
  OrderData? order;
  String? type;

  OrderResponse({this.order, this.type});

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      order: json['order'] != null ? OrderData.fromJson(json['order']) : null,
      type: json['type'],
    );
  }
}

// -------------------- ORDER --------------------
class OrderData {
  int? userId;
  int? shiftId;
  String? customerName;
  double? subTotal;
  double? totalAmount;
  double? tax;
  double? serviceCharges;
  double? deliveryCharges;
  double? salesDiscount;
  double? approvedDiscounts;
  String? status;
  String? note;
  String? kitchenNote;
  String? orderDate;
  String? orderTime;
  String? updatedAt;
  String? createdAt;
  int? id;
  List<OrderItem>? items;
  KotData? kot;
  List<dynamic>? promo;
  String? phoneNumber;
  String? deliveryLocation;
  List<dynamic>? approvedDiscountDetails;
  double? promoDiscount;
  List<dynamic>? appliedPromos;
  String? orderType;
  String? tableNumber;
  String? paymentMethod;
  bool? autoPrintKot;
  double? cashReceived;
  double? change;
  String? paymentType;
  double? cashAmount;
  double? cardAmount;

  OrderData({
    this.userId,
    this.shiftId,
    this.customerName,
    this.subTotal,
    this.totalAmount,
    this.tax,
    this.serviceCharges,
    this.deliveryCharges,
    this.salesDiscount,
    this.approvedDiscounts,
    this.status,
    this.note,
    this.kitchenNote,
    this.orderDate,
    this.orderTime,
    this.updatedAt,
    this.createdAt,
    this.id,
    this.items,
    this.kot,
    this.promo,
    this.phoneNumber,
    this.deliveryLocation,
    this.approvedDiscountDetails,
    this.promoDiscount,
    this.appliedPromos,
    this.orderType,
    this.tableNumber,
    this.paymentMethod,
    this.autoPrintKot,
    this.cashReceived,
    this.change,
    this.paymentType,
    this.cashAmount,
    this.cardAmount,
  });

  factory OrderData.fromJson(Map<String, dynamic> json) {
    return OrderData(
      userId: json['user_id'],
      shiftId: json['shift_id'],
      customerName: json['customer_name'],

      subTotal: _toDouble(json['sub_total']),
      totalAmount: _toDouble(json['total_amount']),
      tax: _toDouble(json['tax']),
      serviceCharges: _toDouble(json['service_charges']),
      deliveryCharges: _toDouble(json['delivery_charges']),
      salesDiscount: _toDouble(json['sales_discount']),
      approvedDiscounts: _toDouble(json['approved_discounts']),

      status: json['status'],
      note: json['note'],
      kitchenNote: json['kitchen_note'],
      orderDate: json['order_date'],
      orderTime: json['order_time'],
      updatedAt: json['updated_at'],
      createdAt: json['created_at'],
      id: json['id'],

      items: (json['items'] as List?)
          ?.map((e) => OrderItem.fromJson(e))
          .toList(),

      kot: json['kot'] != null ? KotData.fromJson(json['kot']) : null,
      promo: json['promo'],
      phoneNumber: json['phone_number'],
      deliveryLocation: json['delivery_location'],
      approvedDiscountDetails: json['approved_discount_details'],

      promoDiscount: _toDouble(json['promo_discount']),
      appliedPromos: json['applied_promos'],
      orderType: json['order_type'],
      tableNumber: json['table_number']?.toString(),
      paymentMethod: json['payment_method'],
      autoPrintKot: json['auto_print_kot'],

      cashReceived: _toDouble(json['cash_received']),
      change: _toDouble(json['change']),
      paymentType: json['payment_type'],

      cashAmount: _toDoubleOrNull(json['cash_amount']),
      cardAmount: _toDoubleOrNull(json['card_amount']),
    );
  }
}

// -------------------- ORDER ITEM --------------------
class OrderItem {
  int? productId;
  String? title;
  int? quantity;
  double? price;
  String? note;
  String? kitchenNote;
  double? unitPrice;
  String? itemKitchenNote;
  double? taxPercentage;
  double? taxAmount;
  int? variantId;
  String? variantName;
  List<dynamic>? addons;
  double? saleDiscountPerItem;
  List<dynamic>? removedIngredients;

  OrderItem({
    this.productId,
    this.title,
    this.quantity,
    this.price,
    this.note,
    this.kitchenNote,
    this.unitPrice,
    this.itemKitchenNote,
    this.taxPercentage,
    this.taxAmount,
    this.variantId,
    this.variantName,
    this.addons,
    this.saleDiscountPerItem,
    this.removedIngredients,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id'],
      title: json['title'],
      quantity: json['quantity'],

      price: _toDouble(json['price']),
      unitPrice: _toDouble(json['unit_price']),
      taxPercentage: _toDouble(json['tax_percentage']),
      taxAmount: _toDouble(json['tax_amount']),
      saleDiscountPerItem: _toDouble(json['sale_discount_per_item']),

      note: json['note'],
      kitchenNote: json['kitchen_note'],
      itemKitchenNote: json['item_kitchen_note'],

      variantId: json['variant_id'],
      variantName: json['variant_name'],

      addons: json['addons'],
      removedIngredients: json['removed_ingredients'],
    );
  }
}

// -------------------- KOT --------------------
class KotData {
  int? id;
  int? posOrderTypeId;
  String? orderTime; // FIX
  String? orderDate; // FIX
  String? note;
  String? kitchenNote;
  String? createdAt;
  String? updatedAt;
  List<KotItem>? items;

  KotData({
    this.id,
    this.posOrderTypeId,
    this.orderTime,
    this.orderDate,
    this.note,
    this.kitchenNote,
    this.createdAt,
    this.updatedAt,
    this.items,
  });

  factory KotData.fromJson(Map<String, dynamic> json) {
    return KotData(
      id: int.tryParse(json['id'].toString()),
      posOrderTypeId: int.tryParse(json['pos_order_type_id'].toString()),
      orderTime: json['order_time']?.toString(),
      orderDate: json['order_date']?.toString(),
      note: json['note'],
      kitchenNote: json['kitchen_note'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      items: (json['items'] as List?)?.map((e) => KotItem.fromJson(e)).toList(),
    );
  }
}

// -------------------- KOT ITEM --------------------
class KotItem {
  final int id;
  final int kitchenOrderId;
  final String itemName;
  final String? variantName; // <-- MAKE NULLABLE
  final int quantity;
  final List<dynamic> ingredients;
  final String? itemKitchenNote;
  final String status;
  final String createdAt;
  final String updatedAt;

  KotItem({
    required this.id,
    required this.kitchenOrderId,
    required this.itemName,
    this.variantName, // <-- allow null
    required this.quantity,
    required this.ingredients,
    this.itemKitchenNote,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory KotItem.fromJson(Map<String, dynamic> json) {
    return KotItem(
      id: int.tryParse(json['id'].toString()) ?? 0,
      kitchenOrderId: int.tryParse(json['kitchen_order_id'].toString()) ?? 0,
      itemName: json['item_name']?.toString() ?? '',
      variantName: json['variant_name']?.toString(),
      quantity: int.tryParse(json['quantity'].toString()) ?? 0,
      ingredients: json['ingredients'] ?? [],
      itemKitchenNote: json['item_kitchen_note'],
      status: json['status']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}
