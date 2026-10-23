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
