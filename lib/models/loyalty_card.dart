class LoyaltyCard {
  const LoyaltyCard({
    required this.id,
    required this.clientId,
    required this.number,
    required this.issuedAt,
    required this.discountPercent,
    required this.active,
    this.deletedAt,
  });

  final int id;
  final int clientId;
  final String number;
  final DateTime issuedAt;
  final int discountPercent;
  final bool active;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'clientId': clientId,
    'number': number,
    'issuedAt': issuedAt.toIso8601String(),
    'discountPercent': discountPercent,
    'active': active,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory LoyaltyCard.fromJson(Map<String, dynamic> json) => LoyaltyCard(
    id: json['id'] as int? ?? 0,
    clientId: json['clientId'] as int? ?? 0,
    number: json['number'] as String? ?? '',
    issuedAt: json['issuedAt'] == null
        ? DateTime.now()
        : DateTime.tryParse(json['issuedAt'] as String) ?? DateTime.now(),
    discountPercent: json['discountPercent'] as int? ?? 0,
    active: json['active'] as bool? ?? true,
    deletedAt: json['deletedAt'] == null
        ? null
        : DateTime.tryParse(json['deletedAt'] as String),
  );

  LoyaltyCard copyWith({
    int? clientId,
    String? number,
    DateTime? issuedAt,
    int? discountPercent,
    bool? active,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return LoyaltyCard(
      id: id,
      clientId: clientId ?? this.clientId,
      number: number ?? this.number,
      issuedAt: issuedAt ?? this.issuedAt,
      discountPercent: discountPercent ?? this.discountPercent,
      active: active ?? this.active,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
