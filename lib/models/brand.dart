class Brand {
  const Brand({
    required this.id,
    required this.name,
    required this.country,
    this.deletedAt,
  });

  final int id;
  final String name;
  final String country;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'country': country,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Brand.fromJson(Map<String, dynamic> json) => Brand(
    id: json['id'] as int? ?? 0,
    name: json['name'] as String? ?? '',
    country: json['country'] as String? ?? '',
    deletedAt: json['deletedAt'] == null
        ? null
        : DateTime.tryParse(json['deletedAt'] as String),
  );

  Brand copyWith({
    String? name,
    String? country,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Brand(
      id: id,
      name: name ?? this.name,
      country: country ?? this.country,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
