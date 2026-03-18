class CartItemModel {
  CartItemModel({
    required this.id,
    required this.productId,
    required this.cartKey,
    required this.name,
    required this.baseName,
    this.variantId,
    this.variantLabel,
    this.attributeName,
    this.attributeValue,
    required this.price,
    this.imageUrl,
    required this.type,
    required this.stock,
    required this.quantity,
  });

  final String id;
  final String productId;
  final String cartKey;
  final String name;
  final String baseName;
  final String? variantId;
  final String? variantLabel;
  final String? attributeName;
  final String? attributeValue;
  final int price;
  final String? imageUrl;
  final String type;
  final int stock;
  final int quantity;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      cartKey: json['cart_key']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      baseName: json['base_name']?.toString() ?? '',
      variantId: json['variant_id']?.toString(),
      variantLabel: json['variant_label']?.toString(),
      attributeName: json['attribute_name']?.toString(),
      attributeValue: json['attribute_value']?.toString(),
      price: (json['price'] as num?)?.toInt() ?? 0,
      imageUrl: json['image_url']?.toString(),
      type: json['type']?.toString() ?? 'physical',
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'cart_key': cartKey,
        'name': name,
        'base_name': baseName,
        'variant_id': variantId,
        'variant_label': variantLabel,
        'attribute_name': attributeName,
        'attribute_value': attributeValue,
        'price': price,
        'image_url': imageUrl,
        'type': type,
        'stock': stock,
        'quantity': quantity,
      };

  CartItemModel copyWith({int? quantity}) {
    return CartItemModel(
      id: id,
      productId: productId,
      cartKey: cartKey,
      name: name,
      baseName: baseName,
      variantId: variantId,
      variantLabel: variantLabel,
      attributeName: attributeName,
      attributeValue: attributeValue,
      price: price,
      imageUrl: imageUrl,
      type: type,
      stock: stock,
      quantity: quantity ?? this.quantity,
    );
  }

  int get subtotal => price * quantity;
}
