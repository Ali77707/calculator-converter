class Car {
  final int id;
  final String title;
  final String vin;
  final int year;
  final int mileage;
  final int makeId;
  final int bodyTypeId;
  final String fuel;
  final int price;
  final List<int> ownerIds;
  final DateTime? deletedAt;

  const Car({
    required this.id,
    required this.title,
    required this.vin,
    required this.year,
    required this.mileage,
    required this.makeId,
    required this.bodyTypeId,
    required this.fuel,
    required this.price,
    required this.ownerIds,
    this.deletedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'vin': vin,
    'year': year,
    'mileage': mileage,
    'makeId': makeId,
    'bodyTypeId': bodyTypeId,
    'fuel': fuel,
    'price': price,
    'ownerIds': ownerIds,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Car.fromJson(Map<String, dynamic> json) => Car(
    id: json['id'] as int? ?? 0,
    title: json['title'] as String? ?? '',
    vin: json['vin'] as String? ?? '',
    year: json['year'] as int? ?? 0,
    mileage: json['mileage'] as int? ?? 0,
    makeId: json['makeId'] as int? ?? 0,
    bodyTypeId: json['bodyTypeId'] as int? ?? 0,
    fuel: json['fuel'] as String? ?? '',
    price: json['price'] as int? ?? 0,
    ownerIds: (json['ownerIds'] as List?)?.cast<int>() ?? const [],
    deletedAt: json['deletedAt'] == null
        ? null
        : DateTime.tryParse(json['deletedAt'] as String),
  );

  bool get isDeleted => deletedAt != null;

  Car copyWith({
    String? title,
    String? vin,
    int? year,
    int? mileage,
    int? makeId,
    int? bodyTypeId,
    String? fuel,
    int? price,
    List<int>? ownerIds,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Car(
      id: id,
      title: title ?? this.title,
      vin: vin ?? this.vin,
      year: year ?? this.year,
      mileage: mileage ?? this.mileage,
      makeId: makeId ?? this.makeId,
      bodyTypeId: bodyTypeId ?? this.bodyTypeId,
      fuel: fuel ?? this.fuel,
      price: price ?? this.price,
      ownerIds: ownerIds ?? this.ownerIds,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
