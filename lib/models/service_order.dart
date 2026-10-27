class ServiceOrder {
  const ServiceOrder({
    required this.id,
    required this.number,
    required this.carId,
    required this.clientId,
    required this.description,
    required this.status,
    required this.price,
    required this.createdAt,
    this.deletedAt,
  });

  final int id;
  final String number;
  final int carId;
  final int clientId;
  final String description;
  final String status;
  final int price;
  final DateTime createdAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'carId': carId,
    'clientId': clientId,
    'description': description,
    'status': status,
    'price': price,
    'createdAt': createdAt.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory ServiceOrder.fromJson(Map<String, dynamic> json) => ServiceOrder(
    id: json['id'] as int? ?? 0,
    number: json['number'] as String? ?? '',
    carId: json['carId'] as int? ?? 0,
    clientId: json['clientId'] as int? ?? 0,
    description: json['description'] as String? ?? '',
    status: json['status'] as String? ?? '',
    price: json['price'] as int? ?? 0,
    createdAt: json['createdAt'] == null
        ? DateTime.now()
        : DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now(),
    deletedAt: json['deletedAt'] == null
        ? null
        : DateTime.tryParse(json['deletedAt'] as String),
  );

  ServiceOrder copyWith({
    String? number,
    int? carId,
    int? clientId,
    String? description,
    String? status,
    int? price,
    DateTime? createdAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return ServiceOrder(
      id: id,
      number: number ?? this.number,
      carId: carId ?? this.carId,
      clientId: clientId ?? this.clientId,
      description: description ?? this.description,
      status: status ?? this.status,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}

const List<String> orderStatuses = ['Новый', 'В работе', 'Готов', 'Выдан'];
