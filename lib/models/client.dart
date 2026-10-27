class Client {
  final int id;
  final String lastName;
  final String firstName;
  final String middleName;
  final String city;
  final String phone;
  final String email;
  final DateTime registeredAt;
  final DateTime? deletedAt;

  const Client({
    required this.id,
    required this.lastName,
    required this.firstName,
    required this.middleName,
    required this.city,
    required this.phone,
    required this.email,
    required this.registeredAt,
    this.deletedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'lastName': lastName,
    'firstName': firstName,
    'middleName': middleName,
    'city': city,
    'phone': phone,
    'email': email,
    'registeredAt': registeredAt.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Client.fromJson(Map<String, dynamic> json) => Client(
    id: json['id'] as int? ?? 0,
    lastName: json['lastName'] as String? ?? '',
    firstName: json['firstName'] as String? ?? '',
    middleName: json['middleName'] as String? ?? '',
    city: json['city'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    email: json['email'] as String? ?? '',
    registeredAt: json['registeredAt'] == null
        ? DateTime.now()
        : DateTime.tryParse(json['registeredAt'] as String) ?? DateTime.now(),
    deletedAt: json['deletedAt'] == null
        ? null
        : DateTime.tryParse(json['deletedAt'] as String),
  );

  bool get isDeleted => deletedAt != null;

  String get fullName => '$lastName $firstName $middleName';

  Client copyWith({
    String? lastName,
    String? firstName,
    String? middleName,
    String? city,
    String? phone,
    String? email,
    DateTime? registeredAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Client(
      id: id,
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      registeredAt: registeredAt ?? this.registeredAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
